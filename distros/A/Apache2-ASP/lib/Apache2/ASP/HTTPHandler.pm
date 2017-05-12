
package Apache2::ASP::HTTPHandler;

use strict;
use warnings 'all';
BEGIN {
  use vars '@VARS';
  our @VARS = qw(
    $Request  $Response
    $Server   $Application
    $Session  $Form
    $Config   $Stash
    %modes
  );
  sub VARS { @VARS }
}
use vars __PACKAGE__->VARS;


#==============================================================================
sub new
{
  my ($class) = shift;

#warn "$class: new: " . caller;  
  return bless { @_ }, $class;
}# end new()


#==============================================================================
sub before_run { 1; }
sub after_run  { }
sub run;


#==============================================================================
sub init_asp_objects
{
  my ($s, $context) = @_;
  
  no strict 'refs';
  my $selfclass = ref($s) ? ref($s) : $s;
  
  # Get each of this classes' superclasses, and theirs as well, recursively:
  my %c = map { $_ => 1 } (
    grep { $_->isa('Apache2::ASP::HTTPHandler') } 
    ( $selfclass, @{"$selfclass\::ISA"} )
  );
  map { $c{$_}++ } map {
    @{"$_\::ISA"}
  } keys(%c);
  my @classes = keys(%c);
  
  my (
    $request,      $response,
    $server,       $session,
    $application,  $config,
    $form,         $stash
  ) = (
    $context->request,
    $context->response,
    $context->server,
    $context->session,
    $context->application,
    $context->config,
    $context->request->Form,
    $context->stash
  );

  foreach my $class ( @classes )
  {
    ${"$class\::Request"}     = $request;
    ${"$class\::Response"}    = $response;
    ${"$class\::Server"}      = $server;
    ${"$class\::Session"}     = $session;
    ${"$class\::Application"} = $application;
    ${"$class\::Config"}      = $config;
    ${"$class\::Form"}        = $form;
    ${"$class\::Stash"}       = $stash;
  }# end foreach()

  1;
}# end init_asp_objects()


#==============================================================================
sub register_mode
{
  my ($s, %info) = @_;
  
  $modes{ $info{name} } = $info{handler};
}# end register_mode()


#==============================================================================
sub modes
{
  my $s = shift;
  my $key = shift;
  
  @_ ? $modes{$key} = shift : $modes{$key};
}# end modes()

1;# return true:

=pod

=head1 NAME

Apache2::ASP::HTTPHandler - base HTTP handler class

=head1 SYNOPSIS

Internal use only.

=head1 DESCRIPTION

All *Handlers (FormHandlers, ErrorHandlers, UploadHandlers, etc) are subclasses
of this class.

HTTPHandler provides the mechanism for inheriting and initializing the ASP
objects ($Request, $Response, $Session, $Server, etc) in itself and all of its
subclasses, recursively.

=head1 PUBLIC METHODS

=head2 VARS

This shoud be called by every *Handler and MediaManager subclass.

Returns a list of strings like this:

  qw(
    $Response   $Application
    $Request    $Stash
    $Config     $Form
    $Server     $Session
  );

=head1 BUGS

It's possible that some bugs have found their way into this release.

Use RT L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Apache2-ASP> to submit bug reports.

=head1 HOMEPAGE

Please visit the Apache2::ASP homepage at L<http://www.devstack.com/> to see examples
of Apache2::ASP in action.

=head1 AUTHOR

John Drago L<mailto:jdrago_999@yahoo.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 John Drago, All rights reserved.

This software is free software.  It may be used and distributed under the
same terms as Perl itself.

=cut
