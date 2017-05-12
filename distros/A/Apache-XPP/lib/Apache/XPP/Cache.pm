# Apache::XPP::Cache
# --------------------
# $Revision: 1.9 $
# $Date: 2002/01/16 21:06:01 $
#-----------------------------

=head1 NAME

Apache::XPP::Cache - XPP Cache manegment module

=cut

package Apache::XPP::Cache;

=head1 SYNOPSIS

 use Apache::XPP::Cache;
 $cache	= Apache::XPP::Cache->new( %options );
 $cache	= Apache::XPP::Cache->is_cached( %options );

=head1 REQUIRES

Apache::XPP

=cut

use Carp;
use strict;
use vars qw( $debug $debuglines );

BEGIN {
	$Apache::XPP::Cache::REVISION       = (qw$Revision: 1.9 $)[-1];
	$Apache::XPP::Cache::VERSION        = '2.01';
	$debug		= undef;
	$debuglines	= 1;
}

=head1 EXPORTS

Nothing

=head1 DESCRIPTION

Apache::XPP::Cache is an interface to both Store and Expire caching modules.

=head1 METHODS

=over

=cut

=item new( $name, $group, \%instance_data, [ $storetype, @store_options ], [ $expiretype, @expire_options ] )

Creates a new Cache object using the specified Store and Expire types.

=cut
{# BEGIN PRIVATE CODE BLOCK
my %cache;
sub new {
#	Apache::XPP::Cache->new( 're4sidebar', 'games', { r => $r }, [ 'File', $content ], [ 'Duration', '2h' ] );
	my $proto		= shift;
	my $class		= ref($proto) || $proto;
	my $name		= shift;
	my $group		= shift;
	my $instance	= shift;
	my $self;

	my $specifier	= unpack("%32C*", $name . $group) % 65535;
	if ($cache{ $specifier }) {
		warn "cache: using cached object (in new)" . ($debuglines ? '' : "\n") if ($debug);
		$self		= $cache{ $specifier };
	} else {
		warn "cache: creating new object (in new)" . ($debuglines ? '' : "\n") if ($debug);
		my $store		= shift;
		my $expire		= shift;

		$self			= bless( { %{ ref($instance) ? $instance : {} } }, $class );

		foreach my $part ( {Store => $store}, {Expire => $expire} ) {

			my ($label, $inputs) = %{$part};
			my $type	= shift( @{ $inputs } );
			if (my $thisclass = $class->install_module( (($label eq 'Expire') ? 'Expiry' : $label), $type )) {
				my $obj	= $thisclass->new( $name, $group, { r => $self->r }, @{ $inputs } );
				if (ref($obj)) {
					my $meth = $label . 'Type';
					$self->$meth( $type );		# StoreType/ExpireType
					$meth = $label . 'Object';
					$self->$meth( $obj );		# StoreObject/ExpireObject
				} else {
					return undef;
				}
			} else {
				carp "Specified $label type ($type) is not registered as available!";
				return undef;
			}

		}

		$cache{ $specifier }	= $self;
	}
} # END constructor new
} # END private code block for %cache

=item C<install_module> ( ('Store'|'Expiry'), $name )

Installs the $name store or expiry module, and returns the associated class name.

=cut
sub install_module {			# shamelessly snagged from DBI
	my $class	= shift;
	my $type	= shift;
	my $name	= shift;
	
	$type		= 'Expiry' unless ($type eq 'Store');
	my $mod;
	
	# already installed
	return $mod if ($mod = $Apache::XPP::installed{ $type }{ $name });
	
	# --- load the code
	$mod		= "Apache::XPP::Cache::${type}::${name}";
	eval "package Apache::XPP::Cache::_firesafe; require $mod";
	if ($@) {
		warn "require of ($mod) failed! $@";
		return undef;
	}
	
	$Apache::XPP::installed{ $type }{ $name }	= $mod;
}

sub store {
	my $self	= shift;
	return undef unless ref($self);
	return $self->{ 'StoreObject' };
} # END method store

sub expire {
	my $self	= shift;
	return undef unless ref($self);
	return $self->{ 'ExpireObject' };
} # END method expire


=item C<is_expired> (  )

Returns a true value if the current cache has expired, otherwise returns false.

=cut
sub is_expired {
	my $self	= shift;
	return undef unless ref($self);
	if ($self->expire->is_expired( $self->store )) {
		$self->store->is_expired;
		return 1;
	} else {
		return 0;
	}
} # END method is_expired

=item C<content> (  )

Returns the content of the current cache.

=cut
sub content {
	my $self	= shift;
	return ref($self) ? $self->store->content : undef;
} # END method content


=item C<r> (  )

Returns the Apache request object

=cut
*r = \&{ "Apache::XPP::r" };

=item C<AUTOLOAD> ( )

Calling $obj->meth() returns $obj->{'meth'}.
Calling $obj->meth($val) sets $obj->{'meth'} = $val.

=cut

*AUTOLOAD = \&{ "Apache::XPP::AUTOLOAD" };

1;

__END__

=back

=head1 REVISION HISTORY

 $Log: Cache.pm,v $
 Revision 1.9  2002/01/16 21:06:01  kasei
 Updated VERSION variables to 2.01

 Revision 1.8  2000/09/15 22:02:37  dougw
 Took out $AUTOLOAD

 Revision 1.7  2000/09/15 21:35:22  dougw
 Autoload changed to use Apache::XPP's autoload. This didn't make it into
 the previous check in.

 Revision 1.6  2000/09/13 21:02:11  dougw
 David cleaned up the loop in new() so it isn't 2 identical loops. r() and
 AUTOLOAD() are now just forwarders to Apache::XPP::r and Apache::XPP::AUTOLOAD

 Revision 1.5  2000/09/07 19:03:19  dougw
 over fix

 Revision 1.4  2000/09/07 18:40:38  dougw
 Pod updates.


=head1 AUTHORS

Doug Weimer <dougw@cnation.com>
Greg Williams <greg@cnation.com>

=head1 SEE ALSO

 l<perl(1)>.
 l<Apache::XPP>

=cut
