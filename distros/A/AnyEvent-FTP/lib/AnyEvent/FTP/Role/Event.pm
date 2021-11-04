package AnyEvent::FTP::Role::Event;

use strict;
use warnings;
use 5.010;
use Moo::Role;

# ABSTRACT: Event interface for AnyEvent::FTP objects
our $VERSION = '0.18'; # VERSION


sub define_events
{
  my $class = shift;

  foreach my $name (@_)
  {
    my $method_name = join '::', $class, "on_$name";
    my $method = sub {
      my($self, $cb) = @_;
      push @{ $self->{event}->{$name} }, $cb;
      $self;
    };
    no strict 'refs';
    *$method_name = $method;
  }
}


sub emit
{
  my($self, $name, @args) = @_;
  for(@{ $self->{event}->{$name} })
  {
    eval { $_->(@args) };
    warn $@ if $@;
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

AnyEvent::FTP::Role::Event - Event interface for AnyEvent::FTP objects

=head1 VERSION

version 0.18

=head1 SYNOPSIS

 package AnyEvent::FTP::Foo;
 
 use Moo;
 with 'AnyEvent::FTP::Role::Event';
 __PACKAGE__->define_events(qw( error good ));
 
 sub some_method
 {
   my($self) = @_;
 
   if($self->other_method)
   {
     $self->emit(good => 'paylod message');
   }
   else
   {
     $self->emit(error => 'something went wrong!');
   }
 }

later on somewhere else

 use AnyEvent::FTP::Foo;
 
 my $foo = AnyEvent::FTP::Foo->new;
 $foo->on_good(sub {
   my($message) = @_;
   print "worked: $message";
 });
 $foo->on_error(sub {
   my($message) = @_;
   print "failed: $message";
 });
 
 $foo->some_method

=head1 DESCRIPTION

This role provides a uniform even callback mechanism for classes in L<AnyEvent::FTP>.
You declare events by using the C<define_events> method.  Once declared
you can use C<on_>I<event_name> to add a callback to a particular event
and C<emit> to trigger those callbacks.

=head1 METHODS

=head2 define_events

 __PACKAGE__->define_events( @list_of_event_names );

This is called within the class package to declare the event names for all
events used by the class.  It creates methods of the form C<on_>I<event_name>
which can be used to add callbacks to events.

=head2 emit

 $obj->emit($event_name, @arguments);

This calls the callbacks associated with the given C<$event_name>.
It will pass to that callback the given C<@arguments>.

=head1 SEE ALSO

=over 4

=item *

L<AnyEvent::FTP>

=back

=head1 AUTHOR

Author: Graham Ollis E<lt>plicease@cpan.orgE<gt>

Contributors:

Ryo Okamoto

Shlomi Fish

José Joaquín Atria

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017-2021 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
