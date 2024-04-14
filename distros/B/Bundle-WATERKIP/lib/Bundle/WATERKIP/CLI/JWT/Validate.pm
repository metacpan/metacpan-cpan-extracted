package Bundle::WATERKIP::CLI::JWT::Validate;
our $VERSION = '0.003';
use Moo;
use namespace::autoclean;
with 'YA::CLI::ActionRole';
use feature qw(say);

# ABSTRACT: Validate JWT tokens

use Crypt::JWT qw(decode_jwt);
use Types::Standard qw(Enum);
use LWP::UserAgent;
use List::Util qw(any);

my $providers = Enum(
  [
    qw(
      google_v1
      google_v2
      azure_v1
      azure_v2
    )
  ]
);

my %providers = (
    google_v2 => 'https://www.googleapis.com/oauth2/v2/certs',
    google_v1 => 'https://www.googleapis.com/oauth2/v1/certs',
    azure_v1  => 'https://login.microsoftonline.com/tenantid/discovery/v1.0/keys',
    azure_v2  => 'https://login.microsoftonline.com/tenantid/discovery/v2.0/keys',
);

has provider => (
    is => 'ro',
    isa => $providers,
    predicate => 'has_provider',
);

sub usage_pod { 1 }

sub cli_options {
  return (
    'jwt=s', 'provider=s', 'key_uri=s',
    'tenant_id|tenant-id=s', 'ignore_signature|ignore-signature'
  );
}

sub _croak {
    my $self = shift;
    my $msg = shift;
    return $self->as_help(1, $msg)->run;

}

sub action { 'main' }

sub run {
  my $self = shift;

  my $token = $self->_cli_args->{jwt};

  $self->_croak("You must supply a JWT token") unless defined $token;

  my $uri = $self->_cli_args->{key_uri};
  my $keys;
  if (!$self->_cli_args->{ignore_signature}) {
      if ($self->has_provider) {
          $uri = $providers{$self->provider};

          if (any { $self->provider eq $_ } qw(azure_v1 azure_v2)) {
              my $tenant_id = $self->_cli_args->{tenant_id};
              $self->_croak("You must supply a tenant-id") unless $tenant_id;
              $uri =~ s/tenantid/$tenant_id/;
          }
      }

      $self->_croak("You must supply a provider or URI") unless defined $uri;

      my $ua = LWP::UserAgent->new();
      $ua->default_header('Accept' => 'application/json');
      $ua->default_header('Accept' => 'application/foo');
      my $res = $ua->get($uri);
      die("Unable to get $uri: " . $res->status_line . $/) unless $res->is_success;

      $keys = JSON::XS::decode_json($res->decoded_content);
  }

  my $data = decode_jwt(
      token => $token,
      $self->_cli_args->{ignore_signature} ? ( ignore_signature => 1 ) : (
          kid_keys => $keys,
      ),
      verify_exp => 0,
  );

  use Data::Dumper;
  say "Decrypted token to:\n" . Dumper $data;

}


__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bundle::WATERKIP::CLI::JWT::Validate - Validate JWT tokens

=head1 VERSION

version 0.003

=head1 SYNOPSIS

jwt-decrypt --help [ OPTIONS ]

=head1 DESCRIPTION

Get Azure Password JWT tokens

=head1 OPTIONS

=over

=item * --help (this help)

=item * --provider (optional)

=over 8

=item google_v1

=item google_v2

=item azure_v1

=item azure_v2

=back

=item * --tenant-id|--tenant_id (required when using azure_v1 or azure_v2
provider)

=item * --uri (optional)

The URL where the kid keys can be retreived from. Used when you don't use a
provider

=over 8

=item https://graph.windows.net/

for using the MS Graph API

=item https://management.core.windows.net/

for using the Azure Management APIs

=back

=head1 AUTHOR

Wesley Schwengle <waterkip@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2024 by Wesley Schwengle.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
