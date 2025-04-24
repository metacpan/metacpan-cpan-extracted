use strict;
use warnings;
package CatalystX::Test::MockContext;
use Plack::Test;
use Class::Load ();

our $VERSION = '0.000004';

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

version 0.000004

=head1 SYNOPSIS

  use HTTP::Request::Common;
  use CatalystX::Test::MockContext;

  my $m = mock_context('MyApp');
  my $c = $m->(GET '/');

=head1 EXPORTS

=head2 mock_context

 my $sub = mock_context('MyApp');

This function returns a closure that takes an L<HTTP::Request> object and returns a
L<Catalyst> context object for that request.

=head1 SOURCE

The development version is on github at L<https://github.com/robrwo/CatalystX-Test-MockContext>
and may be cloned from L<git://github.com/robrwo/CatalystX-Test-MockContext.git>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/robrwo/CatalystX-Test-MockContext/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head2 Reporting Security Vulnerabilities

Security issues should not be reported on the bugtracker website.  Please see F<SECURITY.md> for instructions how to
report security vulnerabilities.

=head1 AUTHOR

Eden Cardim <edencardim@gmail.com>

Currently maintained by Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017, 2025 by Eden Cardim.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
