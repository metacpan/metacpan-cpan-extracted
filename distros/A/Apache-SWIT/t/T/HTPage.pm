use strict;
use warnings FATAL => 'all';

package T::HTPage::Root;
use base 'HTML::Tested';

package T::HTPage;
use base 'Apache::SWIT::HTPage';
use File::Slurp;
use HTML::Tested qw(HTV);

sub ht_swit_render {
	my ($class, $r, $root) = @_;
	return '/test/www/hello.html' if $r->param('redir');
	return [ INTERNAL => '../www/hello.html' ] if $r->param('internal');
	$root->hello('world');
	$root->req_uri($r->uri);
	$root->hid($root->hid || 'secret');
	$root->hostport($ENV{APACHE_SWIT_SERVER_URL});
	return $root;
}

sub ht_swit_update {
	my ($class, $r, $root) = @_;
	my $f = $root->file or die "No file is given";
	my $up = $r->upload('up');
	my $res = $up ? $up->filename : "0";
	write_file($f, "$res\n" . read_file($root->up));
	return '/test/basic_handler';
}

sub swit_startup {
	my $hclass = shift()->ht_root_class;
	$hclass->ht_add_widget(HTV, 'hello');
	$hclass->ht_add_widget(HTV, 'req_uri');
	$hclass->ht_add_widget(HTV, 'v1');
	$hclass->ht_add_widget(HTV."::Upload", 'up');
	$hclass->ht_add_widget(HTV."::Upload", 'inv_up');
	$hclass->ht_add_widget(HTV."::EditBox", 'file');
	$hclass->ht_add_widget(HTV."::Marked", 'hostport');
	$hclass->ht_add_widget(HTV."::Hidden", 'hid', is_sealed => 1);
}

1;
