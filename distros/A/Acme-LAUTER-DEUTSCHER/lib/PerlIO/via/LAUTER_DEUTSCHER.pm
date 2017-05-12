package PerlIO::via::LAUTER_DEUTSCHER;
use strict;
use warnings;

our $VERSION = '1.02';

use Lingua::Translate;
use Carp;

our $fish;

sub import {
    $fish = Lingua::Translate->new( src => 'en', dest => 'de' )
        or croak 'unable to translate from en to de';
}

sub unimport {
    undef $fish;
}

sub PUSHED {
    my $self = '';
    bless \$self, shift;
}

sub FILL {
    my ( $self, $fh ) = @_;
    return defined $fh ? $self->_translate(<$fh>) : undef;
}

sub WRITE {
    my ( $self, $text, $fh ) = @_;
    return 0 unless defined $text;
    if ( my $out = $self->_translate($text) ) {
        print $fh $out;
        return length $out;
    }
    else {
        return -1;
    }
}

sub _translate {
    my ( $self, $line ) = @_;
    return if not ref $fish;
    return if not defined $line or $line !~ /\w/;
    my $out = uc $fish->translate($line);
    for ($out) {
        s/ \b TIMMY \b /DIETER/gsx;        # a solid German name
        s/ (?<=\w) \. (?=\W|\Z) /!/gsx;    # there's no whispering!
    }
    chomp $out;
    return "$out\n";
}

1;

__END__

=head1 NAME

PerlIO::via::LAUTER_DEUTSCHER - a Perl IO layer to make output indistinguishable from someone yelling German

=head1 SYNOPSIS

    use PerlIO::via::LAUTER_DEUTSCHER;
    binmode STDOUT, ':via(LAUTER_DEUTSCHER)'
    print "Timmy pet the cute puppy.\n";

Running the above produces the following output:

    DIETER HAUSTIER DER NETTE WELPE!

=head1 DESCRIPTION

This module provides a Perl IO layer that translates output into German using
L<Lingua::Translate>. In addition to translation, the output is converted to upper
case and the name "Timmy" is changed to "Dieter."

=head1 AUTHOR

Ian Langworth, C<< <ian@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-acme-lauter-deutscher@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically be
notified of progress on your bug as I make changes.

=head1 SEE ALSO

L<Acme::LAUTER::DEUTSCHER>

=head1 COPYRIGHT & LICENSE

Copyright 2005 Ian Langworth, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

