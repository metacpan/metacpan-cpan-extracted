package Class::Listener;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.01.04';

our $DEBUG = 0;

our $callback_fmt = "_on_%s";

    sub signal : method
    {
        my $this = shift;

        my $event = shift;

		my $method = sprintf $callback_fmt, $event;
		
            return $this->$method( $event, @_ ) if $this->can( $method );

            warn "D: $method - unimplemented event called\n" if $DEBUG;

    return undef;
    }

1;
__END__

=head1 NAME

Class::Listener - executes methods on events

=head1 SYNOPSIS

  use Class::Listener;

  {
    package My::Listener;

    our @ISA = qw(Class::Listener);
	
	sub new 
	{
		bless [], 'My::Listener';
	}
	
	sub _on_event
	{
		print "event received";
	}	
  }

  my $l = My::Listener->new();

	# call '_on_event' method
	
  $l->Class::Listener::signal( 'event', @args );

=head1 DESCRIPTION

A base class which listenes for signals and runs methods.

=head2 METHODS

=head3 signal( $eventname, @args )

=over 4

=item $eventname

A method with the name "_on_$eventname" will be called (if it exists).

=item @args

This array is forwarded to the callback.

=back

[Note] signal returns the resulting return value of the callback.

=head2 EXPORT

None by default.

=head1 AUTHOR

Murat Uenalan, E<lt>muenalan@cpan.orgE<gt>

=head1 SEE ALSO

L<Class::Proxy>.

=cut
