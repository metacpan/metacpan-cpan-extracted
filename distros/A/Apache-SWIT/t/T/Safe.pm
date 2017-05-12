use strict;
use warnings FATAL => 'all';

package T::Safe::DB;
use base 'Apache::SWIT::DB::Base';
__PACKAGE__->set_up_table('safet');

package T::Safe::Root::L;
use base 'HTML::Tested';
__PACKAGE__->ht_add_widget(::HTV."::EditBox", 'o', is_integer => 1);

package T::Safe::Root;
use base 'HTML::Tested::ClassDBI';
__PACKAGE__->ht_add_widget(::HTV."::Hidden", 's_id' => cdbi_bind => 'Primary');
__PACKAGE__->ht_add_widget(::HTV."::EditBox", klak => cdbi_bind => 'k3');
__PACKAGE__->ht_add_widget(::HTV, 'referer');
__PACKAGE__->ht_add_widget(::HTV, scol => safe_bind => 'k3');
__PACKAGE__->ht_add_widget(::HTV, flak => cdbi_bind => 'k3'
	, cdbi_readonly => 1);
__PACKAGE__->ht_add_widget(::HTV."::EditBox", $_ => cdbi_bind => '')
	for qw(name k1 k2);
__PACKAGE__->ht_add_widget(::HTV."::EditBox", 'email' => cdbi_bind => ''
		, constraints => [ [ regexp => '^[^ ]*$' ] ]);
__PACKAGE__->bind_to_class_dbi('T::Safe::DB');
__PACKAGE__->ht_add_widget(::HT."::List", sl => __PACKAGE__ . "::L");

package T::Safe;
use base 'Apache::SWIT::HTPage::Safe';
use Carp;

sub ht_swit_render {
	my ($class, $r, $root) = @_;
	$root->cdbi_load if $root->s_id;
	$root->referer($r->headers_in->{Referer});
	$root->name('boob') if $r->param('boob');
	$root->sl([ map { $root->sl_containee->new({ o => $_ }) } (1 .. 2) ]);
	return $root;
}

sub die2 {
	confess "BUGBUGBUG";
}

sub die1 {
	shift()->die2;
}

sub ht_swit_update {
	my ($class, $r, $root) = @_;
	die "CUSTOM" if ($root->name && $root->name eq 'custodie');
	$class->die1 if ($root->name && $root->name eq 'die');
	if ($root->name eq 'another_t') {
		my $dbh = Apache::SWIT::DB::Connection->instance->db_handle;
		$dbh->do("insert into another_t (name) values ('fff')");
		$dbh->do("insert into another_t (name) values ('fff')");
	}
	$root->cdbi_create;
	return $root->ht_make_query_string("r", "s_id");
}

sub ht_swit_update_die {
	my ($class, $msg, $r, $root) = @_;
	return $msg =~ /CUSTOM/ ?
		$class->swit_encode_errors([ [ "name", 'custom' ] ])
	                        : shift()->SUPER::ht_swit_update_die(@_);
}

1;

