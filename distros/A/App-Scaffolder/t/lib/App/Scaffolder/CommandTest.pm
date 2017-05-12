package App::Scaffolder::CommandTest;
use parent qw(Test::Class);

use strict;
use warnings;

use Carp;
use Test::More;
use Test::Exception;

use Path::Class::Dir;
use Test::File::ShareDir '-share' => {
	'-dist' => { 'App-Scaffolder' => Path::Class::Dir->new(qw(t testdata)) }
};
use File::ShareDir;
use Config;
use Test::Exception;
use App::Scaffolder::Command;
use App::Scaffolder::Command::dummy;

my $share_dir = Path::Class::Dir->new(File::ShareDir::dist_dir('App-Scaffolder'));
my $extra_dir0 = Path::Class::Dir->new(qw(t testdata extra_templates0))->absolute();
my $extra_dir1 = Path::Class::Dir->new(qw(t testdata extra_templates1))->absolute();

sub test_new : Test(1) {
	my ($self) = @_;

	new_ok('App::Scaffolder::Command::dummy' => [{}]);
}

sub get_template_dirs_test : Test(2) {
	my ($self) = @_;

	my $dummy = App::Scaffolder::Command::dummy->new({});
	is_deeply(
		[ $dummy->get_template_dirs() ],
		[ $share_dir->subdir('dummy') ],
		'template dirs found'
	);

	local $ENV{SCAFFOLDER_TEMPLATE_PATH} = $extra_dir0->stringify();
	is_deeply(
		[ $dummy->get_template_dirs() ],
		[ $extra_dir0->subdir('dummy'), $share_dir->subdir('dummy') ],
		'template dirs found'
	);
}

sub get_templates_test : Test(3) {
	my ($self) = @_;

	my $dummy = App::Scaffolder::Command::dummy->new({});
	my $template = $dummy->get_templates();
	isnt($template->{template}, undef, 'template found');
	is($template->{template}->get_name(), 'template', 'name ok');
	is_deeply(
		$template->{template}->get_path(),
		[$share_dir->subdir('dummy', 'template')],
		'path ok'
	);
}


sub get_template_test : Test(2) {
	my ($self) = @_;

	my $dummy = App::Scaffolder::Command::dummy->new({});
	my $template = $dummy->get_template('template');
	is($template->get_name(), 'template', 'name ok');

	throws_ok(
		sub { $dummy->get_template() },
		qr{Required 'name' parameter not passed or empty},
		'name parameter required'
	);
}


sub get_extra_template_dirs_test : Test(6) {
	my ($self) = @_;

	local $ENV{SCAFFOLDER_TEMPLATE_PATH} = $extra_dir0->stringify();
	my $dummy = App::Scaffolder::Command::dummy->new({});
	my @template_dirs = $dummy->get_extra_template_dirs('dummy');
	is(scalar @template_dirs, 1, 'one directory found');
	is_deeply($template_dirs[0], $extra_dir0->subdir('dummy'));

	$ENV{SCAFFOLDER_TEMPLATE_PATH} = $extra_dir0->stringify()
		. $Config::Config{path_sep}
			. $extra_dir1->stringify();
	@template_dirs = $dummy->get_extra_template_dirs('dummy');
	is(scalar @template_dirs, 2, 'two directories found');
	is_deeply($template_dirs[0], $extra_dir0->subdir('dummy'));
	is_deeply($template_dirs[1], $extra_dir1->subdir('dummy'));

	throws_ok(
		sub { $dummy->get_extra_template_dirs() },
		qr{Required 'command' parameter not passed or empty},
		'command parameter required'
	);
}


1;
