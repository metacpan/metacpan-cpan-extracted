use strict;
use warnings FATAL => 'all';

package Apache::SWIT::Subsystem::Maker;
use base 'Apache::SWIT::Maker';
use Apache::SWIT::Subsystem::Makefile;
use File::Slurp;
use Apache::SWIT::Maker::Conversions;
use Apache::SWIT::Maker::Manifest;

sub makefile_class { return 'Apache::SWIT::Subsystem::Makefile'; }

sub write_950_install_t {
	my $self = shift;
	my $rc = Apache::SWIT::Maker::Config->instance->root_class;
	$self->add_test('t/950_install.t', 1, <<ENDT);
use Apache::SWIT::Maker;
use Apache::SWIT::Test::ModuleTester;
use Apache::SWIT::Test::Utils;
use File::Slurp;

# this is needed for root install of subsystem modules
use Test::TempDatabase;
Test::TempDatabase->become_postgres_user;

my \$mt = Apache::SWIT::Test::ModuleTester->new({ root_class => '$rc' });
\$mt->run_make_install;

chdir \$mt->root_dir;

\$mt->make_swit_project(root_class => 'MU');
\$mt->install_subsystem('TheSub');

my \$res = join('', `perl Makefile.PL && make test 2>&1`);
unlike(\$res, qr/Error/) or do {
	diag(read_file('t/logs/error_log'));
	ASTU_Wait(\$mt->root_dir);
};

chdir '/';
ENDT
}

# InstallationContent inherits it
sub write_maker_pm {
	my $self = shift;
	my $c = Apache::SWIT::Maker::Config->instance->root_class . "::Maker";
	swmani_write_file("lib/" . conv_class_to_file($c)
		, conv_module_contents($c, <<ENDM));
use base 'Apache::SWIT::Subsystem::Maker';
ENDM
}

sub available_commands {
	my %res = shift()->SUPER::available_commands(@_);
	$res{installation_content} = [ 'Write InstallationContent.pm' ];
	return %res;
}

sub write_initial_files {
	my $self = shift;
	$self->SUPER::write_initial_files(@_);
	$self->write_950_install_t;
	$self->write_maker_pm;

	my $mr = YAML::LoadFile('conf/makefile_rules.yaml');
	my $rc = Apache::SWIT::Maker::Config->instance->root_class;
	my $icf = "blib/lib/".conv_class_to_file($rc."::InstallationContent");
	push @{ $mr->[0]->{dependencies} }, $icf;
	push @$mr, { targets => [ $icf ], dependencies => [ 'conf/swit.yaml'
			, '%IC_TEST_FILES%' ]
		, actions => [ './scripts/swit_app.pl installation_content' ]
	};
	YAML::DumpFile('conf/makefile_rules.yaml', $mr);
}

sub add_class {
	my ($self, $new_class, $str) = @_;
	$self->SUPER::add_class($new_class, $str);
	Apache::SWIT::Maker::Config->instance->add_startup_class($new_class);
}

sub write_swit_yaml {
	my $gens = Apache::SWIT::Maker::Config->instance->generators;
	push @$gens, 'Apache::SWIT::Subsystem::Generator';
	shift()->SUPER::write_swit_yaml;
}

sub install_subsystem {
	my ($self, $module) = @_;
	my $lcm = lc($module);
	my $rc = Apache::SWIT::Maker::Config->instance->root_class;
	my $full_name =  $rc . '::' . $module;

	my $orig_tree = $self->this_subsystem_original_tree;
	my $gq = Apache::SWIT::Maker::GeneratorsQueue->new({
			generator_classes => $orig_tree->{generators} });
	my $tree = Apache::SWIT::Maker::Config->instance;
	while (my ($n, $v) = each %{ $orig_tree->{pages} }) {
		my $ep = $v->{entry_points} or next;
		$ep->{r}->{template} = "templates/$lcm/" . $ep->{r}->{template};
		my $fstr = delete $v->{file};
		swmani_write_file($ep->{r}->{template}, $fstr);
		$tree->{pages}->{"$lcm/$n"} = $v;
	}
	$tree->save;
	my $tests = $self->this_subsystem_original_tree->{dumped_tests};
	while (my ($n, $t) = each %$tests) {
		for my $p (keys %{ $orig_tree->{pages} }) {
			$t =~ s/$p\_/$lcm\_$p\_/g;
			$t =~ s#([^/])$p\b#$1$lcm/$p#g;
		}
		swmani_write_file("t/dual/$lcm/$n", $t);
	}
}

sub this_subsystem_name {
	my $class = ref(shift());
	$class =~ s/::Maker$//;
	return $class;
}

sub get_installation_content {
	my ($self, $func) = @_;
	return conv_eval_use($self->this_subsystem_name
			. "::InstallationContent")->$func;
}

sub this_subsystem_original_tree { 
	return shift()->get_installation_content(
				'this_subsystem_original_tree');
}

sub installation_content {
	shift()->makefile_class->write_ic;
}

1;
