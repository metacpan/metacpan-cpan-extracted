use strict;
use warnings FATAL => 'all';

package Apache::SWIT::Maker::Skeleton::Scaffold::DualTest;
use base 'Apache::SWIT::Maker::Skeleton::Scaffold';
use Apache::SWIT::Maker::Conversions;
use File::Slurp;

sub empty_cols_v {
	my $cols = shift->columns;
	my $val = shift || '';
	return join(",\n\t", map { "$_ => '$val'" } @$cols);
}

sub cols_99_v { return shift()->empty_cols_v('99'); }

sub cols_99_list_v {
	my @cols = @{ shift->columns };
	shift @cols;
	return @cols ? join(",\n\t", map { "$_ => '99'" } @cols) . "," : '';
}

sub cols_333_v {
	my $c99 = shift()->cols_99_v;
	$c99 =~ s/99/333/g;
	return $c99;
}

sub cols_333_list_v {
	my $c99 = shift()->cols_99_list_v;
	$c99 =~ s/99/333/g;
	return $c99;
}

sub form_test_v { return lc(shift()->table_class_v) . "_form"; }
sub list_test_v { return lc(shift()->table_class_v) . "_list"; }
sub info_test_v { return lc(shift()->table_class_v) . "_info"; }

sub output_file {
	my $mf = read_file('MANIFEST');
	my $dt = conv_next_dual_test($mf);
	return "t/dual/$dt\_" . shift()->table . ".t";
}

sub template_prefix { return <<'ENDS'; }
use strict;
use warnings FATAL => 'all';

use Test::More tests => 19;

BEGIN { use_ok('T::Test'); };
ENDS

sub template { return shift()->template_prefix . <<'ENDS'; }

my $t = T::Test->new;
$t->reset_db;
$t->ok_ht_[% list_test_v %]_r(make_url => 1, ht => { [% list_name_v %] => [] });

$t->ok_follow_link(text => 'Add [% table_class_v %]');

$t->ok_ht_[% form_test_v %]_r(ht => {
	[% empty_cols_v %]
});
$t->ht_[% form_test_v %]_u(ht => {
	[% cols_99_v %]
});
$t->ok_ht_[% info_test_v %]_r(param => { HT_SEALED_[% table_v %]_id => 1 }
		, ht => {
	[% cols_99_v %], HT_SEALED_[% table_v %]_id => 1,
});

$t->ok_follow_link(text => 'Edit [% table_class_v %]');
$t->ok_follow_link(text => 'List [% table_class_v %]');

$t->ok_ht_[% list_test_v %]_r(ht => { [% list_name_v %] => [ {
	[% cols_99_list_v %] HT_SEALED_[% col1_v %] => [ '99', 1 ],
} ] });
$t->ok_follow_link(text => '99');
$t->ok_ht_[% info_test_v %]_r(param => { HT_SEALED_[% table_v %]_id => 1 }
		, ht => {
	[% cols_99_v %], HT_SEALED_[% table_v %]_id => 1,
});

$t->ok_follow_link(text => 'Edit [% table_class_v %]');
$t->ok_ht_[% form_test_v %]_r(param => { HT_SEALED_[% table_v %]_id => 1 }
		, ht => {
	[% cols_99_v %]
});

$t->ht_[% form_test_v %]_u(ht => {
	[% cols_333_v %], HT_SEALED_[% table_v %]_id => 1,
});
$t->ok_follow_link(text => 'List [% table_class_v %]');
$t->ok_ht_[% list_test_v %]_r(ht => { [% list_name_v %] => [ {
	[% cols_333_list_v %] HT_SEALED_[% col1_v %] => [ '333', 1 ],
} ] });

$t->ok_follow_link(text => '333');
$t->ok_follow_link(text => 'Edit [% table_class_v %]');
$t->ok_ht_[% form_test_v %]_r(param => { HT_SEALED_[% table_v %]_id => 1 }
		, ht => {
	[% cols_333_v %], HT_SEALED_[% table_v %]_id => 1
		, delete_button => 'Delete',
});
$t->ht_[% form_test_v %]_u(button => [ delete_button => 'Delete' ], ht => {
	[% cols_333_v %], HT_SEALED_[% table_v %]_id => 1,
});
$t->ok_ht_[% list_test_v %]_r(ht => { [% list_name_v %] => [] });
$t->ok_follow_link(text => 'Add [% table_class_v %]');
ENDS

1;
