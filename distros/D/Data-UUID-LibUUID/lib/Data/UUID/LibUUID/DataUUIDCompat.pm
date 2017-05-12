#!/usr/bin/perl

package Data::UUID::LibUUID::DataUUIDCompat;

use strict;
use warnings;

use Carp ();

use asa 'Data::UUID';

sub import {
    my ( $self, @args ) = @_;

    if ( @args ) {
        Carp::croak("Data::UUID exports only apply to v3 uuids, which are not supported by libuuid");
    }
}

sub new { bless {}, shift }

use Data::UUID::LibUUID (
    new_dce_uuid_binary => { -as => "create" },
    new_dce_uuid_binary => { -as => "create_bin" },
    new_dce_uuid_binary => { -as => "create_from_name" },
    new_dce_uuid_binary => { -as => "create_from_name_bin" },
    new_dce_uuid_string => { -as => "create_str" },
    new_dce_uuid_string => { -as => "create_from_name_str" },
);

sub create_b64 { Data::UUID::LibUUID::uuid_to_base64(create()) }
sub create_hex { Data::UUID::LibUUID::uuid_to_hex(create()) }
sub create_from_name_b64 { Data::UUID::LibUUID::uuid_to_base64(create()) }
sub create_from_name_hex { Data::UUID::LibUUID::uuid_to_hex(create()) }

sub from_string    { Data::UUID::LibUUID::uuid_to_binary($_[1]) }
sub from_hexstring { Data::UUID::LibUUID::uuid_to_binary($_[1]) }
sub from_b64string { Data::UUID::LibUUID::uuid_to_binary($_[1]) }

sub to_string      { Data::UUID::LibUUID::uuid_to_string($_[1]) }
sub to_hexstring   { Data::UUID::LibUUID::uuid_to_hex($_[1]) }
sub to_b64string   { Data::UUID::LibUUID::uuid_to_base64($_[1]) }

sub compare { Data::UUID::LibUUID::uuid_compare($_[1], $_[2]) }

__PACKAGE__

__END__

=pod

=head1 NAME

Data::UUID::LibUUID::DataUUIDCompat - Drop in L<Data::UUID> replacement

=head1 SYNOPSIS

	use Data::UUID::LibUUID::DataUUIDCompat;

    my $uuid_gen = Data::UUID::LibUUID::DataUUIDCompat->new; # Data::UUID->new;

    my $bin_uuid = $uuid_gen->create;

=head1 DESCRIPTION

See L<Data::UUID> for the API.

Note that this module does not support version 3 UUIDs (namespace based UUIDs),
so C<create_from_name> is faked. The UUID

=cut


