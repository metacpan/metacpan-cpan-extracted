package App::cryp::Role::Masternode;

use 5.010001;
use strict;
use warnings;

use Role::Tiny;

requires qw(
               new
               list_masternodes
       );

1;
# ABSTRACT: Role for Masternode drivers

__END__

=pod

=encoding UTF-8

=head1 NAME

App::cryp::Role::Masternode - Role for Masternode drivers

=head1 VERSION

This document describes version 0.004 of App::cryp::Role::Masternode (from Perl distribution App-cryp-mn), released on 2021-05-26.

=head1 PROVIDED METHODS

=head1 REQUIRED METHODS

=head2 new

Usage:

 new(%args) => obj

Constructor. Known arguments:

=over

=back

=head2 list_masternodes

Usage: $mn->list_masternodes => [$status, $reason, $payload, \%resmeta]

List all masternodes.

Method must return enveloped result. Payload must be an array containing
masternode names (except when C<detail> argument is set to true, in which case
method must return array of records/hashrefs).

Known options:

=over

=item * detail

Boolean. Default 0. If set to 1, method must return array of records/hashrefs
instead of just array of strings (masternode names).

Record must contain these keys: C<name> (str), C<ip> (IP address, str), C<port>
(port number, uint16). C<collateral_txid> (collateral transaction ID, str),
C<collateral_oidx> (collateral's output index in collateral transaction, uint).
Record can contain additional keys.

=item * with_status

Boolean. Default 0. Only relevant when detail=1.

If set to true, method must return additional record keys: C<status> (str).

Querying status requires querying the list/masternode, so this is not done by
default.

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-cryp-mn>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-cryp-mn>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-App-cryp-mn/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
