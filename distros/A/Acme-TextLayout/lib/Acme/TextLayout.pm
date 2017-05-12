package Acme::TextLayout;

use warnings;
use strict;
use Perl6::Attributes;
use FileHandle;
use Data::Dumper;


=head1 NAME

Acme::TextLayout - Layout things in a grid, as described textually

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

  $tl = Acme::TextLayout->new;
  $tl->instantiate(text => $pattern);

=head1 DESCRIPTION

For a GUI, controlling layout (especially on resize) can be
difficult, especially if your layout is complex. When looking
at a GUI, I came to the realization that I could express the
layout nicely like this:

  AAAAAAAAAAAAAAAA
  BBBBxxxxxxxxxxxx
  BBBBxxxxxxxxxxxx
  DDDDDDDDDDDDDDDD
  DDDDDDDDDDDDDDDD
  DDDDDDDDDDDDDDDD
  %%%%%%%%%%%%%GGG

Where each group of contiguous, like characters specifies a screen
region.

B<Very important>: space is not legal. Nor should you use "-", trust
me. A space (" ") will cause you to die, but a "-" is accepted,
but is used by other modules for other things. BEWARE!

To me, this gives an easy-to-grasp pictorial of the GUI
layout, as long as one notes WTF the letters and symbols represent.
The only caveat is that the collection of like characters/symbols
making the pattern must be adjacent, and must be rectangular. And
the overall pattern must be rectangular.

Note that this textual arrangement can be as big as you want.
It's all relative. Although it might not look like it on
the screen in your editor of choice, all spacing is assummed to
be the same in X and Y. Thus, the aspect ratio of the above
pattern is 16/7 (width/height).

To be useful for a GUI, one must be able to map this goofy space
into screen coordinates. That's what the B<map_range> function is
for (see below).

Now, I know what you must be thinking: is this guy nuts? Why not
use brand-X fancy GUI layout tool? Well, the fact is that those
are nice and easy for the initial layout, but they generally generate
code with precise XY coordinates in them, which makes resizing almost
impossible.

The idea here is that we use the above textual layout to specify
all the relative positions of things, then map this to a real
coordinate system, preserving the spatial relativity and size
associations.

I wrote this for use in a GUI application, but figured it might have
use elsewhere. Hence, this class. If you find a novel use for it,
please let me know what it is (email address in this document).


=head1 METHODS

=cut

=head2 B<new>

  $tl = Acme::TextLayout->new([%opts]);

Create an instance of this class. See B<instantiate> to do anything useful.

=cut

sub new {
    my $class = shift;
    my %opts = @_;
    my $self = \%opts;
    bless $self, $class;
    $.Class = $class;
    return $self;
}

=head2 B<instantiate>

  $tl->instantiate(text => ??);
  -or-
  $tl->instantiate(file => ??);

Specify the textual layout pattern we are interested in, either
from a text string or a file.

Returns undef if something wrong with your input.

=cut

sub instantiate {
    my ($self, %opts) = @_;
    my $file = $opts{file};
    my $text = $opts{text};

    # reset state on new instantiation
    $.textRef = [];
    $.Ranges  = {};
    $.widest = undef;
    $.chars  = {};
    $.Above = $.Below = $.Left = $.Right = undef;

    if (defined $file) {
        my $fh = FileHandle->new($file);
        return unless defined $fh;
        my @text = <$fh>;
        $fh->close;
        chomp foreach @text;
        s/^\s+// foreach @text;
        $text = [ @text ];
        ./_widest(\@text);
    }
    elsif (defined $text) {
        my @text = split(/\n{1}/, $text);
        s/^\s+// foreach @text;
        $text = [ @text ];
        ./_widest(\@text);
    }
    else {
        return undef;
    }

    ./_whats_in_there($text);
    ./_widest($text);
    $.textRef = $text;
    map {
        return undef unless length($_) == $.widest;
    } @{$.textRef};

    my %Ranges;
    my %chars = %.chars;
    map {
        my $C = $_;
        my @d = ./range($C);
        $Ranges{$C} = \@d;
    } keys(%chars);

    $.Ranges = \%Ranges;
    print STDERR "Pattern appears disjoint\n" if ./_disjoint();
    return undef if ./_disjoint();
    # signify OK if we got here
    return 1;
}

# not a complete test, but tests for the obvious
sub _disjoint {
    my ($self) = @_;
    my @text = @{$.textRef};
    my @chars = ./characters();
    my $ok = 1;
    map {
        my $line = $_;
        map {
            my $n = 0;
            my $t = $line;
            $n++ while $t =~ s/$_{1,}//;
            $ok = 0 if $n > 1;
        } @chars;
    } @text;
    my $width = ./width();
    for (my $i=0; $i < $width; $i++) {
        my @new;
        push(@new, substr($_, $i, 1)) foreach @text;
        my $line = join('', @new);
        map {
            my $n = 0;
            my $t = $line;
            $n++ while $t =~ s/$_{1,}//;
            $ok = 0 if $n > 1;
        } @chars;
    }

    return $ok ? 0 : 1;
}

sub _widest {
    my ($self, $textRef) = @_;
    my @text = @$textRef;
    my $widest = length($text[0]);
    map {
        my $len = length($_);
        $widest = $len if $len > $widest;
    } @text;
    $.widest = $widest;
}

sub _height {
    my ($self, $textRef) = @_;
    my @text = @$textRef;
    return scalar(@text);
}

# figure out all characters in our pattern
sub _whats_in_there {
    my ($self, $aref) = @_;
    my @text = @$aref;
    #print "@text", "\n";
    my %chars;
    map {
        my $c = $_;
        my $C = chr($c);
        map {
            my $n;
            $chars{$C} = 1 if $_ =~ /\Q$C\E/;
            die "$.Class - space unacceptable in pattern\n"
                if $C eq " " && defined $chars{$C} && $chars{$C} == 1;
        } @text;
    } 1 .. 255;

    # preserve our character set
    $.chars = \%chars;
}

sub _right {
    my ($self, $text, $char) = @_;
    my @text = split(//, $text);
    my $first;
    my $last;
    if ($text =~ /$char/) {
        $first = pos($text);
        $last = rindex $text, $char;
    }
    return ($first, $last);
}

# determine vertical range of a specific character in our pattern
sub _vrange {
    my ($self, $textRef, $char) = @_;
    my $top;
    my $bottom;
    my $n = 0;
    map {
        $top    = $n if $_ =~ /$char/ && !defined $top;
        $bottom = $n if $_ =~ /$char/;
        $n++;
    } @$textRef;
    return ($top, $bottom);
}

sub _first {
    my ($self, $textRef, $char) = @_;
    my @text = @$textRef;
    my $first;
    map {
        my $n = index $_, $char;
        unless (defined $first) {
            $first = $n if $n >= 0;
        }
        if (defined $first && $n >= 0) {
            die "$.Class - char $char appears misaligned\n"
                if $n < $first;
        }
    } @text;
    return $first;
}

sub _last {
    my ($self, $textRef, $char) = @_;
    my @text = @$textRef;
    my $last;
    map {
        my $n = rindex $_, $char;
        unless (defined $last) {
            $last = $n if $n >= 0;
        }
        if (defined $last && $n >= 0) {
            die "$.Class - char $char appears misaligned\n"
                if $n > $last;
        }
    } @text;
    return $last;
}

sub _range {
    my ($self, $textRef, $char) = @_;
    my ($top, $bottom) = ./_vrange($textRef, $char);
    my $left  = ./_first($textRef, $char);
    my $right = ./_last($textRef, $char);
    return ($top, $bottom, $left, $right);
}

# simple equation to map char ranges to something else
sub _stretch_offset {
    my ($self, $i1, $i2, $o1, $o2) = @_;
    # handle single characters
    $i2 = $i1 + 1 if $i1 == $i2;
    my $stretch = ($o2-$o1)/($i2-$i1);
    my $offset = $o1-($i1*$stretch);
    return ($stretch, $offset);
}

=head2 B<range>

  ($ymin, $ymax, $xmin, $xmax) = $tl->range($char);

The range of positions for the specified character. B<Note
order of arguments> returned.

=cut

sub range {
    my ($self, $char) = @_;
    #return () unless defined $.Ranges{$char};
    return ./_range($.textRef, $char);
}

=head2 B<characters>

  @chars = $tl->characters();

Return list of all of the unique characters in our pattern.

=cut

sub characters {
    my ($self) = @_;
    return sort keys %.Ranges;
}

=head2 B<text_size>

  ($width, $height) = $tl->text_size();

Find width & height of our pattern in character units. This may
be important since the user of a GUI is free to resize in a way
that messes up the relative aspect ratio as you defined in the
pattern. And you may want to correct this awful situation.

=cut

sub text_size {
    my ($self) = @_;
    my $h = ./_height($.textRef);
    my $w = ./_widest($.textRef);
    return ($w, $h);
}

=head2 B<width>

  $tl->width();

Return width of our pattern (in # characters).

=cut

sub width {
    my ($self) = @_;
    my $w = ./_widest($.textRef);
    return $w;
}

=head2 B<height>

  $tl->height();

Return height of our pattern (in # characters).

=cut

sub height {
    my ($self) = @_;
    my $h = ./_height($.textRef);
    return $h;
}

=head2 B<map_range>

  @bbox = $tl->map_range($width, $height, $char);

Map the relative position and size of the indicated character ($char)
region in our pattern to a real XY coordinate space.

@bbox is the bounding box, returned as ($x1, $y1, $x2, $y2), where
$x1, $y1 is the upper left corner, and $x2, $y2 is the lower right.

Because this was written (primarily) to interface to a GUI, 
the origin is assumed
to be 0,0 in the upper left corner, with x bigger to the right, and
y bigger down. Adjust as necessary to fit your problem domain.

=cut

sub map_range {
    my ($self, $width, $height, $char) = @_;
    my @r = @{$.Ranges{$char}};
    my $h = ./_height($.textRef);
    my $w = ./_widest($.textRef);
    my ($xs, $xo) = ./_stretch_offset(0, $w, 0, $width);
    my ($ys, $yo) = ./_stretch_offset(0, $h, 0, $height);
    my $xEqn = sub { my ($x) = @_; my $y = $xs*$x + $xo; return $y; };
    my $yEqn = sub { my ($y) = @_; my $x = $ys*$y + $yo; return $x; };
    my $xmin = $xEqn->($r[2]);
    my $ymin = $yEqn->($r[0]), 
    my $xmax = $xEqn->($r[3]-$r[2]+1)+$xmin;
    my $ymax = $yEqn->($r[1]-$r[0]+1)+$ymin;
    my @bbox = ($xmin, $ymin, $xmax-1, $ymax-1);
    return @bbox;
}

# find out if there is overlap; $c0 and $c1 are array references
sub _check_overlap {
    my ($self, $c0, $c1) = @_;
    my %x;
    my @x0 = @$c0;
    my @x1 = @$c1;
    $x{$_}  = 1 foreach $x0[0] .. $x0[1];
    $x{$_} += 1 foreach $x1[0] .. $x1[1];
    my $status;
    map {
        $status = 1 if $x{$_} > 1;
    } keys(%x);
    return defined $status ? 1 : 0;
}

# are they in same x range?
sub _in_x {
    my ($self, $me, $other) = @_;
    my @x = ($me->[2], $me->[3]);
    my @xo = ($other->[2], $other->[3]);
    return ./_check_overlap(\@x, \@xo);
}

# are they in same y range?
sub _in_y {
    my ($self, $me, $other) = @_;
    my @y = ($me->[0], $me->[1]);
    my @yo = ($other->[0], $other->[1]);
    return ./_check_overlap(\@y, \@yo);
}

=head2 B<above>

  @r = $tl->above($char);

Return a list (possibly empty) of each of the characters
above (and adjacent) to the specified character.

=cut

sub above {
    my ($self, $char) = @_;
    my @r = @{$.Ranges{$char}};
    return () if $r[0] == 0;
    return @{$.Above{$char}} if defined $.Above{$char};
    my @keys = keys(%.Ranges);
    my @d;
    map {
        if ($_ ne $char) {
        #print "Comparing $_ ";
        my @other = @{$.Ranges{$_}};
        push(@d, $_) if ./_in_x(\@r, \@other) && 
            ($other[0] == ($r[0]-1) || $other[1] == ($r[0]-1));
        }
    } @keys;
    $.Above{$char} = \@d;
    #print "Above $char @d\n";
    return @d;
}

=head2 B<below>

  @r = $tl->below($char);

Return a list (possibly empty) of each of the characters
below (and adjacent) to the specified character.

=cut

sub below {
    my ($self, $char) = @_;
    my @r = @{$.Ranges{$char}};
    return () if $r[1] == ./width();
    return @{$.Below{$char}} if defined $.Below{$char};
    my @keys = keys(%.Ranges);
    my @d;
    map {
        if ($_ ne $char) {
        my @other = @{$.Ranges{$_}};
        push(@d, $_) if ./_in_x(\@r, \@other) && 
            ($other[0] == ($r[0]+1) || $other[1] == ($r[0]+1));
        }
    } @keys;
    $.Below{$char} = \@d;
    return @d;
}

=head2 B<left>

  @r = $tl->left($char);

Return a list (possibly empty) of each of the characters to
the left (and adjacent) to the specified character.

=cut

sub left {
    my ($self, $char) = @_;
    my @r = @{$.Ranges{$char}};
    return () if $r[2] == 0;
    return @{$.Left{$char}} if defined $.Left{$char};
    my @keys = keys(%.Ranges);
    my @d;
    map {
        if ($_ ne $char) {
        my @other = @{$.Ranges{$_}};
        push(@d, $_) if ./_in_y(\@r, \@other) && 
            ($other[3] == ($r[2]-1));
        }
    } @keys;
    $.Left{$char} = \@d;
    return @d;
}

=head2 B<right>

  @r = $tl->right($char);

Return a list (possibly empty) of each of the characters to
the right (and adjacent) to the specified character.

=cut

sub right {
    my ($self, $char) = @_;
    my @r = @{$.Ranges{$char}};
    return () if $r[2] == ./width();
    return @{$.Right{$char}} if defined $.Right{$char};
    my @keys = keys(%.Ranges);
    my @d;
    map {
        if ($_ ne $char) {
        my @other = @{$.Ranges{$_}};
        push(@d, $_) if ./_in_y(\@r, \@other) && 
            ($other[2] == ($r[3]+1));
        }
    } @keys;
    $.Right{$char} = \@d;
    return @d;
}

=head2 B<range_as_percent>

  ($xpercent, $ypercent) = $tl->range_as_percent($char);

Returns the percentage of x and y that this character consumes
in the I<pattern>. Number returned for each is <= 1.0.

=cut

sub range_as_percent {
    my ($self, $char) = @_;
    my ($ymin, $ymax, $xmin, $xmax) = ./range($char);
    my $width  = ./width();
    my $height = ./height();
    return (($xmax-$xmin+1)/$width, ($ymax-$ymin+1)/$height);
}

=head2 B<order>

  @chars = $tl->order([$line]);

Return the order of the characters encountered on line $line
(zero-based). $line defaults to zero if not specified.

=cut

sub order {
    my ($self, $line) = @_;
    $line = 0 unless defined $line;
    die "$.Class - in order, line $line is too big!\n"
        unless $line < ./height();
    my $text = $.textRef[$line];
    return unless defined $text;
    my %Chars;
    my @Chars;
    my @chars = split('', $text);
    map {
        unless (defined $Chars{$_}) {
            push(@Chars, $_);
            $Chars{$_} = 1;
        }
    } @chars;
    return @Chars;
}

=head2 B<only_one>

  $stat = $tl->only_one();

Returns 1 if there is only a single character in your pattern,
0 if there are more.

=cut

sub only_one {
    my ($self) = @_;
    return ./order() == 1;
}

=head1 AUTHOR

X Cramps, C<< <cramps.the at gmail.com> >>

=head1 BUGS

There shouldn't be any. But I am a human, and do mess up sometimes.

Please report any bugs or feature requests to C<bug-acme-textlayout 
at rt.cpan.org>, or through
the web interface at 
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Acme-TextLayout>.  
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Acme::TextLayout

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Acme-TextLayout>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Acme-TextLayout>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Acme-TextLayout>

=item * Search CPAN

L<http://search.cpan.org/dist/Acme-TextLayout/>

=back

=head1 ACKNOWLEDGEMENTS

Captain Beefheart and Ella Guru. So there.

=head1 COPYRIGHT & LICENSE

Copyright 2009 X Cramps, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Acme::TextLayout
