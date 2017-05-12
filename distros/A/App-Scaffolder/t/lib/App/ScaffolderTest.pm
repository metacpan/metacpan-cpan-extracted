package App::ScaffolderTest;
use parent qw(Test::Class);

use strict;
use warnings;

use Carp;
use Test::More;
use Test::Exception;
use App::Cmd::Tester;
use Test::File;
use Directory::Scratch;
use Path::Class::Dir;
use Test::File::ShareDir '-share' => {
	'-dist' => { 'App-Scaffolder' => Path::Class::Dir->new(qw(t testdata)) }
};
use App::Scaffolder;


sub app_test : Test(5) {
	my ($self) = @_;

	my $scratch = Directory::Scratch->new();
	my $result = test_app('App::Scaffolder' => [
		qw(dummy --template template --target), $scratch->base()
	]);
	like($result->stdout(), qr{.+content.txt}, 'no output');
	is($result->error(), undef, 'threw no exceptions');
	my $file = $scratch->base()->file('content.txt');
	file_exists_ok($file, 'expected file created');
	is($file->slurp(), "Some file.\n", 'content ok');

	$scratch = Directory::Scratch->new();
	$result = test_app('App::Scaffolder' => [
		qw(dummy --template template --quiet --target), $scratch->base()
	]);
	is($result->stdout(), '', 'no output');
}


sub no_overwrite_without_option_test : Test(6) {
	my ($self) = @_;

	my $scratch = Directory::Scratch->new();
	my $options = [ qw(dummy --template template --target), $scratch->base() ];

	my $result = test_app('App::Scaffolder' => $options);
	is($result->error(), undef, 'threw no exceptions');

	$result = test_app('App::Scaffolder' => $options);
	like($result->error(), qr{File .+ exists}, 'threw exceptions');

	push @{$options}, '--overwrite';
	$result = test_app('App::Scaffolder' => $options);
	is($result->error(), undef, 'threw no exceptions');
}


1;
