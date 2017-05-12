package Acme::Curses::Marquee;

use warnings;
use strict;
use Curses qw( addstr refresh );

=head1 NAME

Acme::Curses::Marquee - Animated Figlet!

=head1 VERSION

Version 1.0

=cut

our $VERSION = '1.0';

=head1 SYNOPSIS

Acme::Curses::Marquee implements a scrolling messageboard widget,
using C<figlet> to render the text.

    use Curses;
    use Acme::Curses::Marquee;

    initscr;

    # curses halfdelay mode is what actually drives the display
    # and its argument is what determines the rate of the crawl
    halfdelay(1);

    # spawn subwindow to hold marquee and create marquee object
    my $mw = subwin(9,80,0,0);
    my $m = Acme::Curses::Marquee->new( window => $mw,
                                        height => 9,
                                        width  => 80,
                                        font   => larry3d,
                                        text   => 'hello, world' );

    # then, in the event loop
    while (1) {
        my $ch = getch;
        do_input_processing_and_other_crud();
        $m->scroll;
    }

=head1 METHODS

=head2 new

Creates a new A::C::M object. Three arguments are required:

    * window
    * height
    * width

C<window> should be a curses window that the marquee can write
to. C<height> and C<width> should be the height and width of that
window, in characters.

There are also two optional arguments: C<font>, which sets the figlet
font of the marquee (defaults to the figlet default, 'standard'), and
C<text> which will set an initial string to be displayed and cause the
marquee to start display as soon as it is created.

=cut

sub new {
    my ($class,%args) = @_;

    die "Can't create marquee object without a host window\n" 
        unless( defined $args{window} );
    die "Can't create marquee object without height value\n" 
        unless( defined $args{height} );
    die "Can't create marquee object without width value\n" 
        unless( defined $args{width} );

    my $self = bless { win    => $args{window},
                       height => $args{height},
                       width  => $args{width},
                       font   => $args{font} || 'standard',
                       srctxt => $args{text} || undef, 
                       figtxt => '',
                       txtlen => 0,
                       offset => 0,
                       active => 0,
                     }, $class;

    $self->text($self->{srctext}) if (defined $self->{srctxt});

    return $self;
}

=head2 scroll

Scroll the marquee one position to the right.

=cut

sub scroll {
    my $self = shift;
    my $w    = $self->{win};
    my $x    = $self->{width};
    my $y    = $self->{height};
    my $len  = $self->{txtlen};
    my $off  = $self->{offset};
    my $fig  = $self->{figtxt};

    for (0..$y) { addstr($w, $_, 0, (' ' x $x)) }

    $self->{offset} = 0 if ($self->{offset} == $len);

    foreach my $i (0..(@{$fig} - 1)) {
        if ($off + $x > $len) {
            my $end = $len - $off;
            my $rem   = $x - $end;
            my $tmp = substr($fig->[$i],$off,$end);
            $tmp   .= substr($fig->[$i],0,$rem);
            addstr($w, $i, 0, $tmp);
        } else {
            addstr($w, $i, 0, substr($fig->[$i],$off,$x));
        }
    }
    $self->{offset}++;
    refresh($w);
}

=head2 text

Take a new line of text for the marquee...

   $m->text("New line of text");

...render it via figlet, split it into an array, and perform width
adjustments as neccessary. Store the new text, figleted text, length
of figleted text lines, and set marquee state to active.

=cut

sub text {
    my ($self,$text) = @_;
    my $font  = $self->{font};
    my $width = length($text) * 12;
    my $line  = 0;

    # render text via figlet
    my @fig = split(/\n/,`figlet -f $font -w $width '$text'`);

    # find longest line length
    foreach my $i (0..(@fig - 1)) {
        $line = length($fig[$i]) if (length($fig[$i]) > $line);
    }

    # set line length to window width if shorter than that
    $line = $self->{width} if ($line < $self->{width});

    # pad all lines window width or longest length + 5
    foreach my $i (0..(@fig - 1)) {
        my $len = length($fig[$i]);
        my $pad = $line - $len;
        $pad += 25 if ($len > ($self->{width} - 6));
        $fig[$i] = join('',$fig[$i],(' 'x $pad));
    }
    
    $self->{active} = 1;
    $self->{offset} = 0;
    $self->{srctxt} = $text;
    $self->{txtlen} = length($fig[0]);
    $self->{figtxt} = \@fig;
}

=head2 font

Sets the font of the marquee object and then calls C<text> to make the
display change.

    $m->font('univers')

This method should not be called before the marquee object is active.
No checking is done to ensure the spacified font exists.

=cut

sub font {
    my ($self,$font) = @_;
    $self->{font} = $font;
    $self->text($self->{srctxt});
}

=head2 is_active

Returns the marquee object's status (whether text has been set or not)

=cut

sub is_active {
    my $self = shift;
    return $self->{active};
}

=head1 TODO

A couple of nice transitions when changing the message would be good.

Left-to-right scrolling?

=head1 AUTHOR

Shawn Boyette, C<< <mdxi@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-acme-curses-marquee@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Acme-Curses-Marquee>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2005 Shawn Boyette, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Acme::Curses::Marquee
