package DNS::Hetzner;
$DNS::Hetzner::VERSION = '0.05';
use v5.24;

# ABSTRACT: Perl library to work with the API for the Hetzner DNS

use Mojo::Base -strict, -signatures;

use Carp;
use Moo;
use Mojo::File;
use Mojo::Loader qw(find_modules load_class);
use Mojo::UserAgent;
use Mojo::Util qw(decamelize);
use Types::Mojo qw(:all);
use Types::Standard qw(Str);

use DNS::Hetzner::Schema;

no warnings 'experimental::signatures';

has token    => ( is => 'ro', isa => Str, required => 1 );
has host     => ( is => 'ro', isa => MojoURL["https?"], default => sub { 'https://dns.hetzner.com' }, coerce => 1 );
has base_uri => ( is => 'ro', isa => Str, default => sub { 'api/v1' } );

has client   => (
    is      => 'ro',
    lazy    => 1,
    isa     => MojoUserAgent,
    default => sub {
        Mojo::UserAgent->new,
    }
);

sub _load_namespace ($package) {
    my @modules = find_modules $package . '::API', { recursive => 1 };

    for my $module ( @modules ) {
        load_class( $module );

        my $base = (split /::/, $module)[-1];

        no strict 'refs';
        *{ $package . '::' . decamelize( $base ) } = sub ($dns) {
            state $object //= $module->instance(
                token    => $dns->token,
                base_uri => $dns->base_uri,
                client   => $dns->client,
            );

            return $object;
        };
    }
}

__PACKAGE__->_load_namespace;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DNS::Hetzner - Perl library to work with the API for the Hetzner DNS

=head1 VERSION

version 0.05

=head1 SYNOPSIS

    use DNS::Hetzner;
    use Data::Printer;

    my $dns = DNS::Hetzner->new(
        token => 'ABCDEFG1234567',    # your api token
    );

    my $records = $dns->records;
    my $zones   = $dns->zones;

    my $all_records = $records->list;
    p $all_records;

=head1 INFO

This is still pretty alpha. The API might change.

=head1 ATTRIBUTES

=over 4

=item * base_uri

I<(optional)> Default: C<api/v1>

=item * client 

I<(optional)> A C<Mojo::UserAgent> compatible user agent. By default a new object of C<Mojo::UserAgent>
is created.

=item * host

I<(optional)> This is the URL to Hetzner's Cloud-API. Defaults to C<https://dns.hetzner.com>

=item * token

B<I<(required)>> Your API token.

=back

=head1 METHODS

=head2 records

=head2 zones

=head2 primary_servers

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
