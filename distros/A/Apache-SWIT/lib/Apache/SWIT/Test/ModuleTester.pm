use strict;
use warnings FATAL => 'all';

package Apache::SWIT::Test::ModuleTester;
use base 'Class::Accessor';
use File::Temp qw(tempdir);
use File::Basename qw(basename);
use Apache::SWIT::Maker;
use File::Slurp;
use Carp;
use YAML;
use Linux::Unshare qw(unshare_ns);
use Test::TempDatabase;

__PACKAGE__->mk_accessors(qw(root_dir root_class install_dir project_class
			subsystem_name no_cleanup));

sub new {
	delete $ENV{TEST_FILES};
	delete $ENV{MAKEFLAGS};
	delete $ENV{MAKEOVERRIDES};

	my $self = shift()->SUPER::new(@_);
	$self->root_dir(tempdir("/tmp/" . basename($0) 
				. "_XXXXXX", CLEANUP => $self->no_cleanup ? 0 : 1))
		unless $self->root_dir;
	return $self;
}

sub run_modulemaker {
	my $rc = shift()->root_class;
	undef $Apache::SWIT::Maker::Config::_instance;
	`modulemaker -I -n $rc`;
}

sub module_dir {
	my $md = shift()->root_class;
	$md =~ s/::/\//g;
	return $md;
}

sub run_modulemaker_and_chdir {
	my $self = shift;
	$self->run_modulemaker;
	chdir $self->module_dir 
		or die "Unable to chdir to " . $self->module_dir;
}

sub run_make_install {
	my $self = shift;
	my $td = $self->root_dir;
	my $md = $self->module_dir;
	my @in_lines = `make install SITEPREFIX=$td/inst 2>&1`;
	for my $il (@in_lines) {
		if ($il =~ /^Installing (.+)\/$md\.pm/) {
			$self->install_dir($1);
			last;
		}
	}
	my $res = join('', @in_lines);
	die "Unable to find install_dir in $res" unless $self->install_dir;
	return $res;
}

sub make_swit_project {
	my ($self, %args) = @_;
	my $maker = $args{maker} || 'Apache::SWIT::Maker';
	my $old_rc = $self->root_class;
	$self->root_class($args{root_class}) if ($args{root_class});
	$self->run_modulemaker_and_chdir;
	$maker->new->write_initial_files;
	$self->project_class($self->root_class);
	$self->root_class($old_rc);
}

sub install_subsystem {
	my ($self, $name) = @_;
	my $md = $self->module_dir;
	my ($first) = ($md =~ /^([^\/]+)/);
	die "# Unable to find first in $md" unless $first;
	my $inst_dir = $self->install_dir . "/$first";
	symlink($inst_dir, $first);
	symlink("$inst_dir.pm", "$first.pm") if ($first eq $md);
	require "$md/Maker.pm" or die "Unable to require $md/Maker.pm";
	my $mc = $self->root_class . "::Maker";
	$mc->new->install_subsystem($name);
	$self->subsystem_name($name);
}

sub replace_in_file {
	my ($self, $f, $from, $to) = @_;
	my $str = read_file($f);
	$str =~ s/$from/$to/g
		or confess "# Unable to replace $from to $to in $f:\n$str";
	write_file($f, $str);
}

sub insert_into_schema_pm {
	my ($self, $str) = @_;
	$self->replace_in_file('lib/' . $self->module_dir . "/DB/Schema.pm", 
			'shift;', "shift;\n$str");
}

sub install_subsystem_schema {
	my $self = shift;
	my $old_rc = $self->root_class;
	my $sc_class = "$old_rc\::DB::Schema";
	$self->root_class($self->project_class);
	$self->insert_into_schema_pm("use $sc_class;\n"
			. "$sc_class->new(\$dbh)->run_updates;\n");
	$self->root_class($old_rc);
}

sub install_session_base {
	my $self = shift;
	my $old_rc = $self->root_class;
	$self->root_class($self->project_class);
	my $sub_class = $self->root_class . "::" . $self->subsystem_name;
	my $sess_class = "$old_rc\::Session";
	$self->replace_in_file('lib/' . $self->module_dir . "/Session.pm", 
			'use base [^;]+', 
			"use base '$sess_class'");
	$self->root_class($old_rc);

	my $tree = YAML::LoadFile('conf/swit.yaml');
	push @{ $tree->{startup_classes} }, $sess_class;
	YAML::DumpFile('conf/swit.yaml', $tree);
}

sub Drop_Root {
	return if $<;
	unshare_ns() and die;
	system("mount --bind blib/lib /mnt") and die;
	$ENV{PERL5LIB} = "/mnt";
	push @INC, "/mnt";
	Test::TempDatabase->become_postgres_user;
}

1;
