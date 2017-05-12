package Business::TW::TSIB::CStorePayment;

use warnings;
use strict;
use Business::TW::TSIB::CStorePayment::Entry;
use DateTime;

=head1 NAME

Business::TW::TSIB::CStorePayment - Module for Taishin Bank Convenient Store Payment Management

=cut

our $VERSION = '0.04';

=head1 SYNOPSIS

    use Business::TW::TSIB::CStorePayment;
    my $csp = Business::TW::TSIB::CStorePayment->new({ corp_code => 'CPCU' });
    my @bar = $csp->generate( { due    => DateTime->new( year => 2007, month => 4, day => 2 ),
                                collect_until => DateTime->new( year => 2007, month => 4, day => 2 ),
                                amount => 3900,
                                ar_id  => '20892' } );

    # render the code39 barcode with GD::Barcode
    my @png = map { GD::Barcode::Code39->new("*$_*")->plot->png } @bar;

    # parse summary from file handler
    my $entries = Business::TW::TSIB::CStorePayment->parse_summary($fh);

    # entries is arrayref of Business::TW::TSIB::CStorePayment::Entry objects,

=head1 DESCRIPTION

This module provides utility functions for the convenient store
payment collection service by TSIB (Taishin International Bank,
Taiwan).

=head1 METHODS

=head2 new( { corp_code => $corp_code} )

Initialize the payment collection context with C<corp_code> provided
by TSIB.

=cut

sub new {
    my $class = shift;
    my $args = shift;
    my $self = {};
    die("No Given Corperation Code") if ( ! exists( $args->{corp_code} ));

    $self->{corp_code} = $args->{corp_code};

    return bless $self , $class;
}

=head2 $csp->generate( $args )

Generate bar codes for the given arguments.  Returns a list of 3
strings that are to be printed as barcode.  $args is a hash ref and
must contain:

=over

=item due

A L<DateTime> object for due day of the payment.

=item collect_until

A L<DateTime> object for last collection date, default to C<due>.

=item amount

The expected amount of the transaction.

=item ar_id

The arbitary account receivable identifier.

=back

=cut

sub generate {
    my $self = shift;
    my $args = shift;

    map { die("No Given $_") if ( !exists( $args->{$_} ) ) } qw/due amount ar_id/;

    $args->{collect_until} ||= $args->{due};
    my $bar1 = sprintf("%02d%02d%02d", $args->{due}->year-1911, $args->{due}->month, $args->{due}->day) . '627';
    my $bar2 = $self->{corp_code}.sprintf("%0".(16 - length($self->{corp_code}))."s", $args->{ar_id});
    my $bar3 = sprintf("%02d%02d", $args->{collect_until}->month, $args->{collect_until}->day).'00'.sprintf("%09d", $args->{amount});

    my $checksum = $self->_compute_checksum($bar1, $bar2, $bar3);
    substr($bar3, 4, 2, $checksum);
    return ($bar1, $bar2, $bar3);
}

use List::Util qw(sum);
use List::MoreUtils qw(apply part);

sub _compute_checksum {
    my $self = shift;
    my (@bar) = apply { tr/A-Z/1-91-92-9/ }@_;
    my $str = $bar[0].'0'.$bar[1].$bar[2];
    my $i = 0;
    my @sum = map { (sum @$_) % 11 } part { $i++ % 2 } split //, $str;
    $sum[0] = { 0 => 'A', '10' => 'B' } -> { $sum[0] } || $sum[0];
    $sum[1] = { 0 => 'X', '10' => 'Y' } -> { $sum[1] } || $sum[1];
    return join('', @sum);
}

=head2 $self->parse_summary($fh)

Parse CStore Payment file

=cut

sub parse_summary {
    my $self = shift;
    my $fh   = shift;

    # format:

    # debit date (8)  
    # paid date (8)  
    # payment id (16)  
    # amount (9) 
    # due (4)  
    # collection agent (8)  
    # payee account (14) 


    my @entries;
    while (<$fh>) {
        chomp;
        next unless length $_;
        my %cols;

        @cols{
            qw/
                debit_date
                paid_date
                payment_id
                amount
                due
                collection_agent
                payee_account/
            }
            = (
            m/
            (.{8})  # debit date
            (.{8})  # paid date  
            (.{16}) # payment id
            (.{9})  # amount
            (.{4})  # due  
            (.{8})  # collection agent  
            (.{14}) # payee account
            /x
            );

        # trim
        map { $cols{$_} =~ s/\s*$//g; $cols{$_} =~ s/^\s*//g; } keys %cols;

        $cols{amount} = int($cols{amount});

        my $entry = Business::TW::TSIB::CStorePayment::Entry->new( \%cols );
        push @entries, $entry;
    }
    return \@entries;
}

=head1 AUTHOR

Chia-liang Kao, C<< <clkao AT aiink.com> >> ,

=head1 BUGS

Please report any bugs or feature requests to
C<bug-business-tw-taishinbank-cstorepayment at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Business-TW-TSIB-CStorePayment>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Business::TW::TSIB::CStorePayment

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Business-TW-TSIB-CStorePayment>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Business-TW-TSIB-CStorePayment>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Business-TW-TSIB-CStorePayment>

=item * Search CPAN

L<http://search.cpan.org/dist/Business-TW-TSIB-CStorePayment>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2007 AIINK co., ltd, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut





1; # End of Business::TW::TSIB::CStorePayment
