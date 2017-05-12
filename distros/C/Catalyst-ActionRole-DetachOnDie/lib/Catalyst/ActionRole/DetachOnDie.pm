package Catalyst::ActionRole::DetachOnDie;
{
  $Catalyst::ActionRole::DetachOnDie::VERSION = '0.001006';
}
use Moose::Role;
use Try::Tiny;
use Scalar::Util qw(blessed);

# ABSTRACT: If something dies in a chain, stop the chain. DEPRECATED IN FAVOR OF CATALYST 5.90040

around execute => sub {
   my ($orig, $self, $controller, $c, @args) = @_;

   try {
      $self->$orig($controller, $c, @args)
   } catch {
      if(blessed($_) && ($_->isa('Catalyst::Exception::Detach') || $_->isa('Catalyst::Exception::Go'))){
        die $_; # re-throw explicit detach
      }
      $c->log->error("Caught exception: $_ detaching");
      $c->error([ @{ $c->error }, $_ ]);
      $c->detach;
      undef
   }
};

no Moose::Role;

1;

__END__

=pod

=head1 NAME

Catalyst::ActionRole::DetachOnDie - If something dies in a chain, stop the chain. DEPRECATED IN FAVOR OF CATALYST 5.90040

=head1 VERSION

version 0.001006

=head1 SYNOPSIS

 package MyApp::Controller::Foo;
 use Moose;

 BEGIN { extends 'Catalyst::Controller::ActionRole' }

 __PACKAGE__->config(
    action => {
       '*' => { Does => 'DetachOnDie' },
    },
 );

 ...;

=head1 DESCRIPTION

Chained dispatch is arguably one of the coolest features Catalyst has to offer,
unfortunately it is marred by the bizarre decision to have exceptions thrown
B<not> detach a chain.  To be clear, if one has a chain as follows:

 sub first  : Chained('/') PathPart('') CaptureArgs(0) { ... }
 sub middle : Chained('first') PathPart('middle') CaptureArgs(0) { ... }
 sub last   : Chained('middle') PathPart('') Args(0) { ... }

If the URL /middle is dispatched to, but an exception is raised in the
C<middle> (or even C<first>) method, the C<last> method will B<still> run!
This module solves that problem.  I recommend you use it as I have documented
in the L</SYNOPSIS>, as that will make it apply to all of your actions, but if
for some reason you do not want to apply it to all actions you can apply it per
action as follows:

 sub foo : Chained('bar') PathPart('') CaptureArgs(0) Does('DetachOnDie') { ... }

If you do not want to use the action role, check out
L<Catalyst::Action::DetachOnDie>, which does the same thing but does not
require the use of L<Catalyst::Controller::ActionRole>.

=head1 DEPRECATED

Instead of using this module you should use Catalyst 5.90040 and set
the C<abort_chain_on_error_fix> flag.

=head1 AUTHOR

Arthur Axel "fREW" Schmidt <frioux+cpan@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Arthur Axel "fREW" Schmidt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
