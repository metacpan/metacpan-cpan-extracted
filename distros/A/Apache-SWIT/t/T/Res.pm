use strict;
use warnings FATAL => 'all';

package T::Res;
use base 'Apache::SWIT';
use File::Basename qw(dirname);

sub swit_render {
	my ($class, $r) = @_;
	my $f = dirname($INC{'T/Res.pm'}) . "/../templates/res.tt";
	$r->pnotes('SWITTemplate', $f);
	return { res => $r->param('res') };
}

1;
