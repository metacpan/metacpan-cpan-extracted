# this is the applcation class

# this example is an example for a CGI prototype. stylesheetnames and
# all events are allready defined, but not fully implemented. This is
# done to demonstrate, the internal error handling, if the requested
# data cannot be found.

# the class only defines only the default event function. this is ok,
# if no functionality on startup or exit is required.

package example1;

use vars qw( @ISA @HANLDER );
use CGI::XMLApplication;

@ISA     = qw(CGI::XMLApplication);

# we define two handler here but below there is only a single explicit
# handler implemented. if you call the coma event the script will tell
# the event is not yet defined.
#
# if you have several application layer, that all define some events,
# you should write the function like this:
# sub registerEvents { ( $_[0]->SUPER::registerEvents(), @eventlist ); }
# to ashure, no events get lost during initialization.
sub registerEvents    { qw(submit coma); } # the handler list

# a rather simple example :)
# this function is called by the serialization function. As shown this
# function should return the full path and filename. otherwise the
# script will check, if the stylesheets are in the local directory.
sub selectStylesheet  {
  my ( $self , $ctxt ) = @_;
  my $path_to_style = 'your/path/';
  return $path_to_style . qw( bsp1.xsl bsp2.xsl )[$ctxt{-stylesheetid}];
}

# notice, that we do not implement getDOM!
# this will cause CGI::XMLApplication to create an empty document
# so the transformation will be done anyway

# implicit handler
# no init and exit needed here :)

# This event is called, if no other event can be found in the
# parameter list.
sub event_default {
  my $self = shift;
  my $ctxt = shift;
  warn "test->default\n";
  $ctxt->{-stylesheetid} = 1;
  return 0;
}

# explicit handler
# this handler is called if the param list contains 'submit=abc' or
# 'submit.x=123'. The script does not check the value of the event, at the
# current state. commonly this is not neccesary anyway since designers
# decide to change values all the time :)
sub event_submit {
  my $self = shift;
  warn "test->submit\n";
  $ctxt->{-stylesheetid} = 2;
  return 0;
}

1;
