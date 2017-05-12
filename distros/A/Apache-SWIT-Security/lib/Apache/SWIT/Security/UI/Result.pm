use strict;
use warnings FATAL => 'all';

package Apache::SWIT::Security::UI::Result::Root;
use base 'HTML::Tested';
__PACKAGE__->ht_add_widget(::HTV."::Marked", 'username');

package Apache::SWIT::Security::UI::Result;
use base qw(Apache::SWIT::HTPage);

sub ht_swit_render {
	my ($class, $r, $root) = @_;
	$root->username($r->pnotes('SWITSession')->get_user->name);
	return $root;
}

sub ht_swit_update {
	my ($class, $r, $root) = @_;
	return "/apache/swit/security/result/r";
}

1;
