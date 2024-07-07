use 5.008001; use strict; use warnings;

package # hide from PAUSE for now
	Catalyst::Plugin::Flash::JSON;

our $VERSION = '0.002';

use JSON::MaybeXS;
my $jx = JSON::MaybeXS->new->ascii;

sub flash_to_cookie { shift; $jx->encode( \@_ ) }

sub flash_from_cookie {
	local $@;
	my $data = $_[1];
	$data && $data =~ /^\[/ && eval { $data = $jx->decode( $data ) } ? @$data : ();
}

# use Catalyst 5.80004 ();
use Moose::Role;
with 'Catalyst::Plugin::Flash';
no Moose::Role;

1;
