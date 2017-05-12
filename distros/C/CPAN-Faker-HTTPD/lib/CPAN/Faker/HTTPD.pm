package CPAN::Faker::HTTPD;
{
  $CPAN::Faker::HTTPD::VERSION = '0.002';
}

# ABSTRACT: Run a bogus CPAN web server for testing

use strict;
use warnings;
use Test::Fake::HTTPD;
use HTTP::Message::PSGI;
use Plack::App::File;
use File::Temp;
use Moose;
use namespace::clean -except => 'meta';

extends 'CPAN::Faker';

has '+dest' => (
    is       => 'ro',
    isa      => 'Str',
    required => 0,
    default  => sub { File::Temp::tempdir( CLEANUP => 1 ) },
);

has 'httpd' => (
    is      => 'ro',
    isa     => 'Test::Fake::HTTPD',
    handles => [qw(port host_post endpoint)],
    default => sub { Test::Fake::HTTPD->new },
);

has 'server' => (
    is      => 'ro',
    isa     => 'Plack::Component',
    handles => { serve => 'call' },
    default => sub { Plack::App::File->new( root => $_[0]->dest ) },
);

has 'app' => (
    is      => 'ro',
    isa     => 'CodeRef',
    default => sub {
        my $self = shift;
        return sub { $self->serve($_[0]->to_psgi) },
    },
);

sub BUILD {
    my $self = shift;
    $self->httpd->run( $self->app );
};

__PACKAGE__->meta->make_immutable;


__END__
=pod

=head1 NAME

CPAN::Faker::HTTPD - Run a bogus CPAN web server for testing

=head1 VERSION

version 0.002

=head1 SYNOPSIS

  use CPAN::Faker::HTTPD;
  use LWP::Simple;

  my $cpan = CPAN::Faker::HTTPD->new({ source => './eg' });
  $cpan->make_cpan;

  my $uri = $cpan->endpoint;
  $uri->path( '/authors/id/P/PS/PSHANGOV/Miril-0.008.tar.gz' );

  my $content = LWP::Simple::get( $uri );

$cpan->make_cpan;

=head1 DESCRIPTION

This module is a subclass of L<CPAN::Faker> that additionally supplies a
running webserver (via L<Test::Fake::HTTPD>). It is useful for testing code
that interacts with remote CPAN mirrors.

=head1 METHODS

=head2 port

Port number of the running server. The port is dynamically determined by
L<Test::Fake::HTTPD> during initialization. If you need to specify the port
number explicitly, you will have to create a L<Test::Fake::HTTPD> object
with the respective options manually, and pass it to L<CPAN::Faker::HTTPD>
as the C<httpd> parameter on construction.

See L<Test::Fake::HTTPD> for details.

-head2 host_port

Host and port of the running server.

See L<Test::Fake::HTTPD> for details.

=head2 endpoint

L<URI> object for the full address of the running server (e.g.
C<http://127.0.0.1:{port}>).

See L<Test::Fake::HTTPD> for details.

=head2 httpd

An instance of L<Test::Fake::HTTPD>. Can be overriden during construction.

See L<Test::Fake::HTTPD> for details.

=head2 server

Plack application that will handle the serving of files. The default is
an instance of L<Plack::App::File>, which will simply serve any static
files under the fake CPAN. Can be overriden during construction.

=head2 app

Coderef that will be passed to L<Test::Fake::HTTPD/run>. It converts the
L<HTTP::Request> object to a L<PSGI> environment hash before transferring
control on to the L</server>. Can be overriden during construction.

=head2 dest

Directory in which to construct the CPAN instance. Same as in L<CPAN::Faker>,
but not required any more. If not supplied, a temporary directory will be
used, as presumably it is the repository uri rather than the repository path
that users of this module will test against.

See L<CPAN::Faker> for details.

=head2 make_cpan

See L<CPAN::Faker/make_cpan>.

=head2 add_author

See L<CPAN::Faker/add_author>

=head2 index_package

See L<CPAN::Faker/index_package>.

=head2 write_author_index

See L<CPAN::Faker/write_author_index>.

=head2 write_package_index

See L<CPAN::Faker/write_package_index>.

=head2 write_modlist_index

See L<CPAN::Faker/write_modlist_index>.

=head2 write_perms_index

See L<CPAN::Faker/write_perms_index>.

=head2 add_dist

See L<CPAN::Faker/add_dist>.

=head1 SEE ALSO

=over

=item L<CPAN::Faker>

=item L<Test::Fake::HTTPD>

=back

=head1 AUTHOR

Peter Shangov <pshangov@yahoo.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Venda, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

