# Apache::XPP::Cache::Expiry::Duration
# ----------------------------------------
# $Revision: 1.6 $
# $Date: 2002/01/16 21:06:01 $
#------------------------------------------------------------------

=head1 NAME

Apache::XPP::Cache::Expiry::Duration - Duration based cache expiry.

=cut

package Apache::XPP::Cache::Expiry::Duration;

=head1 SYNOPSIS

...

=head1 REQUIRES

Apache::XPP::Cache::Expiry

=cut

use Carp;
use strict;
use Apache::XPP::Cache::Expiry;
use vars qw( @ISA $debug $debuglines );

BEGIN {
	@ISA		= qw( Apache::XPP::Cache::Expiry );
	$Apache::XPP::Cache::Expiry::Duration::REVISION = (qw$Revision: 1.6 $)[-1];
	$Apache::XPP::Cache::Expiry::Duration::VERSION = '2.01';
	$debug		= undef;
	$debuglines	= 1;
}

=head1 EXPORTS

Nothing

=head1 DESCRIPTION

Apache::XPP::Cache::Expiry::Duration handles the expiring of caches based on a duration
of time on behalf of Apache::XPP::Cache.

=head1 METHODS

=over

=item C<new> ( $name, $group, \%instance_data, $duration )

Creates a new Duration expiry object. The contents of %instance_data will be placed in
the object as instance data (for Apache request object, etc.).

=cut
{ # BEGIN PRIVATE CODEBLOCK
my %multiplier	= (
	'y'	=> [365, 'd'],
	'M'	=> [28, 'd'],
	'w'	=> [7, 'd'],
	'd'	=> [24, 'h'],
	'h'	=> [60, 'm'],
	'm'	=> [60, 's'],
	's'	=> [1, 's']
);
sub new {
	my $proto		= shift;
	my $class		= ref($proto) || $proto;
	my $name		= shift;
	my $group		= shift;
	my $instance	= shift;
	
	my $self		= bless( { %{ ref($instance) ? $instance : {} } }, $class );
	
	$self->name( $name );
	$self->group( $group );
	
	if (my $duration = shift) {
		if ($duration =~ /^(\d+)$/) {
			$self->duration( $duration );
		} else {
			return undef unless ($duration =~ /^([\d.]+)([yMwdhms])$/);
			my ($multiple, $specifier)	= ($1, $2);
			while ($specifier ne 's') {
				my $tmp		= $multiplier{ $specifier };
				$multiple	*= $tmp->[0];
				$specifier	= $tmp->[1];
			}
			
			$self->duration( $multiple );
		}
	}
	
	return $self;
} # END constructor new
} # END PRIVATE CODEBLOCK

=item C<is_expired> ( $store_object )

Returns TRUE if the cache (whose store is passed as an argument) has expired,
FALSE otherwise.

=cut
sub is_expired {
	my $self		= shift;
	my $class		= ref($self) || return undef;
	my $store		= shift;
	
	my $mtime		= $store->mtime;
	my $duration	= $self->duration;
	
	return (time > ($mtime + $duration)) ? 1 : 0;
} # END method is_expired



1;

__END__

=back

=head1 REVISION HISTORY

 $Log: Duration.pm,v $
 Revision 1.6  2002/01/16 21:06:01  kasei
 Updated VERSION variables to 2.01

 Revision 1.5  2000/09/11 20:12:23  david
 Various minor code efficiency improvements.

 Revision 1.4  2000/09/07 19:02:56  dougw
 over fix

 Revision 1.3  2000/09/07 18:53:13  dougw
 Added VERSION/REVISION, pod changes.


=head1 AUTHORS

Greg Williams <greg@cnation.com>

=head1 SEE ALSO

perl(1).

=cut
