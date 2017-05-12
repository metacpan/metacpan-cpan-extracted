package Bit::MorseSignals;

use strict;
use warnings;

=head1 NAME

Bit::MorseSignals - The MorseSignals protocol.

=head1 VERSION

Version 0.08

=cut

our $VERSION = '0.08';

=head1 SYNOPSIS

    use Bit::MorseSignals::Emitter;
    use Bit::MorseSignals::Receiver;

    my $deuce = Bit::MorseSignals::Emitter->new;
    my $pants = Bit::MorseSignals::Receiver->new(done => sub { print $_[1], "\n" });

    $deuce->post('HLAGH') for 1 .. 3;
    $pants->push while defined ($_ = $deuce->pop);

=head1 DESCRIPTION

In unidirectionnal communication channels (such as networking or IPC), the main issue is often to know the length of the message. Some possible solutions are fixed-length messages (which is quite cumbersome) or a special ending sequence (but it no longer can appear in the data). This module proposes another solution, by using a begin/end signature specialized for each message.

An actual implementation is also provided :

=over 4

=item L<Bit::MorseSignals::Emitter> is a base class for emitters ;

=item L<Bit::MorseSignals::Receiver> is a base class for receivers.

=back

Go to those pages if you just want the stuff done and don't care about how it gets there.

=head1 PROTOCOL

Each byte of the data string is converted into its bits sequence, with bits of lowest weight coming first. All those bits sequences are put into the same order as the characters occur in the string.

The header is composed of three bits (lowest weight coming first) :

=over 4

=item - The 2 first ones denote the data type : a value of 0 is used for a plain string, 1 for an UTF-8 encoded string, and 2 for a L<Storable> object. See also the L</CONSTANTS> section ;

=item - The third one is reserved. For compatibility reasons, the receiver should for now enforce the message data type to plain when this bit is lit.

=back

The emitter computes then the longuest sequence of successives 0 (say, m) and 1 (n) in the concatenation of the header and the data. A signature is then chosen :

=over 4

=item - If m > n, we take n+1 times 1 followed by one 0 ;

=item - Otherwise, we take m+1 times 0 followed by one 1.

=back

The signal is then formed by concatenating the signature, the header, the data bits and the reversed signature (i.e. the bits of the signature in the reverse order).

    a ... a b | t0 t1 r | ... data ... | b a ... a
    signature | header  |     data     | reversed signature

The receiver knows that the signature has been sent when it has catched at least one 0 and one 1. The signal is completely transferred when it has received for the first time the whole reversed signature.

=head1 CONSTANTS

=cut

use constant {
 BM_DATA_AUTO     => -1,
 BM_DATA_PLAIN    => 0,
 BM_DATA_UTF8     => 1,
 BM_DATA_STORABLE => 2,
};

=head2 C<BM_DATA_AUTO>

Default for non-references messages. Try to guess if the given scalar is an UTF-8 string with C<Encode::is_utf8>.

=head2 C<BM_DATA_PLAIN>

Treats the data as a plain string. No extra mangling in done.

=head2 C<BM_DATA_UTF8>

Treats the data as an UTF-8 string. The string is C<Encode::encode_utf8>'d in a binary string before sending, and C<Encode::decode_utf8>'d by the receiver.

=head2 C<BM_DATA_STORABLE>

The scalar, array or hash reference given is C<Storable::freeze>'d by the sender and C<Storable::thaw>'d by the receiver.

=head1 EXPORT

The constants L</BM_DATA_AUTO>, L</BM_DATA_PLAIN>, L</BM_DATA_UTF8> and L</BM_DATA_STORABLE> are only exported on request, either by specifying their names or the C<':consts'> tag.

=cut

use base qw<Exporter>;

our @EXPORT         = ();
our %EXPORT_TAGS    = (
 'consts' => [ qw<BM_DATA_AUTO BM_DATA_PLAIN BM_DATA_UTF8 BM_DATA_STORABLE> ]
);
our @EXPORT_OK      = map { @$_ } values %EXPORT_TAGS;
$EXPORT_TAGS{'all'} = [ @EXPORT_OK ];

=head1 DEPENDENCIES

L<Carp> (standard since perl 5), L<Encode> (since perl 5.007003), L<Storable> (idem).

=head1 SEE ALSO

L<Bit::MorseSignals::Emitter>, L<Bit::MorseSignals::Receiver>.

=head1 AUTHOR

Vincent Pit, C<< <perl at profvince.com> >>, L<http://www.profvince.com>.

You can contact me by mail or on C<irc.perl.org> (vincent).

=head1 BUGS

Please report any bugs or feature requests to C<bug-bit-morsesignals at rt.cpan.org>, or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Bit-MorseSignals>.  I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Bit::MorseSignals

Tests code coverage report is available at L<http://www.profvince.com/perl/cover/Bit-MorseSignals>.

=head1 COPYRIGHT & LICENSE

Copyright 2008 Vincent Pit, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Bit::MorseSignals
