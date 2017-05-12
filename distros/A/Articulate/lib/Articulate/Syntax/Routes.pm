package Articulate::Syntax::Routes;
use strict;
use warnings;

# use Dancer qw(:syntax);
use Exporter::Declare;
use Articulate::Service;
default_exports qw(
  any get post patch del put options
);

#  request upload uploads captures param params splat
#  config var session template
#  redirect forward halt pass send_error status
# ); # the first line will stay, everything else will find its way into framework

no warnings 'redefine';

sub on_enable {
  my $code   = shift;
  my ($pkg)  = caller(2);
  my $routes = "${pkg}::__routes";
  {
    no strict 'refs';
    $$routes //= [];
    push @$$routes, $code;
  }
}

sub _declare_route {
  my ( $http_verb, $path, $code ) = @_;
  on_enable(
    sub {
      my $self = shift;
      my $wrapped = sub { $self->serialisation->serialise( $code->(@_) ) };
      $self->framework->declare_route(
        $http_verb => $path => sub {
          perform_request( $wrapped, [ $self, $self->framework->request ] );
        }
      );
    }
  );
}

sub any     { _declare_route( any     => @_ ); }
sub get     { _declare_route( get     => @_ ); }
sub post    { _declare_route( post    => @_ ); }
sub patch   { _declare_route( patch   => @_ ); }
sub del     { _declare_route( del     => @_ ); }
sub put     { _declare_route( put     => @_ ); }
sub options { _declare_route( options => @_ ); }

sub perform_request {
  $_[0]->( @{ $_[1] } );
}

1;
