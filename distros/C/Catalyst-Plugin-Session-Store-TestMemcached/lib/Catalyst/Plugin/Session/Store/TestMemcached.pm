package Catalyst::Plugin::Session::Store::TestMemcached;

use Moose;
use namespace::autoclean;
use Test::Memcached;

extends 'Catalyst::Plugin::Session::Store::Memcached';

our $VERSION = '0.001';

(my $memd = Test::Memcached->new)
  ->start;

before 'setup_session', sub {
  (my $self = shift)
    ->_session_plugin_config
    ->{__test_memcached} = $memd;

  $self->_session_plugin_config
    ->{memcached_new_args}
    ->{data} = "127.0.0.1:${\$memd->option('tcp_port')}";
};

__PACKAGE__->meta->make_immutable(inline_constructor => 0);

=head1 NAME

Catalyst::Plugin::Session::Store::TestMemcached - Automatic creation of test Memcached instance

=head1 SYNOPSIS

In your L<Catalyst> application class:

    package MyApp::Web;

    our $VERSION = '0.01';

    use Moose;
    use Catalyst qw/
      Session
      Session::Store::TestMemcached
      Session::State::Cookie
    /;

    extends 'Catalyst';

    __PACKAGE__->setup;
    __PACKAGE__->meta->make_immutable;

Later in a controller:

    package MyApp::Controller::Root;

    use Moose;
    use MooseX::MethodAttributes;

    extends 'Catalyst::Controller';

    sub welcome : Path(welcome) {
      my ($self, $ctx) = @_;
      my $count = ++$ctx->session->{count};
      $ctx->session(count => $count);
      $ctx->res->body("Welcome to Catalyst: $count");
    }

    __PACKAGE__->meta->make_immutable;

=head1 DESCRIPTION

This uses L<Test::Memcached> to make an application scoped instance of a
memcached server, so that if you want to test using memcached as a store for
sessions you don't need to run it in a separate job.

This is probably useful only for testing and prototypes.  Additionally, many
people suggest using memcached, which is not really a persistent data store,
for sessions is not a great practice.  As you wish!

=head1 AUTHOR

John Napiorkowski L<email:jjnapiork@cpan.org>

=head1 SEE ALSO

L<Catalyst::Plugin::Session::Store::Memcached>, L<Catalyst::Plugin::Session>,
L<Catalyst>, L<Test::Memcached>

=head1 COPYRIGHT & LICENSE

Copyright 2012, John Napiorkowski L<email:jjnapiork@cpan.org>

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

