#
# This file is part of App-nioscli
#
# This software is Copyright (c) 2021 by Christian Segundo.
#
# This is free software, licensed under:
#
#   The Artistic License 2.0 (GPL Compatible)
#
## no critic
package App::nioscli;
$App::nioscli::VERSION = '0.001';

# ABSTRACT: CLI for NIOS
# VERSION
# AUTHORITY

## use critic
use strictures 2;

use MooseX::App qw(Color Version Config);
use DNS::NIOS;

app_strict(1);
app_namespace;
app_command_register
  'create-a-record'     => 'App::nioscli::Commands::create_a_record',
  'create-cname-record' => 'App::nioscli::Commands::create_cname_record',
  'create-host-record'  => 'App::nioscli::Commands::create_host_record',
  'list-a-records'      => 'App::nioscli::Commands::list_a_records',
  'list-aaaa-records'   => 'App::nioscli::Commands::list_aaaa_records',
  'list-cname-records'  => 'App::nioscli::Commands::list_cname_records',
  'list-host-records'   => 'App::nioscli::Commands::list_host_records',
  'list-ptr-records'    => 'App::nioscli::Commands::list_ptr_records',
  'list-txt-records'    => 'App::nioscli::Commands::list_txt_records',
  'ref-delete'          => 'App::nioscli::Commands::ref_delete',
  'ref-get'             => 'App::nioscli::Commands::ref_get',
  'ref-update'          => 'App::nioscli::Commands::ref_update';

option 'wapi-version' => (
  is            => 'ro',
  isa           => 'Str',
  default       => 'v2.7',
  documentation => 'Specifies the version of WAPI to use',
  required      => 1,
  cmd_env       => 'WAPI_VERSION'
);

option 'username' => (
  is            => 'ro',
  isa           => 'Str',
  required      => 1,
  cmd_env       => 'WAPI_USERNAME',
  documentation => 'Username to use to authenticate the connection to NIOS'
);

option 'password' => (
  is            => 'ro',
  isa           => 'Str',
  required      => 1,
  cmd_env       => 'WAPI_PASSWORD',
  documentation => 'Password to use to authenticate the connection to NIOS'
);

option 'wapi-host' => (
  is            => 'ro',
  isa           => 'Str',
  required      => 1,
  cmd_env       => 'WAPI_HOST',
  documentation => 'DNS host name or address of NIOS.'
);

option 'insecure' => (
  is            => 'ro',
  isa           => 'Bool',
  default       => 0,
  cmd_env       => 'WAPI_INSECURE',
  documentation => 'Enable or disable verifying SSL certificates',
);

option 'scheme' => (
  is      => 'ro',
  isa     => 'Str',
  default => 'https'
);

has 'nios_client' => (
  is      => 'ro',
  isa     => 'Object',
  lazy    => 1,
  default => sub {
    my $self = shift;
    return DNS::NIOS->new(
      username  => $self->{username},
      password  => $self->{password},
      wapi_addr => $self->{'wapi-host'},
      insecure  => $self->{insecure},
      scheme    => $self->{scheme},
      traits    => [ 'DNS::NIOS::Traits::ApiMethods', 'DNS::NIOS::Traits::AutoPager' ]
    );
  }
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::nioscli - CLI for NIOS

=head1 VERSION

version 0.001

=head1 DESCRIPTION

This tool aids the management of the BIND-based DNS included in NIOS appliances.
The following types of DNS records are supported:

=over

=item * A

=item * AAAA

=item * CNAME

=item * PTR

=item * TXT

=back

=head1 OPTIONS

The following options apply to all subcommands:

=over 4

=item * C<config>: Values for all global and specific options can be read from a YAML config file, eg:

    global:
      username: foo
      password: bar
      wapi-host: 10.0.0.1

=item * C<insecure>: Enable or disable verifying SSL certificates. Can be set from C<ENV: WAPI_INSECURE>, default is C<false>.

=item * C<password>: Password to use to authenticate the connection to NIOS. Can be set from C<ENV: WAPI_PASSWORD>.

=item * C<scheme>: Default is C<https>.

=item * C<username>: Username to use to authenticate the connection to NIOS. Can be set from C<ENV: WAPI_USERNAME>.

=item * C<wapi-host>: DNS host name or address of NIOS. Can be set from C<ENV: WAPI_HOST>.

=item * C<wapi-version>: Specifies the version of WAPI to use. Can be set from C<ENV: WAPI_VERSION>, default is C<v2.7>.

=back

=head1 COMMANDS

=over

=item * create-a-record     L<App::nioscli::Commands::create_a_record>

=item * create-cname-record L<App::nioscli::Commands::create_cname_record>

=item * create-host-record  L<App::nioscli::Commands::create_host_record>

=item * list-a-records      L<App::nioscli::Commands::list_a_records>

=item * list-aaaa-records   L<App::nioscli::Commands::list_aaaa_records>

=item * list-cname-records  L<App::nioscli::Commands::list_cname_records>

=item * list-host-records   L<App::nioscli::Commands::list_host_records>

=item * list-ptr-records    L<App::nioscli::Commands::list_ptr_records>

=item * list-txt-records    L<App::nioscli::Commands::list_txt_records>

=item * ref-delete          L<App::nioscli::Commands::ref_delete>

=item * ref-get             L<App::nioscli::Commands::ref_get>

=item * ref-update          L<App::nioscli::Commands::ref_update>

=back

=head1 AUTHOR

Christian Segundo <ssmn@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2021 by Christian Segundo.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
