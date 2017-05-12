package Apache::Hendrix;

# $Id$

use v5.10.0;
use warnings;
use strict;
use Carp;

use Apache2::Const -compile => qw(OK NOT_FOUND);
use Apache2::Request;
use Apache2::RequestIO ();
use Apache2::RequestRec qw/content/;
use Apache2::Response;
use JSON::XS;
use Apache::Hendrix::Route;
use Moose;
use MooseX::FollowPBP;
use MooseX::ClassAttribute;
use Moose::Exporter;
use Template;
use version; our $VERSION = qv(0.3.0);
use DDP;

class_has 'json' => (
    isa     => 'Object', is => 'rw',
    default => sub       { JSON::XS->new()->allow_blessed(1)->convert_blessed(1) },
);
class_has 'handlers'   => ( isa => 'HashRef[ArrayRef]', is => 'rw', default => sub { {} } );
class_has 'class_base' => ( isa => 'Str',               is => 'rw', default => sub {'/'} );
class_has 'request'    => ( isa => 'Apache2::Request',  is => 'rw' );
class_has 'my_template' => (
    isa      => 'HashRef[Template]',
    is       => 'rw',
    default  => sub { {} },
    required => 0,
);

class_has 'my_template_config' => (
    isa     => 'HashRef[HashRef]',
    is      => 'rw',
    default => sub { {} },
);
my $template_config_default = sub {
    {
        INCLUDE_PATH => $ENV{TEMPLATE_PATH},
        INTERPOLATE  => 0,
        POST_CHOMP   => 1,
        EVAL_PERL    => 0,
    }

};
my $template_default = sub {
    return Template->new( __PACKAGE__->my_template_config );
};

class_has 'template_variable' => ( isa => 'HashRef[HashRef]', is => 'rw', required => 0, default => sub { return {} } );

Moose::Exporter->setup_import_methods(
    as_is => [
        qw/handler base
          get post head put any
          template template_config template_variable/
    ] );

sub base {
    return __PACKAGE__->class_base(shift);
}

sub handler {
    my ($r) = @_;

    $r = Apache2::Request->new($r);

    __PACKAGE__->request($r);
    my %params;
    %params = %{ $r->param } if $r->param;

    my $uri = $r->uri;

    # Find handlers for this type of request
    my $handlers =
      __PACKAGE__->handlers->{ $ENV{CONTEXT_PREFIX} }->{ $ENV{REQUEST_METHOD} };

    # 404 if we don't have any
    return Apache2::Const::NOT_FOUND if !$handlers;

    # Check one by one to see if we have a match, either string or regexp
  ROUTE:
    for my $route ( @{$handlers} ) {
        my $base    = $route->get_base();
        my $tmp_uri = $uri;
        $tmp_uri =~ s/^$base//;
        $tmp_uri ||= '/';
        if (
            (
                # RegEXP
                ref( $route->get_path ) eq 'Regexp'
                && $tmp_uri =~ $route->get_path
            )
            || $route->get_path eq $tmp_uri
          )
        {
            my $path = $route->get_path();
            $uri =~ s/^$base\/*//;
            $uri ||= '/';

            $uri =~ m/$path/;

            if (%+) {
                @params{ keys %+ } = values %+;
            }

            my $result = $route->get_method->( \%params, $r, $route );
            if ( ref $result ) {
                return make_json( $r, $result );
            }
            return $result;
        }
    } ## end ROUTE: for my $route ( @{$handlers...})

    # No route found, we 404.
    return Apache2::Const::NOT_FOUND;
} ## end sub handler

sub make_json {
    my ( $r, $object ) = @_;

    my $result = __PACKAGE__->json->encode($object);

    $r->content_type('application/json');
    $r->set_content_length( length($result) );

    print $result;

    return Apache2::Const::OK;
}

## Route Handling

sub route {
    my ( $types, @route ) = @_;
    my $handlers = __PACKAGE__->handlers->{ $ENV{CONTEXT_PREFIX} };
    for my $route_type ( @{$types} ) {
        push @{ $handlers->{$route_type} },
          Apache::Hendrix::Route->new( {
                path   => $route[ 0 ],
                method => $route[ 1 ],
                base   => __PACKAGE__->class_base,
          } );
    }

    __PACKAGE__->handlers->{ $ENV{CONTEXT_PREFIX} } = $handlers;

    return;
}

sub get {    ## no critic (RequireArgUnpacking)
    return route( [ 'GET' ], @_ );
}

sub head {    ## no critic (RequireArgUnpacking)
    return route( [ 'HEAD' ], @_ );
}

sub post {    ## no critic (RequireArgUnpacking)
    return route( [ 'POST' ], @_ );
}

sub put {     ## no critic (RequireArgUnpacking)
    return route( [ 'PUT' ], @_ );
}

sub any {
    my (@route) = @_;

    # If we haven't specified which type, it's truly "any" route.
    # Which for us is currently GET, POST, and HEAD.
    if ( scalar(@route) == 2 ) {
        unshift @route, [ 'GET', 'POST', 'HEAD', 'PUT' ];
    }
    return route(@route);
}

## Template Handling

sub template_config {
    __PACKAGE__->my_template_config->{ $ENV{CONTEXT_PREFIX} } //= {};    # $template_config_default->();
    return __PACKAGE__->my_template_config->{ $ENV{CONTEXT_PREFIX} };
}

sub template {
    my ( $template, $vars ) = @_;
    __PACKAGE__->my_template->{ $ENV{CONTEXT_PREFIX} }
      ||= Template->new( __PACKAGE__->my_template_config->{ $ENV{CONTEXT_PREFIX} } );

    # Copy site variables to template
    if ( __PACKAGE__->template_variable->{ $ENV{CONTEXT_PREFIX} } ) {
        while ( my ( $k, $v ) = each %{ __PACKAGE__->template_variable->{ $ENV{CONTEXT_PREFIX} } } ) {
            $vars->{$k} //= $v;                                       # For the template
        }
    }

    __PACKAGE__->request->content_type('text/html');
    __PACKAGE__->my_template->{ $ENV{CONTEXT_PREFIX} }->process( $template, $vars )
      || croak 'Template process failed: ' . __PACKAGE__->my_template->{ $ENV{CONTEXT_PREFIX} }->error(), "\n";
    return Apache2::Const::OK;
}

__PACKAGE__->meta->make_immutable;

1;

=pod

=head1 NAME

Apache::Hendrix - Provides a route-to-sub based web framework

=head1 SYNOPSIS

use Apache::Hendrix;

my $base = '/web_path/base'

base($base);  # Base for routes form here below

template_variable->{base} = $base;  # Base for templates "base"
template_config->{PRE_PROCESS}  = 'header.tt';
template_config->{POST_PROCESS} = 'footer.tt';
template_config->{INCLUDE_PATH} = '/my/path/to/templates/';

get '/' => sub {
    my ( $params, $apache_request, $this_sub_reference ) = @_;
    my @articles = get_articles ..... ;
    return template( 'index.tt', { articles => \@articles, page => 'news', ... } );
};

get '/thing/:param' => sub  { ... }

post '/post/:param' => sub { ... }

get qr/some.*regexp/ => sub { ... }

=head1 DETAILS

Provides simple methods to simplify web development.   Routes may be specified as "get", "post", "head", or "put" currently.  Raw perl structures returned will be converted into JSON.

=head1 METHODS

=over

base - sets the base url for calls from this point in the code forward

'get', 'post', 'post', 'head', 'any [optional array]' => sub - defines a route

template - call a template to be created

template_config - configure the template

template_variable - Set a variable to be used in a template


=back

=head1 REQUIRED LIBS

=over

=item Apache2::Const;

=item Apache2::Request;

=item Apache2::RequestIO;

=item Apache2::RequestRec;

=item Carp;

=item JSON::XS;

=item Moose::Exporter;

=item Moose;

=item MooseX::FollowPBP;

=item MooseX::Singleton;

=item Template;

=item Tie::Cache;

=item XML::Simple

=back

=head1 REVISION HISTORY

=over

=item 0.1.0 - Initial concept

=item 0.1.1 - Improved construct, first used in production

=item 0.1.2 - Easy of use improved

=item 0.2.0 - Internal structure rewritten

=item 0.3.0 - Update to be compatible with multiple scripts on the same apache session

=item 0.3.5 - First release to CPAN.

=back

=head1 AUTHOR

=over

=item Zack Allison

=item zedoriah@gmail.com

=back

=cut
