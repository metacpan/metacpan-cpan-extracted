package App::Scaffolder::TemplateTest;
use parent qw(Test::Class);

use strict;
use warnings;

use Carp;
use Test::More;
use Test::Exception;
use Path::Class::Dir;
use Path::Class::File;
use Directory::Scratch;

use App::Scaffolder::Template;

my $dir0 = Path::Class::Dir->new(qw(t testdata test_template))->absolute();
my $dir1 = Path::Class::Dir->new(qw(t testdata test_template2))->absolute();
my $dir2 = Path::Class::Dir->new(qw(t testdata test_template3))->absolute();
my $dir3 = Path::Class::Dir->new(qw(t testdata test_template4))->absolute();

sub new_test : Test(1) {
	my ($self) = @_;

	new_ok('App::Scaffolder::Template' => [{
		name => 'test_template',
		path => [Path::Class::Dir->new(qw(t testdata test_template))]
	}]);
}

sub path_test : Test(2) {
	my ($self) = @_;

	my $template = App::Scaffolder::Template->new({
		name => 'test_template',
		path => [$dir0],
	});
	is_deeply($template->get_path(), [$dir0], 'path set');

	$template->add_path_entry($dir1);
	is_deeply($template->get_path(), [$dir0, $dir1], 'path extended');
}

sub get_template_files_test : Test(2) {
	my ($self) = @_;

	my $template = App::Scaffolder::Template->new({
		name => 'test_template',
		path => [$dir0],
	});

	my $files = $template->get_template_files();
	is_deeply($files, {
		'foo.txt' => {
			source     => $dir0->file('foo.txt'),
			rel_target => Path::Class::File->new('foo.txt'),
		},
		'bar.txt' => {
			source     => $dir0->file('bar.txt.tt'),
			rel_target => Path::Class::File->new('bar.txt'),
		},
	}, 'files found');

	$template = App::Scaffolder::Template->new({
		name => 'test_template',
		path => [$dir1, $dir0],
	});
	$files = $template->get_template_files();
	is_deeply($files, {
		'foo.txt' => {
			source     => $dir0->file('foo.txt'),
			rel_target => Path::Class::File->new('foo.txt'),
		},
		'bar.txt' => {
			source     => $dir1->file('bar.txt'),
			rel_target => Path::Class::File->new('bar.txt'),
		},
		'foobar.txt' => {
			source     => $dir1->file('foobar.txt'),
			rel_target => Path::Class::File->new('foobar.txt'),
		},
	}, 'files found');
}


sub replace_file_path_variables_test : Test(11) {
	my ($self) = @_;

	my $template = App::Scaffolder::Template->new({
		name => 'test_template3',
		path => [$dir2],
	});

	my $file = Path::Class::File->new('___name1___.txt');
	my $variables = {
		name1 => 'testname1',
		name2 => Path::Class::File->new('dir1', 'dir2', 'testname2'),
		dir1  => 'dir1',
		dir2  => 'dir2',
		dir3  => Path::Class::Dir->new('dir1', 'dir2', 'dir3'),
	};
	my $result = $template->replace_file_path_variables($file, $variables);
	is($result, Path::Class::File->new('testname1.txt'), 'name replaced');

	$file = Path::Class::File->new('___dir1___/___name1___.txt');
	$result = $template->replace_file_path_variables($file, $variables);
	is($result, Path::Class::File->new('dir1', 'testname1.txt'), 'name and dir replaced');

	$file = Path::Class::File->new('___dir1___/___dir2___/___name1___.txt');
	$result = $template->replace_file_path_variables($file, $variables);
	is($result, Path::Class::File->new('dir1', 'dir2', 'testname1.txt'), 'name and dir replaced');

	$file = Path::Class::File->new('___dir3___/___name1___.txt');
	$result = $template->replace_file_path_variables($file, $variables);
	is($result, Path::Class::File->new('dir1', 'dir2', 'dir3', 'testname1.txt'), 'name and dir replaced');

	$file = Path::Class::File->new('___name2___.txt');
	$result = $template->replace_file_path_variables($file, $variables);
	is($result, Path::Class::File->new('dir1', 'dir2', 'testname2.txt'), 'name replaced');

	$file = Path::Class::File->new('___name2.txt');
	$result = $template->replace_file_path_variables($file, $variables);
	is($result, Path::Class::File->new('___name2.txt'), 'name not replaced');

	$file = Path::Class::File->new('___dir1/___name1___.txt');
	$result = $template->replace_file_path_variables($file, $variables);
	is($result, Path::Class::File->new('___dir1/testname1.txt'), 'dir not replaced');

	$file = Path::Class::File->new('___dir1______dir2___/___name1___.txt');
	$result = $template->replace_file_path_variables($file, $variables);
	is($result, Path::Class::File->new('dir1dir2/testname1.txt'), 'dirs replaced');

	my @candidates = qw(___dir___/file dir/___dir___/file dir/___file___);
	for my $file (map { Path::Class::File->new($_) } @candidates) {
		throws_ok(sub {
			$result = $template->replace_file_path_variables($file, {
				dir  => '..',
				file => '..',
			});
		}, qr{Potential directory traversal detected}, 'directory traversal avoided');
	}
}


sub process_test : Test(4) {
	my ($self) = @_;

	my $template = App::Scaffolder::Template->new({
		name => 'test_template',
		path => [$dir0],
	});

	my $scratch = Directory::Scratch->new();
	my @files = $template->process({
		target    => $scratch->base(),
		variables => {
			variable_value => 'a variable value',
		}
	});
	is(scalar @files, 2, 'two files created');
	is_deeply([
		sort @files
	], [
		$scratch->base()->file('bar.txt'), $scratch->base()->file('foo.txt')
	], 'files created');
	is(
		$scratch->base()->file('bar.txt')->slurp(),
		"Some test text with a variable value.\n",
		'content of bar.txt ok'
	);
	is(
		$scratch->base()->file('foo.txt')->slurp(),
		"Some static test text.\n",
		'content of bar.txt ok'
	);
}


sub process_with_path_variables_test : Test(7) {
	my ($self) = @_;

	my $template = App::Scaffolder::Template->new({
		name => 'test_template3',
		path => [$dir2],
	});

	my $scratch = Directory::Scratch->new();
	my $basedir = $scratch->base();
	my @files = $template->process({
		target    => $basedir,
		variables => {
			dir  => 'directory',
			dir2 => 'directory2',
			name => 'testname',
		}
	});
	is(scalar @files, 4, 'four files created');
	is_deeply([
		sort @files
	], [
		$basedir->file('directory', 'directory2', 'file2.txt'),
		$basedir->file('directory', 'directory2', 'testname'),
		$basedir->file('directory', 'file.txt'),
		$basedir->file('testname'),
	], 'files created');
	is($basedir->file('directory', 'directory2', 'file2.txt')->slurp(), "File 2\n", 'content ok');
	is($basedir->file('directory', 'directory2', 'testname')->slurp(), "testname\n", 'content ok');
	is($basedir->file('directory', 'file.txt')->slurp(), "directory\n", 'content ok');
	is($basedir->file('testname')->slurp(), "content\n", 'content ok'),

	$scratch = Directory::Scratch->new();
	$basedir = $scratch->base();
	throws_ok(sub {
		$template->process({
			target    => $basedir,
			variables => {
				dir  => '..',
				dir2 => '..',
				name => 'testname',
			}
		})
	}, qr{Potential directory traversal detected}, 'directory traversal avoided');
}


sub get_content_for_test : Test(2) {
	my ($self) = @_;

	my $template = App::Scaffolder::Template->new({
		name => 'test_template',
		path => [$dir0],
	});
	is(
		$template->get_content_for($dir0->file('foo.txt'), undef),
		"Some static test text.\n",
		'static content returned'
	);
	is(
		$template->get_content_for($dir0->file('bar.txt.tt'), {
			variable_value => 'testtext'}
		),
		"Some test text with testtext.\n",
		'dynamic content returned'
	);
}


sub no_overwrite_without_force_test : Test(6) {
	my ($self) = @_;

	my $template = App::Scaffolder::Template->new({
		name => 'test_template4',
		path => [$dir3],
	});

	my $scratch = Directory::Scratch->new();
	my $process_params = {
		target    => $scratch->base(),
		variables => {
			variable_value => 'initial value',
		}
	};

	# Overwrite prevented
	my @files = $template->process($process_params);
	is(scalar @files, 1, 'one file created');
	is($files[0]->slurp(), "initial value\n", 'content ok');
	throws_ok(
		sub {
			$template->process($process_params);
		},
		qr{File .+foo\.txt exists - need to pass 'overwrite' parameter to overwrite files},
		'overwrite not performed'
	);
	is($files[0]->slurp(), "initial value\n", 'content not overwritten');

	# Force overwrite
	$process_params->{overwrite} = 1;
	$process_params->{variables}->{variable_value} = 'fresh value';
	@files = $template->process($process_params);
	is(scalar @files, 1, 'file overwritten');
	is($files[0]->slurp(), "fresh value\n", 'content ok');
}


1;
