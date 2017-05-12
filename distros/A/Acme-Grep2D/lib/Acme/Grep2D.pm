package Acme::Grep2D;

use warnings;
use strict;
use Data::Dumper;
use Perl6::Attributes;

=head1 NAME

Acme::Grep2D - Grep in 2 dimensions

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

    use Acme::Grep2D;

    my $foo = Acme::Grep2D->new(text => ??);
    ...

=head1 DESCRIPTION

For testing another module, I needed the ability to grep in 2 dimensions,
hence this module.

This module can grep forwards, backwards, up, down, and diagonally in a
given text string. Given the text:

  THIST  T S
  .H  H H  II
  ..I II SIHTH
  ...SS    T  T

We can find all occurances of THIS.

Full Perl regexp is allowed, with a few limitations. Unlike regular
grep, you get back (for each match) an array containing array
references with the following contents:

  [$length, $x, $y, $dx, $dy, ??]

Operational note: there is one more argument at the end of the
returned array reference (as indicated by ??). Don't mess with
this. It's reserved for future use.

=head1 METHODS

=cut

=head2 B<new>

  $g2d = Acme::Grep2D->new(text => ??);

Constructor. Specify text pattern to be grepped
(multiline, with newlines).

Example:

  my $text = <<'EOF';
  foobarf
  .o,,,o
  ,,o?f?fr
  <<,b ooa
  ##a#a ob
  @r@@@rbo
  ------ao
  ~~~~~~rf
  EOF

  $g2d = Acme::Grep2D->new(text => $text);
 
Now, our grep will have no problem finding all of the "foobar"
strings in the text (see B<Grep> or other more directional methods).

The author is interested in any novel use you might find for this
module (other than solving newspaper puzzles).

=cut

sub new {
    my ($class, %opts) = @_;
    my $self = \%opts;
    bless $self, $class;
    $.Class = $class;
    ./_required('text');
    ./_init();
    return $self;
}

# check for mandatory options
sub _required {
    my ($self, $name) = @_;
    die "$.Class - $name is required\n" unless defined $self->{$name};
}

# adjust dimensions to be rectangular, and figure out what's
# in there in all directions
sub _init {
    my ($self) = @_;
    my $text = $.text;
    my @text;
    
    # split on newlines, preserving them spatially
    while ((my $n = index($text, "\n")) >= 0) {
        my $chunk = substr($text, 0, $n);
        push(@text, $chunk);
        $text = substr($text, $n+1);
    }
    chomp foreach @text;

    my @len;
    push(@len, length($_)) foreach @text;
    my $maxlen = $len[0];
    my $nlines = @text;

    #determine max length of each string
    map {
        $maxlen = $len[$_] if $len[$_] > $maxlen;
    } 0..($nlines-1);

    # make all lines same length
    map {
        $text[$_] .= ' ' x ($maxlen-$len[$_]);
    } 0..($nlines-1);
    #print Dumper(\@text);

    my @diagLR;
    my @diagRL;
    my @vertical;
    my $x = 0;
    my $y = 0;
    my $max = $nlines;
    $max = $maxlen if $maxlen < $nlines;

    # find text along diagonal L->R
    for (my $char=0; $char < $maxlen; $char++) {
        my @d;
        $x = $char;
        my $y = 0;
        my @origin = ($x, $y);
        map {
            if ($y < $nlines && $x < $maxlen) {
                my $char = substr($text[$y], $x, 1);
                push(@d, $char) if defined $char;
            }
            $x++;
            $y++;
        } 0..$nlines-1;
        unshift(@d, \@origin);
        push(@diagLR, \@d) if @d;
    }

    for (my $line=1; $line < $nlines; $line++) {
        my @d;
        $x = 0;
        my $y = $line;
        my @origin = ($x, $y);
        map {
            if ($y < $nlines && $x < $maxlen) {
                my $char = substr($text[$y], $x, 1);
                push(@d, $char) if defined $char;
            }
            $x++;
            $y++;
        } 0..$nlines-1;
        unshift(@d, \@origin);
        push(@diagLR, \@d) if @d;
    }

    # find text along diagonal R->L
    for (my $char=0; $char < $maxlen; $char++) {
        my @d;
        $x = $char;
        my $y = 0;
        my @origin = ($x, $y);
        map {
            if ($y < $nlines && $x >= 0) {
                my $char = substr($text[$y], $x, 1);
                push(@d, $char) if defined $char;
            }
            $x--;
            $y++;
        } 0..$nlines-1;
        unshift(@d, \@origin);
        push(@diagRL, \@d) if @d;
    }

    for (my $line=1; $line < $nlines; $line++) {
        my @d;
        $x = $maxlen-1;
        my $y = $line;
        my @origin = ($x, $y);
        map {
            if ($y < $nlines && $x >= 0) {
                my $char = substr($text[$y], $x, 1);
                push(@d, $char) if defined $char;
            }
            $x--;
            $y++;
        } 0..$nlines-1;
        unshift(@d, \@origin);
        push(@diagRL, \@d) if @d;
    }

    # find text along vertical
    for (my $char=0; $char < $maxlen; $char++) {
        my @d;
        my @origin = ($char, $y);
        push(@d, substr($text[$_], $char, 1)) for 0..$nlines-1;
        unshift(@d, \@origin);
        push(@vertical, \@d);
    }

    # correct LR to make text greppable
    map {
        my ($coords, @text) = @$_;
        my $text = join('', @text);
        $_ = [$text, $coords];
    } @diagLR;

    # correct RL to make text greppable
    map {
        my ($coords, @text) = @$_;
        my $text = join('', @text);
        $_ = [$text, $coords];
    } @diagRL;

    # correct vertical to make text greppable
    map {
        my ($coords, @text) = @$_;
        my $text = join('', @text);
        $_ = [$text, $coords];
    } @vertical;
    $.diagLR   = \@diagLR;
    $.diagRL   = \@diagRL;
    $.vertical = \@vertical;
    $.maxlen = $maxlen;
    $.nlines = $nlines;
    $.text   = \@text;
}

# reverse a string
sub _reverse {
    my ($self, $text) = @_;
    my @text = split //, $text;
    return join '', reverse(@text);
}

=head2 B<Grep>

  $g2d->Grep($re);  

Find the regular expression ($re) no matter where it occurs in
text.

The difference from a regular grep is that "coordinate" information
is returned for matches. This is the length of the
found match, x and y coordinates, along with
directional movement information (dx, dy). 
It's easiest to use B<extract> to access matches.

=cut

sub Grep {
    my ($self, $re) = @_;
    my @matches;

    # find things "normally," like a regular grep
    push(@matches, ./grep_h($re));

    # find things in the L->R diagonal vector
    push(@matches, ./grep_lr($re));

    # find things in the R->L diagonal vector
    push(@matches, ./grep_rl($re));

    # find things in the vertical vector
    push(@matches, ./grep_v($re));

    return @matches;
}

sub _ref {
    my ($self, $ref) = @_;
    return \$ref if ref($ref) eq 'SCALAR';
    return \$ref->[0] if ref($ref) eq 'ARRAY';
}

=head2 B<grep_hf>

  @matches = $g2d->grep_hf($re);

Search text normally, left to right.

=cut

sub grep_hf {
    my ($self, $re) = @_;
    my @matches;
    my $n = 0;
    # find things "normally," like a regular grep
    foreach (@{$.text}) {
        my $text = $_;
        while ($text =~/($re)/g) {
            push(@matches, [length($1), _start(\$text,$1), $n, 1, 0, \$_])
        }
        $n++;
    };
    return @matches;
}

=head2 B<grep_hr>

  @matches = $g2d->grep_hf($re);

Search text normally, but right to left.

=cut

sub grep_hr {
    my ($self, $re) = @_;
    my @matches;
    my $n = 0;
    # find things "normally," like a regular grep
    foreach (@{$.text}) {
        my $text = $_;
        $text = ./_reverse($text);
        while ($text =~/($re)/g) {
            push(@matches, 
                [length($1), length($text)-(_start(\$text,$1)+1), 
                $n, -1, 0, \$_]) 
        }
        $n++;
    };
    return @matches;
}

=head2 B<grep_h>

  @matches = $g2d->grep_h($re);

Search text normally, in both directions.

=cut

sub grep_h {
    my ($self, $re) = @_;
    my @matches;
    push(@matches, ./grep_hf($re));
    push(@matches, ./grep_hr($re));
    return @matches;
}


=head2 B<grep_vf>

  @matches = grep_vf($re);

Search text vertically, down.

=cut

sub grep_vf {
    my ($self, $re) = @_;
    my @matches;
    # find things in the vertical vector
    foreach (@{$.vertical}) {
        my ($text, $coords) = @$_;
        my ($x, $y) = @$coords;
        push(@matches, [length($1), $x, _start(\$text, $1), 
            0, 1, \$_]) while ($text =~ /($re)/g);
    }
    return @matches;
}

=head2 B<grep_vr>

  @matches = grep_vr($re);

Search text vertically, up.

=cut

sub grep_vr {
    my ($self, $re) = @_;
    my @matches;
    # find things in the vertical vector
    foreach (@{$.vertical}) {
        my ($text, $coords) = @$_;
        my ($x, $y) = @$coords;
        $text = ./_reverse($text);
        push(@matches, [length($1),$x, length($text)-_start(\$text, $1)-1,
            0, -1, \$_]) while ($text =~ /($re)/g);
    }
    return @matches;
}

=head2 B<grep_v>

  @matches = $g2d->grep_v($re);

Search text vertically, both directions.

=cut

sub grep_v {
    my ($self, $re) = @_;
    my @matches;
    push(@matches, ./grep_vf($re));
    push(@matches, ./grep_vr($re));
    return @matches;
}

=head2 B<grep_rlf>

  @matches = $g2d->grep_rlf($re);

Search the R->L vector top to bottom.

=cut

sub grep_rlf {
    my ($self, $re) = @_;
    my @matches;
    # find things in the R->L diagonal vector
    foreach (@{$.diagRL}) {
        my ($text, $coords) = @$_;
        my ($x, $y) = @$coords;
        while ($text =~ /($re)/g) {
            my $off = _start(\$text, $1);
            my $length = length($1);
            push(@matches, [$length, $x-$off, $off+$y, -1, 1, \$_]);
        }
    }
    return @matches;
}

=head2 B<grep_rlr>

  @matches = $g2d->grep_rlr($re);

Search the R->L vector bottom to top.

=cut

sub grep_rlr {
    my ($self, $re) = @_;
    my @matches;
    # find things in the R->L diagonal vector
    foreach (@{$.diagRL}) {
        my ($text, $coords) = @$_;
        my ($x, $y) = @$coords;
        $text = ./_reverse($text);
        $x -= length($text);
        $y += length($text);
        $x++;
        $y--;
        while ($text =~ /($re)/g) {
            my $off = _start(\$text, $1);
            my $length = length($1);
            push(@matches, [$length, $x+$off, $y-$off, 1, -1, \$_]);
        }
    }
    return @matches;
}

=head2 B<grep_rl>

  @matches = $g2d->grep_rlf($re);

Search the R->L both directions.

=cut

sub grep_rl {
    my ($self, $re) = @_;
    my @matches;
    push(@matches, ./grep_rlf($re));
    push(@matches, ./grep_rlr($re));
    return @matches;
}

=head2 B<grep_lrf>

  @matches = $g2d->grep_lrf($re);

Search the L->R top to bottom.

=cut

sub grep_lrf {
    my ($self, $re) = @_;
    my @matches;
    # find things in the L->R diagonal vector
    foreach (@{$.diagLR}) {
        my ($text, $coords) = @$_;
        my ($x, $y) = @$coords;
        while ($text =~ /($re)/g) {
            my $off = _start(\$text,$1);
            push(@matches, 
                [length($1), $x+$off, $off+$y, 1, 1, \$_]) 
        }
    }
    return @matches;
}

=head2 B<grep_lrr>

  @matches = $g2d->grep_lrr($re);

Search the L->R bottom to top.

=cut

sub grep_lrr {
    my ($self, $re) = @_;
    my @matches;
    # find things in the L->R diagonal vector
    foreach (@{$.diagLR}) {
        my ($text, $coords) = @$_;
        my ($x, $y) = @$coords;
        $text = ./_reverse($text);
        while ($text =~ /($re)/g) {
            my $off = _start(\$text,$1);
            my $length = length($1);
            $x += length($text);
            $y += length($text);
            $x--;
            $y--;
            push(@matches, 
                [length($1), $x-$off, $y-$off, -1, -1, \$_]) 
        }
    }
    return @matches;
}

=head2 B<grep_lr>

  @matches = $g2d->grep_lr($re);

Search the L->R both directions.

=cut

sub grep_lr {
    my ($self, $re) = @_;
    my @matches;
    push(@matches, ./grep_lrf($re));
    push(@matches, ./grep_lrr($re));
    return @matches;
}

=head2 B<extract>

  $result = $g2d->extract($info);

Extract pattern match described by $info, which is a single return
from B<Grep>. E.g.

  my @matches = $g2d->Grep(qr(foo\w+));
  map {
      print "Matched ", $g2d->extract($_), "\n";
  } @matches;

=cut

sub extract {
    my ($self, $info) = @_;
    my ($length, $x, $y, $dx, $dy) = @$info;
    my @result;
    map {
        push(@result, substr($.text->[$y], $x, 1));
        $x += $dx;
        $y += $dy;
    } 1..$length;
    return join('', @result);
}

sub _start {
    my ($textRef, $one) = @_;
    return pos($$textRef) - length($one);
}

=head2 B<text>

  $textRef = $g2d->text();

Return an array reference to our internal text buffer. This
is for future use. Don't mess with the return, or bad things
may happen.

=cut

sub text {
    my ($self) = @_;
    return $.text;
}

=head1 AUTHOR

X Cramps, C<< <cramps.the at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to 
C<bug-acme-grep2d at rt.cpan.org>, or through
the web interface at 
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Acme-Grep2D>.  
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Acme::Grep2D

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Acme-Grep2D>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Acme-Grep2D>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Acme-Grep2D>

=item * Search CPAN

L<http://search.cpan.org/dist/Acme-Grep2D/>

=back


=head1 ACKNOWLEDGEMENTS

Captain Beefheart and the Magic Band. Fast & bulbous. Tight, also.

=head1 COPYRIGHT & LICENSE

Copyright 2009 X Cramps, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
