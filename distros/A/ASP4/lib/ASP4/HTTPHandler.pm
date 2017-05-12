
package
ASP4::HTTPHandler;

use strict;
use warnings 'all';
use Data::Properties::YAML;

BEGIN {
  sub VARS {
    qw(
      $Request      $Response
      $Session      $Server
      $Config       $Form
      $Stash
    )
  }
  use vars __PACKAGE__->VARS;
}


sub new {
  my ($class, %args) = @_;
  return bless \%args, $class;
}


sub before_run  { 1; }
sub after_run   { }
sub request     { $Request }
sub response    { $Response }
sub session     { $Session }
sub stash       { $Stash }
sub server      { $Server }
sub form        { $Form }
sub config      { $Config }


sub init_asp_objects
{
  my ($s, $context) = @_;
  
  $Request  = $context->request;
  $Response = $context->response;
  $Session  = $context->session;
  $Server   = $context->server;
  $Form     = $context->request->Form;
  $Config   = $context->config;
  $Stash    = $context->stash;
  
  my $class = ref($s) ? ref($s) : $s;
  my @classes = $s->_parents( $class );
  no strict 'refs';
  my %saw = ( );
  map {
    ${"$_\::Request"}   = $Request;
    ${"$_\::Response"}  = $Response;
    ${"$_\::Session"}   = $Session;
    ${"$_\::Server"}    = $Server;
    ${"$_\::Form"}      = $Form;
    ${"$_\::Config"}    = $Config;
    ${"$_\::Stash"}     = $Stash;
  } grep { ! $saw{$_}++ } @classes;
  
  return 1;
}# end init_asp_objects()


sub properties
{
  my ($s, $file) = @_;
  
  $file ||= $Config->web->application_root . '/etc/properties.yaml';
  return Data::Properties::YAML->new( properties_file => $file );
}# end properties()

sub trim_form
{
  no warnings 'uninitialized';
  
  map {
    $Form->{$_} =~ s/^\s+//;
    $Form->{$_} =~ s/\s+$//;
  } keys %$Form;
}# end trim_form()


sub _parents
{
  my ($s, $class ) = @_;
  
  no strict 'refs';
  
  ${"$class\::__PARENTS_TIME"} ||= 0;
  my $diff = time() - ${"$class\::__PARENTS_TIME"};
  my $max_age = 5;
  if( @{"$class\::__PARENTS"} && $diff < $max_age )
  {
    return @{"$class\::__PARENTS"};
  }# end if()
  
  my @classes = ( $class );
  my $pkg = __PACKAGE__;
  my %saw = ( );
  push @classes, map { $s->_parents( $_ ) }
                   grep { ( ! $saw{$_}++ ) && $_->isa($pkg) }
                     @{"$class\::ISA"};
  
  ${"$class\::__PARENTS_TIME"} = time();
  return @{"$class\::__PARENTS"} = @classes;
}# end _parents()


sub DESTROY
{
  my $s = shift;
  undef(%$s);
}# end DESTROY()

1;# return true:

