
package Apache2::ASP::GlobalASA;

use strict;
use warnings 'all';
BEGIN {
  use vars '@VARS';
  our @VARS = qw(
    $Request  $Response
    $Server   $Application
    $Session  $Form
    $Config   $Stash
  );
  use vars @VARS;
}


#==============================================================================
sub VARS { @VARS }


#==============================================================================
sub init_asp_objects
{
  my ($s, $context) = @_;
  
  no strict 'refs';
  my $selfclass = ref($s) || $s;
  
  # Get each of this classes' superclasses, and theirs as well, recursively:
  my %c = map { $_ => 1 } (
    grep { $_->isa('Apache2::ASP::GlobalASA') } 
    ( $selfclass, @{"$selfclass\::ISA"} )
  );
  map { $c{$_}++ } map {
    @{"$_\::ISA"}
  } keys(%c);
  my @classes = keys(%c);
  
  foreach my $class ( @classes )
  {
    ${"$class\::Request"}     = $context->request;
    ${"$class\::Response"}    = $context->response;
    ${"$class\::Server"}      = $context->server;
    ${"$class\::Session"}     = $context->session;
    ${"$class\::Application"} = $context->application;
    ${"$class\::Config"}      = $context->config;
    ${"$class\::Form"}        = $context->request->Form;
    ${"$class\::Stash"}       = $context->stash;
  }# end foreach()
}# end init_asp_objects()


#==============================================================================
sub Application_OnStart()
{

}# end Application_OnStart()


#==============================================================================
sub Application_OnEnd()
{

}# end Application_OnEnd()


#==============================================================================
sub Server_OnStart()
{

}# end Server_OnStart()


#==============================================================================
sub Server_OnEnd()
{

}# end Server_OnEnd()


#==============================================================================
sub Session_OnStart()
{

}# end Session_OnStart()


#==============================================================================
sub Session_OnEnd()
{

}# end Session_OnEnd()


#==============================================================================
sub Script_OnStart()
{

}# end Script_OnStart()


#==============================================================================
sub Script_OnEnd()
{

}# end Script_OnEnd()


#==============================================================================
sub Script_OnError($);

1;# return true:

=pod

=head1 NAME

Apache2::ASP::GlobalASA - Base GlobalASA class

=head1 SYNOPSIS

In your C<apache2-asp-config.xml>:

  <?xml version="1.0" ?>
  <config>
    ...
    <web>
      ...
      <application_name>MyApp</application_name>
      ...
    </web>
    ...
  </config>

Then, in C<htdocs/GlobalASA.pm>:

  package MyApp::GlobalASA;
  
  use strict;
  use warnings;
  use base 'Apache2::ASP::GlobalASA';
  use vars __PACKAGE__->VARS;
  
  # Called when the apache httpd process first initializes, 
  # before Application_OnStart is called
  sub Server_OnStart
  {
    warn "Server_OnStart()";
  }# end Server_OnStart()
  
  # Called the first time an application is actually fired up:
  sub Application_OnStart
  {
    warn "Application_OnStart()";
  }# end Application_OnStart()
  
  # Called on the first request received from a client:
  sub Session_OnStart
  {
    warn "Session_OnStart()";
  }# end Session_OnStart()
  
  # Called *after* RequestFilters, but before the ASP script (or handler)
  sub Script_OnStart
  {
    warn "Script_OnStart()";
  }# end Session_OnStart()
  
  # Called after the ASP script or handler, but before any PerlCleanupHandlers
  sub Script_OnEnd
  {
    warn "Script_OnEnd()";
  }# end Script_OnEnd()
  
  1;# return true:

=head1 DESCRIPTION

In "Classic ASP" the Global.ASA provided a means of hooking into the 
C<Application_OnStart> and C<Session_OnStart> events.

In C<Apache2::ASP> more events are provided, taking the same idea a little further.

=head1 EVENTS

=head2 Server_OnStart

Called once per Apache httpd process, before C<Application_OnStart>.

=head2 Application_OnStart

Called once in the lifetime of an Application.

=head2 Session_OnStart

Called once at the beginning of a browser session.

This is a good place to initialize any session variables.

=head2 Script_OnStart

Called after any/all L<Apache2::ASP::RequestFilter>s have finished.

This event won't get used much anymore, since we have L<Apache2::ASP::RequestFilter>s now,
but we keep it around just in case you want it for something quick.

=head2 Script_OnEnd

Called after the script has ended, B<before> any C<PerlCleanupHandler>s are called.

B<NOTE>: This event is not raised if an error is thrown while executing the request.

=head1 BUGS

It's possible that some bugs have found their way into this release.

Use RT L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Apache2-ASP> to submit bug reports.

=head1 HOMEPAGE

Please visit the Apache2::ASP homepage at L<http://www.devstack.com/> to see examples
of Apache2::ASP in action.

=head1 AUTHOR

John Drago <jdrago_999@yahoo.com>

=head1 COPYRIGHT

Copyright 2008 John Drago.  All rights reserved.

=head1 LICENSE

This software is Free software and is licensed under the same terms as perl itself.

=cut

