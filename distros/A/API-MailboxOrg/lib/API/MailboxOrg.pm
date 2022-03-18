package API::MailboxOrg;

use v5.24;

# ABSTRACT: Perl library to work with the API for the Mailbox.org API

use strict;
use warnings;

use Carp;
use Moo;
use Mojo::File;
use Mojo::Loader qw(find_modules load_class);
use Mojo::UserAgent;
use Mojo::Util qw(decamelize);
use Scalar::Util qw(weaken);
use Types::Mojo qw(:all);
use Types::Standard qw(Str);

use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '1.0.1'; # VERSION

has user     => ( is => 'ro', isa => Str, required => 1 );
has password => ( is => 'ro', isa => Str, required => 1 );
has token    => ( is => 'rwp', isa => Str );
has host     => ( is => 'ro', isa => MojoURL["https?"], default => sub { 'https://api.mailbox.org' }, coerce => 1 );
has base_uri => ( is => 'ro', isa => Str, default => sub { 'v1/' } );

has client   => (
    is      => 'ro',
    lazy    => 1,
    isa     => MojoUserAgent,
    default => sub {
        Mojo::UserAgent->new
    }
);

sub _load_namespace ($package) {
    my @modules = find_modules $package . '::API', { recursive => 1 };

    for my $module ( @modules ) {
        load_class( $module );

        my $base = (split /::/, $module)[-1];

        no strict 'refs'; ## no critic
        *{ $package . '::' . decamelize( $base ) } = sub ($api) {
            weaken $api;
            state $object //= $module->instance(
                api => $api,
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

API::MailboxOrg - Perl library to work with the API for the Mailbox.org API

=head1 VERSION

version 1.0.1

=head1 SYNOPSIS

    use API::MailboxOrg;
    use Data::Printer;

    my $api = API::MailboxOrg->new(
        user     => 'test_name@example.tld',
        password => 'test1234567789',
    );

    my $all_videochats = $api->videochat->list(
        mail => 'test_name@example.tld',
    );
    p $all_videochats;

=head1 INFO

This is still pretty alpha. The API of this distribution might change.

=head1 ATTRIBUTES

=over 4

=item * base_uri

I<(optional)> Default: C</v1>

=item * client 

I<(optional)> A C<Mojo::UserAgent> compatible user agent. By default a new object of C<Mojo::UserAgent>
is created.

=item * host

I<(optional)> This is the URL to Mailbox.org API. Defaults to C<https://api.mailbox.org>

=item * token

After authenticating, this will be the auth id.

=back

=head1 METHODS

=over 4

=item * account

=item * backup

=item * base

=item * blacklist

=item * capabilities

=item * context

=item * domain

=item * hello

=item * invoice

=item * mail

=item * mailinglist

=item * password

=item * passwordreset

=item * spamprotect

=item * test

=item * user

=item * utils

=item *   validate

=item *   videochat

=back

=head1 MORE INFOS

The Mailbox.org API documentation is available at L<https://api.mailbox.org/v1/doc/methods/index.html>.

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
