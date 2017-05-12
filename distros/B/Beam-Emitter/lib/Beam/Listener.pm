package Beam::Listener;
our $VERSION = '1.007';

#pod =head1 SYNOPSIS
#pod
#pod   package MyListener;
#pod
#pod   extends 'Beam::Listener';
#pod
#pod
#pod   # add metadata with subscription time
#pod   has sub_time => is ( 'ro',
#pod                         init_arg => undef,
#pod                         default => sub { time() },
#pod   );
#pod
#pod    # My::Emitter consumes the Beam::Emitter role
#pod    my $emitter = My::Emitter->new;
#pod    $emitter->on( "foo", sub {
#pod         my ( $event ) = @_;
#pod         print "Foo happened!\n";
#pod         # stop this event from continuing
#pod         $event->stop;
#pod     },
#pod     class => MyListener
#pod     );
#pod
#pod
#pod =head1 DESCRIPTION
#pod
#pod This is the base class used by C<Beam::Emitter> objects to store information
#pod about listeners. Create a subclass to add data attributes.
#pod
#pod =head1 SEE ALSO
#pod
#pod =over 4
#pod
#pod =item L<Beam::Emitter>
#pod
#pod =back
#pod
#pod =cut

use strict;
use warnings;

use Types::Standard qw(:all);
use Moo;

#pod =attr code
#pod
#pod A coderef which will be invoked when the event is distributed.
#pod
#pod =cut

has callback => (
    is  => 'ro',
    isa => CodeRef,
    required => 1,
);

1;

__END__

=pod

=head1 NAME

Beam::Listener

=head1 VERSION

version 1.007

=head1 SYNOPSIS

  package MyListener;

  extends 'Beam::Listener';


  # add metadata with subscription time
  has sub_time => is ( 'ro',
                        init_arg => undef,
                        default => sub { time() },
  );

   # My::Emitter consumes the Beam::Emitter role
   my $emitter = My::Emitter->new;
   $emitter->on( "foo", sub {
        my ( $event ) = @_;
        print "Foo happened!\n";
        # stop this event from continuing
        $event->stop;
    },
    class => MyListener
    );

=head1 DESCRIPTION

This is the base class used by C<Beam::Emitter> objects to store information
about listeners. Create a subclass to add data attributes.

=head1 ATTRIBUTES

=head2 code

A coderef which will be invoked when the event is distributed.

=head1 SEE ALSO

=over 4

=item L<Beam::Emitter>

=back

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
