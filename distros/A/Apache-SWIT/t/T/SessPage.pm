use strict;
use warnings FATAL => 'all';

package T::SessPage;
use base 'Apache::SWIT::HTPage';
use HTML::Tested qw(HTV);

sub swit_startup {
	shift()->ht_make_root_class->ht_add_widget(HTV."::EditBox", 'persbox');
}

sub swit_process_template {
	my ($class, $r, $file, $vars) = @_;
	$vars->{moo} = 'moo is foo';
	return shift()->SUPER::swit_process_template(@_);
}

sub ht_swit_render {
	my ($class, $r, $root) = @_;
	$root->persbox($r->pnotes('SWITSession')->get_persbox);
	return $root;
}

sub ht_swit_update {
	my ($class, $r, $root) = @_;
	$r->pnotes('SWITSession')->set_persbox($root->persbox);
	return '/test/sess_page/r';
}

1;
