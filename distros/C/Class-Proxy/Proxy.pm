require 5.005_62; use strict; use warnings;

our $VERSION = '0.01.02';

use Carp;

use Class::Maker;

use Class::Listener;

package Class::Proxy;

Class::Maker::class
{
	isa => [qw( Class::Listener )],
	
	private =>
	{
		ref => { victim => 'UNIVERSAL' },
	},
};

use vars qw($AUTOLOAD);

sub _preinit
{
	my $this = shift;

		$this->_victim( undef );
}

sub _postinit
{
	my $this = shift;

		$this->victim( $this->_victim ) if $this->_victim;
}

sub victim : method
{
	my $this = shift;

	my $destination = shift;

			# Binding to class or object...

		$this->_victim( ref($destination) ? $destination : $destination->new( @_ ) );

		$this->signal( 'victim', $this->_victim );

return $this->_victim;
}

	# Future: Class::Proxy should more obscure himself
	#
	#	"goto &func" would be the best solution.
	#
	#	#my $fullfunc = \&{ "${destpack}::$func" };
	#	#goto &$fullfunc if $victim->can( $func ) or die "unhandled method $victim->$func via Obsessor";

sub AUTOLOAD : method
{
	my $this = shift || return undef;

	my @args = @_;

		( my $func = $AUTOLOAD ) =~ s/.*:://;

		return if $func eq 'DESTROY';

		#no strict 'refs';

		@_ = @args;

		$this->Class::Listener::signal( 'method', \$func, \$this->_victim, \@args );

		die "unimplemented '$func' called on ".ref( $this->_victim ) unless $this->_victim->can( $func );

return wantarray ? @{ [ $this->_victim->$func( @_ ) ] } : $this->_victim->$func( @_ );
}

1;

__END__

=head1 NAME

Class::Proxy - an object proxy

=head1 SYNOPSIS

   use Class::Proxy;

	my $pobj = Class::Proxy->new( victim => $obj );

	$pobj->victim_method();

=head1 DESCRIPTION

Objects can be served by C<Class::Proxy>. In practice, any method call to the proxy will
be forwarded to the original object (victim). The purpose of that is to alter method
calls in a generic way. This can be used for

=over 4

=item *

faking

=item *

restriction

=item *

logging

=item *

benchmarking

=item *

forwarding

=item *

versioning

=item *

caching

=back

and many more.

=head2 Altering calls

Class::Proxy is a C<Class::Listener> (L<Class::Listener>). Two signals are registered to it:

=over 4

=item method

When a method is called.

=item victim

When a victim was assigned.

=back

=head1 HIDING

The C<Class::Proxy> constructor returns a C<Class::Proxy> object and not a victim object. That means it isn't
very good hiding itsef and this may cause conflicts. But when the victim class was written following oo-recommendations
C<Class::Proxy> should work fine.

[Note] In future C<Class::Proxy> will try to obscure himself (via tie?). Currently ref() or isa() call would
reveal C<Class::Proxy>. Also caller() would give hints.

=head2 EXPORT

None by default.

=head1 AUTHOR

Murat Ünalan, murat.uenalan@gmx.dee

=head1 SEE ALSO

L<Class::Listener>, L<Class::NiceApi> and L<Class::Protected>

=cut

