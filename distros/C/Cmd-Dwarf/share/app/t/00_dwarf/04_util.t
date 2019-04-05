use Dwarf::Pragma;
use Dwarf::Util;
use Dwarf::Util::DateTime;
use FindBin qw($Bin);
use Test::More 0.88;

subtest "add_method" => sub {
	use URI;
	my $uri = URI->new;
	ok !$uri->can('hoge');
	Dwarf::Util::add_method($uri, 'hoge', sub { return 'ok' });
	ok $uri->can('hoge');
	is $uri->hoge, 'ok';
};

subtest "load_class" => sub {
	ok !eval { Dwarf->new };
	Dwarf::Util::load_class('Dwarf');
	my $dwarf = Dwarf->new;
	ok $dwarf;
};

subtest "installed" => sub {
	ok Dwarf::Util::installed('Dwarf');
};

subtest "capitalize" => sub {
	my $str = "hogeFuga";
	is Dwarf::Util::capitalize($str), "HogeFuga";
	$str = "hoge-fuga";
	is Dwarf::Util::capitalize($str), "HogeFuga";
	$str = "hoge_fuga";
	is Dwarf::Util::capitalize($str), "HogeFuga";
};

subtest "shuffle_array" => sub {
	my @arr = qw/1 2 3/;
	my @new = Dwarf::Util::shuffle_array(@arr);
	ok @new;
	is scalar @new, scalar @arr;
};

subtest "filename" => sub {
	ok Dwarf::Util::filename('Dwarf') =~ /^.+\/Dwarf\.pm$/;
};

subtest "read_file" => sub {
	my $content = Dwarf::Util::read_file(__FILE__);
	ok $content;
	ok length $content > 0;
};

subtest "write_file" => sub {
	my $path = "$Bin/write_file.txt";
	my $content = "1234";
	Dwarf::Util::write_file($path, $content);
	is $content, Dwarf::Util::read_file($path);
	ok unlink $path;
};

subtest "get_suffix" => sub {
	is Dwarf::Util::get_suffix('test.txt'), 'txt';
	is Dwarf::Util::get_suffix('test.tmpl.html'), 'html';
};

subtest "safe_join" => sub {
	is Dwarf::Util::safe_join(',', 1, 2, undef, 3), '1,2,,3';
};

subtest "merge_hash" => sub {
	my $a = { a => 1, b => 2 };
	my $b = { b => -2, c => 3, };
	Dwarf::Util::merge_hash($a, $b);
	is $a->{a}, 1;
	is $a->{b}, -2;
	is $a->{c}, 3;
};

subtest "datetime" => sub {
	my $now = DateTime->new(
		year  => "2014",
		month => "06",
		day   => "14",
		hour  => "17",
	);
	my $the_time = Dwarf::Util::DateTime::str2dt("2014-06-14 18:00:00");

	ok Dwarf::Util::DateTime::is_duration_positive($the_time, $now);

	$now = DateTime->new(
		year  => "2014",
		month => "06",
		day   => "14",
		hour  => "18",
	);
	ok !Dwarf::Util::DateTime::is_duration_positive($the_time, $now);

	is Dwarf::Util::DateTime::str2dt("2014-06-14 18:00:00"), "2014-06-14T18:00:00", 'str2dt';
	is Dwarf::Util::DateTime::str2dt("2018-06-14T18:00:00"), "2018-06-14T18:00:00", 'str2dt';
	is Dwarf::Util::DateTime::str2dt("2018-06-14T18:00"),    "2018-06-14T18:00:00", 'str2dt';
	my @t = localtime;
	my $year = $t[5] + 1900;
	is Dwarf::Util::DateTime::str2dt("06-14T18:00:00"), "${year}-06-14T18:00:00", 'str2dt';
};

done_testing();
