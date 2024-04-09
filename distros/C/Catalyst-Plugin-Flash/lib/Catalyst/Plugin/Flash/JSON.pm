use 5.008001; use strict; use warnings;

package # hide from PAUSE for now
	Catalyst::Plugin::Flash::JSON;

our $VERSION = '0.001';

use JSON::MaybeXS;
my $jx = JSON::MaybeXS->new->ascii;

sub flash_to_cookie   { shift; $jx->encode( \@_ ) }
sub flash_from_cookie { local $@; map ref eq 'ARRAY' ? @$_ : (), eval { $jx->decode( $_[1] ) } }

# use Catalyst 5.80004 ();
use Moose::Role;
with 'Catalyst::Plugin::Flash';
no Moose::Role;

1;
