# mamgal - a program for creating static image galleries
# Copyright 2008-2011 Marcin Owsiany <marcin@owsiany.pl>
# See the README file for license information
package App::MaMGal::TestHelper;
use Test::MockObject;
use Test::More;
use base 'Exporter';
use Carp;
@EXPORT = qw(get_mock_entry get_mock_iif get_mock_datetime_parser get_mock_formatter get_mock_localeenv get_mock_cc prepare_test_data get_mock_mplayer_wrapper get_mock_logger logged_only_ok logged_exception_only_ok get_mock_exception get_mock_fh printed_only_ok);

sub get_mock_entry
{
	my $class = (shift || 'App::MaMGal::Entry');
	my %args = @_;
	my $mock_entry = Test::MockObject->new
		->mock('set_root')
		->mock('make')
		->mock('add_tools')
		->mock('name', sub { $args{'name'} || 'filename.jpg' })
		->mock('description', sub { $args{'description'} || 'a description' })
		->mock('creation_time', sub { 1234 })
		->mock('page_path', sub { 'a/page/path' })
		->mock('thumbnail_path', sub { 'a/thumbnail/path' });
	$mock_entry->set_isa($class);
	return $mock_entry;
}

sub get_mock_fh {
	my $fh = Test::MockObject->new->mock('printf');
	return $fh;
}

sub get_mock_iif {
	my $f = Test::MockObject->new->mock('read', sub { Test::MockObject->new });
	$f->set_isa('App::MaMGal::ImageInfoFactory');
	$f
}

sub get_mock_logger {
	my $l = Test::MockObject->new
		->mock('log_message')
		->mock('log_exception');
	$l->set_isa('App::MaMGal::Logger');
	$l
}

sub get_mock_datetime_parser {
	my $p = Test::MockObject->new->mock('parse');
	$p->set_isa('Image::EXIF::DateTime::Parser');
	$p
}

sub get_mock_formatter {
	my @methods = @_;
	my $mf = Test::MockObject->new();
	$mf->set_isa('App::MaMGal::Formatter');
	$mf->mock($_, sub { "whatever" }) for @methods;
	return $mf;
}

sub get_mock_localeenv {
	my $ml = Test::MockObject->new();
	$ml->set_isa('App::MaMGal::LocaleEnv');
	$ml->mock('get_charset', sub { "ISO-8859-123" });
	$ml->mock('set_locale');
	$ml->mock('format_time', sub { "12:12:12" });
	$ml->mock('format_date', sub { "18 dec 2004" });
	return $ml;
}

sub get_mock_mplayer_wrapper {
	my $mmw = Test::MockObject->new;
	$mmw->set_isa('App::MaMGal::MplayerWrapper');
	my $mock_image = Test::MockObject->new;
	$mock_image->set_isa('Image::Magick');
	$mock_image->mock('Get', sub { '100', '100' });
	$mock_image->mock('Scale', sub { undef });
	$mock_image->mock('Write', sub { system('touch', $_[1] ) });
	$mmw->mock('snapshot', sub { $mock_image });
	return $mmw;
}

sub get_mock_cc($) {
	my $ret = shift;
	my $mcc = Test::MockObject->new;
	$mcc->set_isa('App::MaMGal::CommandChecker');
	$mcc->mock('is_available', sub { $ret });
}

sub prepare_test_data {
	# We have to create empty directories, because git does not track them
	for my $dir (qw(empty one_dir one_dir/subdir more/subdir/lost+found)) {
		mkdir("td.in/$dir") or die "td.in/$dir: $!" unless -d "td.in/$dir";
	}
	# We have to create and populate directories with spaces in their
	# names, because perl's makemaker does not like them
	mkdir "td.in/more/zzz another subdir" unless -d "td.in/more/zzz another subdir";
	my $orig_size = -s "td.in/p.png" or die "Unable to stat td.in/p.png";
	my $dest_size = -s 'td.in/more/zzz another subdir/p.png';
	unless ($dest_size and $orig_size == $dest_size) {
		system('cp', '-a', 'td.in/p.png', 'td.in/more/zzz another subdir/p.png');
	}
	# We also need to create our test symlinks, because MakeMaker does not like them
	for my $pair ([qw(td.in/symlink_broken broken)], [qw(td.in/symlink_pic_noext one_pic/a1.png)], [qw(td.in/symlink_to_empty empty)], [qw(td.in/symlink_to_empty_file empty_file)], [qw(td.in/symlink_pic.png one_pic/a1.png)]) {
		my ($link, $dest) = @$pair;
		symlink($dest, $link) or die "Failed to symlink [$dest] to [$link]" unless -l $link;
	}
	# Finally, purge and copy a clean version of the test data into "td"
	system('rm -rf td ; cp -a td.in td') == 0 or die "Test data preparation failed: $?";
}

sub logged_only_ok($$;$)
{
	my $mock = shift;
	my $re = shift;
	my $prefix = shift;
	my $level = $Test::Builder::Level;
	local $Test::Builder::Level = $level + 1;
	my ($name, $args) = $mock->next_call;
	is($name, 'log_message', 'expected method was called');
	like($args->[1], $re, 'message as expected');
	is($args->[2], $prefix, 'prefix as expected');
	($name, $args) = $mock->next_call;
	is($name, undef, 'no other logging method was called');
	return unless defined $name;
	is($args->[1], undef, 'no args were passed either');
	is($args->[2], undef, 'no args were passed either');
	is($args->[3], undef, 'no args were passed either');
}

sub printed_only_ok($$;$)
{
	my $mock = shift;
	my $re = shift;
	my $level = $Test::Builder::Level;
	local $Test::Builder::Level = $level + 1;
	my ($name, $args);
	if (ref $re and ref $re eq 'ARRAY') {
		foreach my $line_re (@$re) {
			($name, $args) = $mock->next_call;
			is($name, 'printf', "expected method was called (checking $line_re)");
			is($args->[1], "%s%s\n", "format string as expected (for $line_re)");
			like((($args->[2] ? $args->[2] : '') . ($args->[3] ? $args->[3] : '')), $line_re, 'message as expected');
		}
	} else {
		($name, $args) = $mock->next_call;
		is($name, 'printf', 'expected method was called');
		is($args->[1], "%s%s\n", 'format string as expected');
		like((($args->[2] ? $args->[2] : '') . ($args->[3] ? $args->[3] : '')), $re, 'message as expected');
	}
	($name, $args) = $mock->next_call;
	is($name, undef, 'no other logging method was called');
	return unless defined $name;
	is($args->[1], undef, 'no args were passed either');
	is($args->[2], undef, 'no args were passed either');
	is($args->[3], undef, 'no args were passed either');
}

sub logged_exception_only_ok($$;$)
{
	my $mock = shift;
	my $ex = shift;
	my $prefix = shift;
	my $level = $Test::Builder::Level;
	local $Test::Builder::Level = $level + 1;
	my ($name, $args) = $mock->next_call;
	is($name, 'log_exception');
	is($args->[1], $ex);
	is($args->[2], $prefix);
	($name, $args) = $mock->next_call;
	is($name, undef, 'no other logging method was called');
	return unless defined $name;
	is($args->[1], undef, 'no args were passed either');
	is($args->[2], undef, 'no args were passed either');
	is($args->[3], undef, 'no args were passed either');
}

sub get_mock_exception($)
{
	my $class = shift;
	my $e = Test::MockObject->new;
	$e->set_isa($class);
	$e->mock('message', sub { 'foo bar' });
	$e->mock('interpolated_message', sub { 'foo bar baz' });
	return $e;
}

1;
