use Dwarf::Pragma;
use Dwarf::Test::Model::Hoge;
use Test::More 0.88;

subtest 'lazy build method' => sub {
	my $value = 1;

	my $m = Dwarf::Test::Model::Hoge->new;
	is $m->readonly, $value;
};

subtest 'readonly' => sub {
	my $value = 1234;

	my $m = Dwarf::Test::Model::Hoge->new(readonly => $value);
	is $m->readonly, $value;

	eval { $m->readonly(++$value) };
	ok $@;
};

subtest 'readwrite' => sub {
	my $value = 3456;

	my $m = Dwarf::Test::Model::Hoge->new(data => $value);
	is $m->data, $value;

	eval { $m->data(++$value) };
	ok !$@;
};

subtest 'writeonly' => sub {
	my $value = 5678;

	my $m = Dwarf::Test::Model::Hoge->new(writeonly => $value);

	eval { $m->writeonly };
	ok $@;

	eval { $m->writeonly(++$value) };
	ok !$@;
};

subtest 'set LIST as ARRAY REF' => sub {
	my @list = qw/1 2 3/;

	my $m = Dwarf::Test::Model::Hoge->new;
	$m->data(@list);

	is_deeply($m->data, \@list);
};

subtest 'set LIST as HASH REF' => sub {
	my %list = (hoge => 1234);

	my $m = Dwarf::Test::Model::Hoge->new(data => {});
	$m->data(%list);

	is_deeply($m->data, \%list);
};

done_testing();
