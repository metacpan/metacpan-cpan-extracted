use strict;
use warnings;
package CatalystX::Test::MockContext;
$CatalystX::Test::MockContext::VERSION = '0.000003';
use Plack::Test;
use Class::Load ();

#ABSTRACT: Conveniently create $c objects for testing


use Sub::Exporter -setup => {
  exports => [qw(mock_context)],
  groups => { default => [qw(mock_context)] }
};


sub mock_context {
  my ($class) = @_;
  Class::Load::load_class($class);
  sub {
    my ($req) = @_;
    my $c;
    my $app = sub {
        my $env = shift;

        # legacy implementation handles stash creation via MyApp->prepare

        $c = $class->prepare( env => $env, response_cb => sub { } );
        return [ 200, [ 'Content-type' => 'text/plain' ], ['Created mock OK'] ];
    };

    # handle stash-as-middleware implementation from v5.90070
    if (eval { $Catalyst::VERSION } >= 5.90070) {
        Class::Load::load_class('Catalyst::Middleware::Stash');
        $app = Catalyst::Middleware::Stash->wrap($app);
    }

    test_psgi app => $app,
    client => sub {
      my $cb = shift;
      $cb->($req);
    };
    return $c;
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CatalystX::Test::MockContext - Conveniently create $c objects for testing

=head1 VERSION

version 0.000003

=head1 SYNOPSIS

  use HTTP::Request::Common;
  use CatalystX::Test::MockContext;

  my $m = mock_context('MyApp');
  my $c = $m->(GET '/');

=head1 METHODS

=head2 my $sub = mock_context('MyApp');

This method returns a closure that takes an HTTP::Request object and returns a
L<Catalyst> context object for that request.

=head1 AUTHOR

Eden Cardim <edencardim@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Eden Cardim.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
