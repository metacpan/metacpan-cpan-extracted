use strict;
use warnings FATAL => 'all';

package Apache::SWIT::Security::Maker::MF;
use base 'Apache::SWIT::Subsystem::Makefile';

sub make_this_subsystem_dumps {
	my %ot = shift()->SUPER::make_this_subsystem_dumps(@_);
	delete $ot{original_tree}->{dumped_tests}->{"020_secparams.t"};
	return %ot;
}

package Apache::SWIT::Security::Maker;
use base 'Apache::SWIT::Subsystem::Maker';
use Apache::SWIT::Security::Role::Loader;
use Data::Dumper;
use YAML;
use Apache::SWIT::Maker::Config;
use Apache::SWIT::Maker::Manifest;
use Apache::SWIT::Maker::Conversions;
use File::Slurp;

sub makefile_class { return ref(shift()) . "::MF"; }

sub write_loader_dump_pm {
	my ($self, $data, $class_name, $more) = @_;
	my $dump = Dumper($data);
	$dump =~ s/'Apache::SWIT::Security::Role::$class_name'/\$class/;
	my $rc = Apache::SWIT::Maker::Config->instance->{env_vars}
			->{'AS_SECURITY_' . uc($class_name) };
	my $file = "blib/lib/" . conv_class_to_file($rc);
	unlink $file;
	mkpath_write_file($file, conv_module_contents($rc, <<ENDS));
use base 'Apache::SWIT::Security::Role::$class_name';
$more
sub create {
	my \$class = shift;
	my $dump
	return \$VAR1;
}
ENDS
	append_file("blib/conf/do_swit_startups.pl", "use $rc;\n");
}

sub write_sec_modules {
	my ($self) = @_;
	my $loader = Apache::SWIT::Security::Role::Loader->new;
	my $tree = Apache::SWIT::Maker::Config->instance;
	$loader->load_role_container($tree->{roles});
	$loader->load($tree);

	my @roles = map { [ $_->[0], uc($_->[1]) . "_ROLE" ] }
				$loader->roles_container->roles_list;
	my $m = "use base 'Exporter';\nour \@EXPORT = qw("
		. join(" ", map { $_->[1] } @roles) . ");\n"
		. join("\n", map { "use constant $_->[1] => $_->[0];" } @roles);

	$self->write_loader_dump_pm($loader->roles_container, 'Container', $m);
	$self->write_loader_dump_pm($loader->url_manager, 'Manager', '');

	my $uc = $tree->{env_vars}->{AS_SECURITY_USER_CLASS};
	my $s = "use $uc;\n$uc->swit_startup;\n";
	write_file("blib/conf/do_swit_startups.pl"
		, $s . read_file("blib/conf/do_swit_startups.pl"));
}

sub install_subsystem {
	my ($self, $module) = @_;
	$self->SUPER::install_subsystem($module);

	my $tree = Apache::SWIT::Maker::Config->instance;
	my $full_class = Apache::SWIT::Maker::Config->instance->root_class
				. '::' . $module;
	my $ot = $self->this_subsystem_original_tree;
	$tree->{roles} = $ot->{roles};
	$tree->{env_vars}->{ "AS_SECURITY_" . uc($_) }
		= $full_class . "::Role::" . $_ for qw(Container Manager);
	$tree->{env_vars}->{AS_SECURITY_USER_CLASS}
		= 'Apache::SWIT::Security::DB::User';
	$tree->{env_vars}->{AS_SECURITY_SALT}
		= $ot->{env_vars}->{AS_SECURITY_SALT};
	push @{ $tree->{generators} }, 
	     'Apache::SWIT::Security::Role::Generator';
	$tree->save;

	my $rl = Apache::SWIT::Maker::Config->instance->root_location
			. "/" . lc($module);
	my $mr = YAML::LoadFile('conf/makefile_rules.yaml')
			or die "Unable to open makefile_rules.yaml";
	my $role_dir =  "blib/lib/$full_class/Role";
	$role_dir =~ s/::/\//g;

	my @new_pms = map { "$role_dir/$_.pm" } qw(Container Manager);
	push @{ $mr->[0]->{dependencies} }, @new_pms;
	my ($cmr) = grep { (grep { /swit\.yaml/ } @{ $_->{dependencies} }) }
			@$mr;
	push @{ $cmr->{targets} }, @new_pms;
	YAML::DumpFile('conf/makefile_rules.yaml', $mr);
}

1;
