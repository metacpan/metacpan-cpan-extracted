
package Apache2::ASP::HTTPContext::SubContext;

use strict;
use warnings 'all';
use base 'Apache2::ASP::HTTPContext';


#==============================================================================
sub new
{
  my ($class, %args) = @_;
  
  die "Required param 'parent' was not provided"
    unless $args{parent};
  die "Param 'parent' isn't a Apache2::ASP::HTTPContext"
    unless $args{parent}->isa( 'Apache2::ASP::HTTPContext' );
  
  $class = ref($class) || $class;
  my $s = bless \%args, $class;
  
  $Apache2::ASP::HTTPContext::instance = $s;
  return $s;
}# end new()


#==============================================================================
sub setup_request
{
  my ($s, $requestrec, $cgi) = @_;

  $s->{r} = $requestrec;
  $s->{cgi} = $cgi;
  
  $s->{connection}  = $s->r->connection;
  
  my $resolver = $s->config->web->handler_resolver;
  $s->_load_class( $resolver );
  $s->{handler} = $resolver->new()->resolve_request_handler( $s->r->uri );
  
  return 1;
}# end setup_request()


#==============================================================================
sub execute
{
  my ($s, $args) = @_;
#  local $SIG{__DIE__} = \&Carp::confess;
  
  $s->_load_class( $s->config->web->handler_runner );
  eval {
    $s->_load_class( $s->handler );
    $s->config->web->handler_runner->new()->run_handler( $s->handler, $args );
  };
  if( $@ )
  {
    $s->server->{LastError} = $@;
    return $s->handle_error;
  }# end if()
  
  $s->response->Flush;
  my $res = $s->{parent} ? $s->response->Status : $s->end_request();
  if( $s->page && $s->page->directives->{OutputCache} && defined($s->{_cache_buffer}) )
  {
    if( $res == 200 || $res == 0 )
    {
      $s->page->_write_cache( \$s->{_cache_buffer} );
    }# end if()
  }# end if()
  
  $res = 0 if $res =~ m/^200/;
  return $res;
}# end execute()


#==============================================================================
sub get_prop
{
  my ($s, $prop) = @_;
  
  $s->{parent}->get_prop($prop);
}# end get_prop()


#==============================================================================
sub set_prop
{
  my ($s) = shift;
  my $prop = shift;
  
  $s->{parent}->set_prop($prop, @_);
}# end set_prop()

sub config       { shift->get_prop('config')      }
sub session      { shift->get_prop('session')     }
sub server       { shift->get_prop('server')      }
sub request      { shift->get_prop('request')     }
sub response     { shift->get_prop('response')    }
sub application  { shift->get_prop('application') }
sub stash        { shift->get_prop('stash')       }
sub global_asa   { shift->get_prop('global_asa')  }
sub _is_setup    { shift->get_prop('_is_setup')   }


#==============================================================================
sub rflush
{
  my $s = shift;
  
  $s->{r}->rflush();
}# end rflush()


#==============================================================================
sub DESTROY
{
  my $s = shift;
  
  if( my $parent = $s->{parent} )
  {
    $Apache2::ASP::HTTPContext::instance = $parent;
  }# end if()
  
  undef(%$s);
}# end DESTROY()

1;# return true:

