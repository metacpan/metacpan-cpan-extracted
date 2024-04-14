package Bundle::WATERKIP::CLI::Azure::Password;
our $VERSION = '0.003';
use Moo;
use namespace::autoclean;
with 'YA::CLI::ActionRole';
use feature qw(say state);

use Azure::AD::Password;
use LWP::UserAgent;
use Types::Standard qw(InstanceOf Enum Str);

sub usage_pod { 1 }

# Allow trailing slashes
state $res_id = Enum(
  [
    qw(
      https://graph.windows.net
      https://management.core.windows.net
      https://graph.windows.net/
      https://management.core.windows.net/
    )
  ]
);

# ABSTRACT: Get Password JWT

has ad => (
  is      => 'ro',
  isa     => InstanceOf[ 'Azure::AD::Password' ],
  lazy    => 1,
  builder => 1,
);

has resource_id => (
    is => 'ro',
    isa => Str,
    default => 'https://graph.windows.net'
);

sub _build_ad {
  my $self = shift;
  return Azure::AD::Password->new(
    %{$self->_cli_args},
    resource_id => $self->resource_id,
  );
}

sub cli_options {
  return (
    'resource_id|resource-id=s', 'client_id|client-id=s',
    'tenant_id|tenant-id=s',     'username=s',
    'password=s',
    'use_at|use-at=s',
  );
}

sub action { 'password' }

sub run {
  my $self = shift;

  my $token = $self->ad->access_token;

  if (!$self->_cli_args->{use_at}) {
      say $token;
      return;
  }

  my $ua = LWP::UserAgent->new();
  $ua->default_header("Authorization", "Bearer $token");

  my $res = $ua->get($self->_cli_args->{use_at});
  if($res->is_success) {
      say $res->decoded_content;
      return;
  }
  say $token;
  die $res->status_line;

}


__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bundle::WATERKIP::CLI::Azure::Password - Get Password JWT

=head1 VERSION

version 0.003

=head1 SYNOPSIS

get-azure-token.pl password --help [ OPTIONS ]

=head1 DESCRIPTION

Get Azure Password JWT tokens

=head1 OPTIONS

=over

=item * --help (this help)

=item * --username (required)

=item * --password (required)

=item * --tenant-id|--tenant_id (required)

=item * --client-id|--client_id (required)

=item * --resource-id|--resource_id (optional)

The URL for which you want a token extended (the URL of the service which you want to obtain a token for).

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
