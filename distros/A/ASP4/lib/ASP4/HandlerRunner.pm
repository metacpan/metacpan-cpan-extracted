
package
ASP4::HandlerRunner;

use strict;
use warnings 'all';


sub new
{
  my ($class, %args) = @_;
  
  return bless \%args, $class;
}# end new()


sub context { ASP4::HTTPContext->current }


sub run_handler
{
  my ($s, $handler_class, $args) = @_;
  
  my $handler = $handler_class->new();
  $handler_class->init_asp_objects( $s->context );
  $handler_class->before_run( $s->context, $args );
  if( ! $s->{did_end} )
  {
    my $res = $handler_class->run( $s->context, $args );
    $handler_class->after_run( $s->context, $args );
    return $res;
  }# end if()
}# end run_handler()

1;# return true:

