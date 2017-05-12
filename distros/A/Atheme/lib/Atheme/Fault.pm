package Atheme::Fault;
our $VERSION = '0.0001';
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(fault_needmoreparams fault_badparams fault_nosuch_source fault_nosuch_target fault_authfail fault_noprivs fault_nosuch_key fault_alreadyexists fault_toomany fault_emailfail fault_notverified fault_nochange fault_already_authed fault_unimplemented );

use constant {
    fault_needmoreparams => 1,
    fault_badparams      => 2,
    fault_nosuch_source  => 3,
    fault_nosuch_target  => 4,
    fault_authfail       => 5,
    fault_noprivs        => 6,
    fault_nosuch_key     => 7,
    fault_alreadyexists  => 8,
    fault_toomany        => 9,
    fault_emailfail      => 10,
    fault_notverified    => 11,
    fault_nochange       => 12,
    fault_already_authed => 13,
    fault_unimplemented  => 14,
};

=head1 NAME

Atheme::Fault - Atheme Fault codes

=head1 VERSION

version 0.0001

=head1 DESCRIPTION

This class provides fault codes for Atheme

=head1 AUTHORS

Pippijn van Steenhoven <pip88nl@gmail.com>
Stephan Jauernick <stephan@stejau.de>

=cut

1;