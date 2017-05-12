package CatalystX::Routes;
BEGIN {
  $CatalystX::Routes::VERSION = '0.02';
}

use strict;
use warnings;

use Moose::Util qw( apply_all_roles );
use Params::Util qw( _CODELIKE _REGEX _STRING );
use Scalar::Util qw( blessed );

use Moose::Exporter;

Moose::Exporter->setup_import_methods(
    with_meta => [qw( get get_html post put del chain_point )],
    as_is => [qw( chained args capture_args path_part action_class_name )],
);

sub get {
    _add_route( 'GET', @_ );
}

sub get_html {
    _add_route( 'GET_html', @_ );
}

sub post {
    _add_route( 'POST', @_ );
}

sub put {
    _add_route( 'PUT', @_ );
}

sub del {
    _add_route( 'DELETE', @_ );
}

sub _add_route {
    my $rest = shift;
    my $meta = shift;
    my ( $attrs, $sub ) = _process_args( $meta, @_ );

    unless ( exists $attrs->{Chained} ) {
        $attrs->{Chained} = q{/};
    }

    my $name = $_[0];
    $name =~ s{^/}{};

    # We need to turn the full chain name into a path, since two end points
    # from two different chains could have the same end point name.
    $name = ( $attrs->{Chained} eq '/' ? q{} : $attrs->{Chained} ) . q{/}
        . $name;

    $name =~ s{/}{|}g;

    my $meth_base = '__route__' . $name;

    _maybe_add_rest_route( $meta, $meth_base, $attrs );

    my $meth_name = $meth_base . q{_} . $rest;

    $meta->add_method( $meth_name => sub { goto &$sub } );

    return;
}

sub chain_point {
    my $meta = shift;
    my $name = shift;
    _add_chain_point( $meta, $name, chain_point => 1, @_ );
}

sub _add_chain_point {
    my $meta = shift;
    my ( $attrs, $sub ) = _process_args( $meta, @_ );

    my $name = $_[0];
    $name =~ s{/}{|}g;

    $meta->add_method( $name => $sub );

    $meta->name()->config()->{actions}{$name} = $attrs;
}

sub _process_args {
    my $meta = shift;
    my $path = shift;
    my $sub  = pop;

    my $caller = ( caller(2) )[3];

    die
        "The $caller keyword expects a path string or regex as its first argument"
        unless _STRINGLIKE0($path) || _REGEX($path);

    die "The $caller keyword expects a sub ref as its final argument"
        unless _CODELIKE($sub);

    my %p = @_;

    unless ( delete $p{chain_point} ) {
        $p{ActionClass} ||= 'REST::ForBrowsers';
    }

    unless ( $p{PathPart} ) {
        my $part = $path;

        unless ( exists $p{Chained} ) {
            unless ( $part =~ s{^/}{} ) {
                $part = join q{/},
                    $meta->name()->action_namespace('FakeConfig'), $part;
                $part =~ s{^/}{};
            }
        }

        $p{PathPart} = [$part];
    }

    return \%p, $sub;
}

sub _maybe_add_rest_route {
    my $meta  = shift;
    my $name  = shift;
    my $attrs = shift;

    return if $meta->has_method($name);

    $meta->add_method( $name => sub { } );

    $meta->name()->config()->{actions}{$name} = $attrs;

    return;
}

sub chained ($) {
    return ( Chained => $_[0] );
}

sub args ($) {
    return ( Args => [ $_[0] ] );
}

sub capture_args ($) {
    return ( CaptureArgs => [ $_[0] ] );
}

sub path_part ($) {
    return ( PathPart => [ $_[0] ] );
}

sub action_class_name ($) {
    return ( ActionClass => [ $_[0] ] );
}

# XXX - this should be added to Params::Util
sub _STRINGLIKE0 ($) {
    return _STRING( $_[0] )
        || ( defined $_[0]
        && $_[0] eq q{} )
        || ( blessed $_[0]
        && overload::Method( $_[0], q{""} )
        && length "$_[0]" );
}

{

    # This is a nasty hack around some weird back compat code in
    # Catalyst::Controller->action_namespace
    package FakeConfig;
BEGIN {
  $FakeConfig::VERSION = '0.02';
}

    sub config {
        return { case_sensitive => 0 };
    }
}

1;

# ABSTRACT: Sugar for declaring RESTful chained actions in Catalyst



=pod

=head1 NAME

CatalystX::Routes - Sugar for declaring RESTful chained actions in Catalyst

=head1 VERSION

version 0.02

=head1 SYNOPSIS

  package MyApp::Controller::User;

  use Moose;
  use CatalystX::Routes;

  BEGIN { extends 'Catalyst::Controller'; }

  # /user/:user_id

  chain_point '_set_user'
      => chained '/'
      => path_part 'user'
      => capture_args 1
      => sub {
          my $self = shift;
          my $c    = shift;
          my $user_id = shift;

          $c->stash()->{user} = ...;
      };

  # GET /user/:user_Id
  get ''
     => chained('_set_user')
     => args 0
     => sub { ... };

  # GET /user/foo
  get 'foo' => sub { ... };

  sub _post { ... }

  # POST /user/foo
  post 'foo' => \&_post;

  # PUT /root
  put '/root' => sub { ... };

  # /user/plain_old_catalyst
  sub plain_old_catalyst : Local { ... }

=head1 DESCRIPTION

B<WARNING>: This module is still experimental. It works well, but the APIs may
change without warning.

This module provides a sugar layer that allows controllers to declare chained
RESTful actions.

Under the hood, all the sugar declarations are turned into Chained subs. All
chain end points are declared using one of C<get>, C<get_html>, C<post>,
C<put>, or C<del>. These will declare actions using the
L<Catalyst::Action::REST::ForBrowsers> action class from the
L<Catalyst::Action::REST> distribution.

=head1 PUTTING IT ALL TOGETHER

This module is merely sugar over Catalyst's built-in L<Chained
dispatching|Catalyst::DispatchType::Chained> and L<Catalyst::Action::REST>. It
helps to know how those two things work.

=head1 SUGAR FUNCTIONS

All of these functions will be exported into your controller class when you
use C<CatalystX::Routes>.

=head2 get ...

This declares a C<GET> handler.

=head2 get_html

This declares a C<GET> handler for browsers. Use this to generate a standard
HTML page for browsers while still being able to generate some sort of RESTful
data response for other clients.

If a browser makes a C<GET> request and no C<get_html> action has been
declared, a C<get> action is used as a fallback. See
C<Catalyst::TraitFor::Request::REST::ForBrowsers> for details on how
"browser-ness" is determined.

=head2 post ...

This declares a C<POST> handler.

=head2 put

This declares a C<PUT> handler.

=head2 del

This declares a C<DELETE> handler.

=head2 chain_point

This declares an intermediate chain point that should not be exposed as a
public URI.

=head2 chained $path

This function takes a single argument, the previous chain point from which the
action is chained.

=head2 args $number

This declares the number of arguments that this action expects. This should
only be used for the end of a chain.

=head2 capture_args $number

The number of arguments to capture at this point in the chain. This should
only be used for the beginning or middle parts of a chain.

=head2 path_part $path

The path part for this part of the chain. If you are declaring a chain end
point with C<get>, etc., then this isn't necessary. By default, the name
passed to the initial sugar function will be converted to a path part. See
below for details.

=head2 action_class_name $class

Use this to declare an action class. By default, this will be
L<Catalyst::Action::REST::ForBrowsers> for end points. For other parts of a
chain, it simply won't be set.

=head1 PATH GENERATION

All of the end point function (C<get>, C<post>, etc.) take a path as the first
argument. By default, this will be used as the C<path_part> for the chain. You
can override this by explicitly calling C<path_part>, in which case the name
is essentially ignored (but still required).

Note that it is legitimate to pass the empty string as the name for a chain's
end point.

If the end point's name does not start with a slash, it will be prefixed with
the controller's namespace.

If you don't specify a C<chained> value for an end point, then it will use the
root URI, C</>, as the root of the chain.

By default, no arguments are specified for a chain's end point, meaning it
will accept any number of arguments.

=head1 CAVEATS

When adding subroutines for end points to your controller, a name is generated
for each subroutine based on the chained path to the subroutine. Some
template-based views will automatically pick a template based on the
subroutine's name if you don't specify one explicitly. This won't work very
well with the bizarro names that this module generates, so you are strongly
encouraged to specify a template name explicitly.

=head1 BUGS

Please report any bugs or feature requests to
C<bug-catalystx-routes@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically be
notified of progress on your bug as I make changes.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0

=cut


__END__

