#
# This file is part of DNS-NIOS
#
# This software is Copyright (c) 2021 by Christian Segundo.
#
# This is free software, licensed under:
#
#   The Artistic License 2.0 (GPL Compatible)
#
## no critic
package DNS::NIOS::Traits::ApiMethods;
$DNS::NIOS::Traits::ApiMethods::VERSION = '0.005';

# ABSTRACT: Convenient sugar for NIOS
# VERSION
# AUTHORITY

## use critic
use strictures 2;
use namespace::clean;
use Role::Tiny;

requires qw( create get );

sub create_a_record {
  shift->create( path => 'record:a', @_ );
}

sub create_cname_record {
  shift->create( path => 'record:cname', @_ );
}

sub create_host_record {
  shift->create( path => 'record:host', @_ );
}

sub list_a_records {
  shift->get( path => 'record:a', @_ );
}

sub list_aaaa_records {
  shift->get( path => 'record:aaaa', @_ );
}

sub list_cname_records {
  shift->get( path => 'record:cname', @_ );
}

sub list_host_records {
  shift->get( path => 'record:host', @_ );
}

sub list_ptr_records {
  shift->get( path => 'record:ptr', @_ );
}

sub list_txt_records {
  shift->get( path => 'record:txt', @_ );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DNS::NIOS::Traits::ApiMethods - Convenient sugar for NIOS

=head1 VERSION

version 0.005

=head1 DESCRIPTION

This trait provides convenient methods for calling some API endpoints.

Methods are simply sugar around the basic c<create> and c<get> methods. For example, these two calls are equivalent:

    $n->list_a_records();
    $n->get( path => 'record:a');

=head1 METHODS

=head2 create_a_record( payload => \%payload, [ params => \%params ] )

=head2 create_cname_record( payload => \%payload, [ params => \%params ] )

=head2 create_host_record( payload => \%payload, [ params => \%params ] )

=head2 list_a_records( [ params => \%params ] )

=head2 list_aaaa_records( [ params => \%params ] )

=head2 list_cname_records( [ params => \%params ] )

=head2 list_host_records( [ params => \%params ] )

=head2 list_ptr_records( [ params => \%params ] )

=head2 list_txt_records( [ params => \%params ] )

=head1 AUTHOR

Christian Segundo <ssmn@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2021 by Christian Segundo.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
