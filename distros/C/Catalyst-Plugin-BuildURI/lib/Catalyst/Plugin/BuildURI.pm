package Catalyst::Plugin::BuildURI;

use strict;
use warnings;

our $VERSION = '0.1';

use URI;
use URI::Escape qw(uri_escape_utf8);
use Catalyst::Exception;

sub build_uri {
    my $c = shift;
    my ( $namespace, $action_name, $args, $query, $base_uri ) = @_;

    my $action = $c->dispatcher->get_action( $action_name, $namespace );
    Catalyst::Exception->throw("No such action: $action_name, $namespace")
      unless ($action);

		$args = [$args] if(defined $args && !ref $args);
    $args = [ map { uri_escape_utf8($_) } @$args ];

		### for Regex, LocalRegex
    my $path = $c->dispatcher->uri_for_action( $action, $args );

		unless ($path) { ### for other DispatchTypes
        $path ||= $c->dispatcher->uri_for_action($action);
				$path .= ('/' . join( "/", @$args )) if (@$args);
		}

    my $uri = ($base_uri) ? URI->new($base_uri) : $c->request->base->clone;

    if ( my $base_path = $uri->path ) {
        $base_path .= $path;
        $base_path =~ s!/+!/!g;
        $uri->path($base_path);
    }
    else {
        $uri->path($path);
    }
    $uri->port(undef) if ( $uri->port && $uri->port == $uri->default_port );

    if ( my $ref_type = ref $query ) {
        ( $ref_type eq 'ARRAY' || $ref_type eq 'HASH' )
          && $uri->query_form($query);
    }
    else {
        $query && $uri->query($query);
    }

    $uri->as_string;
}

sub build_uri_by_label {
    my $c = shift;
    my ( $namespace, $action_name, $args, $query, $label ) = @_;

    my $base_uri = $c->config->{build_uri}{$label}
      || $c->request->uri->as_string;

    $c->build_uri( $namespace, $action_name, $args, $query, $base_uri );
}

1;
__END__

=head1 NAME

Catalyst::Plugin::BuildURI - Build URI by action name, namespace, and args

=head1 SYNOPSIS

  package MyApp;

  use Catalyst qw/BuildURI/;

  MyApp->config(
    name => 'MyApp',
    build_uri => {
      'app' => 'http://app.art-code.org/',
      'img' => 'http://img.art-code.org/'
    }
  );

  ...

  package MyApp::Controller::Foo::Bar

  sub redirect_target: Regex('^target/(\d{4})/(\d{2})$') {
    my ($self, $c) = @_;

    # some code
  }

  sub redirect_action: Local {
    my ($self, $c) = @_;

    # redirect to "http://www.art-code.org/target/2006/10/?id=zigorou&password=hogehoge"
    $c->response->redirect($c->build_uri('foo/bar', 'redirect_target', [2006, 10], {id => 'zigorou', password => 'hogehoge'}, 'http://www.art-code.org/'));
  }

  sub labeled_redirect_action: Local {
    my ($self, $c) = @_;

    # redirect to "http://app.art-code.org/target/1976/12/?id=zigorou&password=hogehoge"
    $c->response->redirect($c->build_uri_by_label('foo/bar', 'labeled_redirect_action', [1976, 12], 'id=zigorou&password=hogehoge', 'app'));
  }

  ...

  [%# in template %]
  <a href="[% $c.build_uri('foo/bar', 'redirect_target', [2006, 10], {id => 'zigorou', password => 'hogehoge'}, 'http://www.art-code.org/') %]" title="test">redirect to</a>

=head1 DESCRIPTION

This module is building uri string from namespace, action name, args or other.

=head1 METHODS

=head2 build_uri($namespace, $action_name, $args, $base_uri)

Build URI using namespace, action name, args.
optional parameter is base_uri. default is $c->request->uri->as_string;

=head2 build_uri_by_label($namespace, $action_name, $args, $base_uri)

Build URI by labeled base_uri.
Please setting labeled base_uri to config of your application.

=head1 SEE ALSO

L<Catalyst>.
L<URI>.

=head1 AUTHOR

Toru Yamaguchi  C<< <zigorou@cpan.org> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2006, Toru Yamaguchi C<< <zigorou@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.
