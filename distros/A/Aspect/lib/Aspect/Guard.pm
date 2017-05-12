package Aspect::Guard;

=pod

=head1 NAME

Aspect::Guard - General purpose guard object for destroy-time actions

=head1 SYNOPSIS

  SCOPE: {
  
      my $guard = Aspect::Guard->new( sub {
          print "Goodbye World!\n";
      } );
  
  }
  # Prints here as it exits the scope

=head1 DESCRIPTION

The B<Aspect::Guard> class shipping with L<Aspect> is a convenience module for
creating C<CODE> based objects that execute when they fall out of scope.

It's usage is effectively summarised by the synopsis.

=head1 METHODS

=cut 

use strict;

our $VERSION = '1.04';

=pod

=head2 new

  my $guard = Aspect::Guard->new( sub { do_something(); } );

The C<new> method creates a new guard object. It takes a single C<CODE>
references as a parameter, which it will bless into the guard class, which will
execute the code reference when it's C<DESTROY> hook is called.

=cut

sub new {
	bless $_[1], $_[0];
}

sub DESTROY {
	$_[0]->();
}

1;

=pod

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2011 - 2013 Adam Kennedy.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
