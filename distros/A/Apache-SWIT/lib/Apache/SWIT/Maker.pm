=head1 NAME

Apache::SWIT::Maker - creates various skeleton files for your SWIT project.

=head1 METHODS

=cut
use strict;
use warnings FATAL => 'all';

package Apache::SWIT::Maker;
use base 'Class::Accessor';
use File::Path;
use File::Basename qw(dirname basename);
use File::Copy;
use Crypt::CBC;
use Cwd qw(abs_path getcwd);
use Apache::SWIT::Maker::GeneratorsQueue;
use Apache::SWIT::Maker::FileWriterData;
use Apache::SWIT::Maker::Conversions;
use Apache::SWIT::Maker::Config;
use Apache::SWIT::Maker::Makefile;
use File::Slurp;
use Digest::MD5 qw(md5_hex);
use Apache::SWIT::Maker::Manifest;
use ExtUtils::Manifest qw(maniread manicopy);
use File::Temp qw(tempdir);
use Data::Dumper;

__PACKAGE__->mk_accessors(qw(file_writer));

my @_initial_skels = qw(apache_test apache_test_run dual_001_load startup);

sub _load_skeleton {
	my ($class, $skel_class, $func) = @_;
	my $s = 'Apache::SWIT::Maker::Skeleton::' . $skel_class;
	conv_eval_use($s);

	no strict 'refs';
	*{ __PACKAGE__ . "::$func" } = sub { return $s; }
		unless __PACKAGE__->can($func);
}

__PACKAGE__->_load_skeleton(conv_table_to_class($_), $_) for @_initial_skels;

my %_page_skels = (qw(skel_page Page skel_template Template
		skel_ht_page HT::Page skel_ht_template HT::Template
		skel_db_class DB::Class scaffold_dual_test Scaffold::DualTest)
		, map { ("scaffold_".lc($_), "Scaffold::$_"
			, "scaffold_".lc($_)."_template"
			, "Scaffold::$_"."Template") } qw(List Form Info));

while (my ($n, $v) = each %_page_skels) {
	__PACKAGE__->_load_skeleton($v, $n);
}

sub makefile_class { return 'Apache::SWIT::Maker::Makefile'; }

sub new {
	my $self = shift->SUPER::new(@_);
	$self->{file_writer} ||= Apache::SWIT::Maker::FileWriterData->new;
	return $self;
}

sub schema_class {
	return Apache::SWIT::Maker::Config->instance->root_class
		. '::DB::Schema';
}

sub write_swit_yaml {
	swmani_write_file('conf/swit.yaml', "");
	Apache::SWIT::Maker::Config->instance->save;
}

sub write_makefile_pl {
	my $self = shift;
	my $args = Apache::SWIT::Maker::Makefile::Args();
	my $mc = $self->makefile_class;
	write_file('Makefile.PL', <<ENDM);
use strict;
use warnings FATAL => 'all';
use $mc;

$mc\->new->write_makefile$args;
ENDM
}

sub add_class { 
	my ($self, $new_class, $str) = @_;
	my $rc = Apache::SWIT::Maker::Config->instance->root_class;
	$new_class = $rc . "::$new_class" if ($new_class !~ /^$rc\::/);
	$self->file_writer->write_lib_pm({ content => $str }
			, { new_root => $new_class });
}

sub write_session_pm {
	my $self = shift;
	my $an = Apache::SWIT::Maker::Config->instance->app_name;
	$self->add_class(Apache::SWIT::Maker::Config->instance
			->session_class, <<ENDM);
use base 'Apache::SWIT::Session';

sub cookie_name { return '$an'; }

ENDM
}

sub write_db_schema_file {
	my $self = shift;
	my $an = Apache::SWIT::Maker::Config->instance->app_name;
	swmani_write_file("lib/" . conv_class_to_file($self->schema_class)
			, conv_module_contents($self->schema_class, <<ENDM));
use base 'DBIx::VersionedSchema';
__PACKAGE__->Name('$an');

__PACKAGE__->add_version(sub {
	my \$dbh = shift;
});

ENDM
}

sub write_test_db_file {
	swmani_write_file('t/T/TempDB.pm', sprintf(<<'ENDS'
package T::TempDB;
use Apache::SWIT::Test::DB;
Apache::SWIT::Test::DB->setup('%s_test_db', '%s');
1;
ENDS
	, Apache::SWIT::Maker::Config->instance->app_name
	, shift()->schema_class));
}

sub write_t_extra_conf_in {
	my $self = shift;
	my $an = Apache::SWIT::Maker::Config->instance->app_name;
	swmani_write_file('t/conf/extra.conf.in', <<ENDM);
PerlPassEnv APACHE_SWIT_DB_NAME
PerlPassEnv APACHE_SWIT_SERVER_URL
LogLevel notice
<IfModule mod_mime.c>
	Include "/etc/apache2/mods-enabled/mime.conf"
</IfModule>
Include ../blib/conf/httpd.conf
CustomLog logs/access_log switlog
<Location />
	PerlInitHandler Apache::SWIT::Test::ResetKids->access_handler
</Location>
ENDM
}

sub write_seal_key {
	swmani_write_file("conf/seal.key"
		, md5_hex(Crypt::CBC->random_bytes(8)));
}

sub write_httpd_conf_in {
	my $self = shift;
	my $rl = Apache::SWIT::Maker::Config->instance->root_location;
	my $an = Apache::SWIT::Maker::Config->instance->app_name;
	swmani_write_file('conf/httpd.conf.in', <<ENDM);
RewriteEngine on
RewriteRule ^/\$ $rl/index/r [R]
Alias $rl/www \@ServerRoot\@/public_html 
Alias /html-tested-javascript /usr/local/share/libhtml-tested-javascript-perl
# Format is:
# Remote IP, time, request, status, duration, referer, user agent
# PID, Cookie, total bytes in request, total bytes in response
LogFormat "%a %t \\"%r\\" %>s %D \\"%{Referer}i\\" \\"%{User-Agent}i\\" %P %{$an}C %I %O" switlog
ENDM
}

sub add_test {
	my ($self, $file, $number, $content) = @_;
	unless ($number) {
		$number = 1;
		$content = "BEGIN { use_ok('"
			. Apache::SWIT::Maker::Config->instance->root_class
			."'); }";
	}
	swmani_write_file($file, <<ENDT);
use strict;
use warnings FATAL => 'all';

use Test::More tests => $number;

$content
ENDT
}

sub write_010_db_t {
	shift()->add_test('t/010_db.t', 1, <<ENDM);
use T::TempDB;

package T::DBI;
use base 'Apache::SWIT::DB::Base';
__PACKAGE__->table('test_table');
__PACKAGE__->columns(Essential => qw/a b/);

package main;
Apache::SWIT::DB::Connection->instance->db_handle->do(
		"create table test_table (a integer, b text)");
is_deeply([ T::DBI->retrieve_all ], []);

ENDM
}

sub write_swit_app_pl {
	my $self = shift;
	$self->file_writer->write_scripts_swit_app_pl({
				class => ref($self) });
	chmod 0755, 'scripts/swit_app.pl';
}

sub install {
	my ($self, $inst_dir) = @_;
	my $si = Apache::SWIT::Maker::Config->instance->{skip_install} || [];
	my %skips = map {
		my $v = read_file($_) or die "Nothing for $_";
		($_, $v);
	} map { "blib/$_" } @$si;
	unlink($_) for keys %skips;
	$self->makefile_class->do_install("blib", $inst_dir);
	write_file($_, $skips{$_}) for keys %skips;
}

sub write_initial_files {
	my $self = shift;
	$self->$_->new->write_output for @_initial_skels;

	$self->write_swit_yaml;
	$self->write_session_pm;
	$self->write_db_schema_file;
	$self->write_test_db_file;
	$self->write_t_extra_conf_in;
	$self->write_httpd_conf_in;
	$self->write_seal_key;
	swmani_write_file("public_html/main.css", "# Sample CSS file\n");
	$self->file_writer->write_t_direct_test_pl;

	my $rc = Apache::SWIT::Maker::Config->instance->root_class;
	$self->file_writer->write_conf_makefile_rules_yaml({ rc => $rc });

	$self->write_makefile_pl;
	$self->write_010_db_t;
	$self->write_swit_app_pl;
	$self->add_ht_page('Index');
}

sub dump_db {
	push @INC, "t", "lib";
	unlink("t/conf/schema.sql");
	system("touch t/conf/schema.sql && chmod a+rw t/conf/schema.sql")
		unless ($<);
	conv_eval_use('T::TempDB');
	system("pg_dump -c $ENV{APACHE_SWIT_DB_NAME} > t/conf/schema.sql");
}

sub _make_page {
	my ($self, $page_class, $args, @funcs) = @_;
	my $i = Apache::SWIT::Maker::Config->instance;
	my $e = $i->create_new_page($page_class);
	for my $f (@funcs) {
		my $p = $self->$f->new($args);
		$p->config_entry($e);
		$p->write_output;
	}
	$i->save;
	return $e;
}

=head2 add_page(page)

Adds page and related files. Page should be the name of the module, 
e.g. 'Index'. See C<add_ht_page> for adding HTML::Tested enabled page.

=cut
sub add_page {
	my ($self, $pc) = @_;
	return $self->_make_page($pc, {}, qw(skel_template skel_page));
}

=head2 add_ht_page(page)

Adds HTML::Tested enabled page and related files. 
Page should be the name of the module, e.g. 'Index'.

=cut
sub add_ht_page {
	my ($self, $pc) = @_;
	return $self->_make_page($pc, {}, qw(skel_ht_template skel_ht_page));
}

sub _location_section_start {
	my ($self, $l, $c, $h) = @_;
return <<ENDS
<Location $l>
	SetHandler perl-script
	PerlHandler $c\->$h
ENDS
}

sub gen_conf_header {
	return <<ENDS;
<IfModule !apreq_module.c>
	LoadModule apreq_module /usr/lib/apache2/modules/mod_apreq2.so
</IfModule>
<IfModule !rewrite_module.c>
	LoadModule rewrite_module /usr/lib/apache2/modules/mod_rewrite.so
</IfModule>
<IfModule !mod_deflate.c>
	LoadModule deflate_module /usr/lib/apache2/modules/mod_deflate.so
</IfModule>
AddOutputFilterByType DEFLATE text/html text/plain text/xml text/css application/x-javascript application/javascript application/xhtml+xml image/svg+xml

PerlModule Apache2::Request Apache2::Cookie Apache2::Upload Apache2::SubRequest
ENDS
}

sub regenerate_httpd_conf {
	my $self = shift;
	my $gq = Apache::SWIT::Maker::GeneratorsQueue->new;
	my $tree = Apache::SWIT::Maker::Config->instance;
	my ($sc, $rl) = ($tree->{session_class}, $tree->{root_location});
	my $ht_in = $self->gen_conf_header . <<ENDS;
PerlPostConfigRequire \@ServerRoot\@/conf/startup.pl
PerlPostConfigRequire \@ServerRoot\@/conf/do_swit_startups.pl
<Location $rl>
	PerlAccessHandler $sc\->access_handler
	PerlSetVar SWITRootLocation $rl
</Location>
ENDS
	my $evars = $tree->{env_vars} || {};
	my $s = join("\n", map { "\$ENV{$_} = '$evars->{$_}';" } keys %$evars);

	my ($aliases, $spl) = ("", "BEGIN {\n$s\n};\n" . join("\n", map {
		"use $_;\n$_\->swit_startup;"
	} @{ $tree->{startup_classes} || [] }) . "\n");

	$tree->for_each_url(sub {
		my ($url, $pname, $pentry, $ep) = @_; 
		my $res = $gq->run('location_section_prolog', $pname, $pentry);
		$ht_in .= $self->_location_section_start($url, $pentry->{class}
				, $ep->{handler});
		$ht_in .= $gq->run('location_section_contents', $url, $ep);
		$ht_in .= "</Location>\n";

	});
	while (my ($n, $v) = each %{ $tree->{pages} }) {
		$aliases .= "\"$n\" => \"$v->{class}\",\n";
		$spl .= "use $v->{class};\n$v->{class}->swit_startup;\n"
	}

	mkpath_write_file('blib/conf/do_swit_startups.pl', "$spl\n1;\n");

	my $hcstr = $ht_in . $gq->run('httpd_conf_start');
	my $blib = abs_path("blib");
	$hcstr =~ s/\@ServerRoot\@/$blib/g;
	write_file('blib/conf/httpd.conf', $hcstr);

	$self->file_writer->write_t_t_test_pm({
		session_class => $tree->{session_class}
		, root_location => $tree->{root_location}
		, blib_dir => abs_path("blib")
		, aliases => $aliases, httpd_session_class =>
			$tree->{session_class} });
	return $tree;
}

sub remove_file {
	my ($self, $file) = @_;
	swmani_filter_out($file);
	unlink($file);
}

=head2 remove_page(page)

Removes page and related files. Page is relative to the root location

=cut
sub remove_page {
	my ($class, $page) = @_;
	my $tree = Apache::SWIT::Maker::Config->instance;
	my $ep = lc($page);
	$ep =~ s/::/\//g;
	my $p = delete $tree->{pages}->{$ep} or die "Unable to find $page";
	my $module_file = "lib/" . $p->{class} . ".pm";
	$module_file =~ s/::/\//g;
	$class->remove_file($module_file);
	$class->remove_file($p->{entry_points}->{r}->{template});
	$tree->save;
}

sub add_db_class {
	my ($self, $table) = @_;
	my $sc = $self->skel_db_class->new({ table => $table });
	$sc->write_output;
	return $sc->class_v;
}

sub _extract_columns {
	my ($self, $c) = @_;
	push @INC, "t", "lib";
	conv_eval_use('T::TempDB');
	conv_eval_use($c);
	my %pc = map { ($_, 1) } $c->primary_columns;
	return grep { !$pc{$_} } $c->columns;
}

sub scaffold {
	my ($self, $table) = @_;
	my $db_class = $self->add_db_class($table);

	my @cols = $self->_extract_columns($db_class);
	my $args = { columns => [ @cols ], table => $table };
	$self->scaffold_dual_test->new($args)->write_output;

	my $ct = conv_table_to_class($table);
	$self->_make_page("$ct\::$_", $args, "scaffold_".lc($_)
		, "scaffold_".lc($_)."_template") for qw(List Info Form);
}

sub run_server {
	my ($self, $hp, $dbn) = @_;
	$hp ||= 1;
	conv_silent_system("perl Makefile.PL") unless -f 'Makefile';
	$ENV{APACHE_SWIT_DB_NAME} = $dbn if $dbn;
	$ENV{__APACHE_SWIT_RUN_SERVER__} = $hp;
	system("make test_apache");
}

sub freeze_schema {
	my $self = shift;
	push @INC, "t", "lib";
	conv_eval_use('T::TempDB');
	system("pg_dump -O -c $ENV{APACHE_SWIT_DB_NAME} > conf/frozen.sql");
	append_file('MANIFEST', "\nconf/frozen.sql\n")
		unless read_file('MANIFEST') =~ /conf\/frozen\.sql/;
}

sub add_migration {
	my ($self, $name, $sql) = @_;
	mkpath("t/$name");
	copy($sql, "t/$name/db.sql") or die "Unable to copy $sql to t/$name";
	append_file('MANIFEST', "\nt/$name/db.sql\n");

	my $fstr = Apache::SWIT::Maker::Makefile->find_tests_str($name);
	my $vn = uc($name) . "_TEST_FILES";
	my @ac = Apache::SWIT::Maker::Makefile->test_apache_lines("\$($vn)");
	my $load = "APACHE_SWIT_LOAD_DB=t/mig/db.sql";
	$ac[1] =~ s#PERL_DL_NONLAZY#$load PERL_DL_NONLAZY#;
			
	my $mr = YAML::LoadFile('conf/makefile_rules.yaml');
	push @$mr, { targets => [ "test_$name" ], dependencies => [ "pure_all" ]
			, actions => \@ac, vars => { $vn, $fstr } }
		, { targets => [ "test" ], dependencies => [ "test_$name" ] };
	YAML::DumpFile('conf/makefile_rules.yaml', $mr);
}

sub override {
	my ($self, $page) = @_;
	my $c = Apache::SWIT::Maker::Config->instance;
	my $p = $c->find_page($page) or die "Unable to find $page page";
	my $rc = $c->root_class;
	my $cc = $p->class;
	$cc =~ /^(\w+)::UI::(\S+)$/ or die "Unable to match " . Dumper($p);
	my $pc = $p->class("$rc\::UI::$1\::$2");
	$self->add_class($pc, <<ENDS);
use base '$cc';
ENDS
	$c->save;
}

sub mv {
	my ($self, $from, $to) = @_;
	swmani_replace_file($from, $to);
	swmani_replace_in_files($from, $to);
	my ($cf, $ct) = (conv_file_to_class($from), conv_file_to_class($to));
	swmani_replace_in_files(-f $to ? sub {
		s/$cf\::Root/$ct\::Root/g;
		s/$cf([^:\w])/$ct$1/g;
	} : ($cf, $ct));

	my ($ef, $et) = map { conv_class_to_entry_point($_) } ($cf, $ct);
	my $cstr = read_file('conf/swit.yaml');
	if (-f $to) {
		$cstr =~ s#$ef\:#$et\:#g;
	} else {
		$cstr =~ s#$ef(.+):#$et$1:#g;
	}
	write_file('conf/swit.yaml', $cstr);

	# change test functions
	my ($tf_f, $tf_t) = ($ef, $et);
	s#\/#_#g for ($tf_f, $tf_t);
	swmani_replace_in_files(-f $to ? sub {
		s/ht_$tf_f(_\w)\b/ht_$tf_t$1/g;
	} : ("ht_$tf_f", "ht_$tf_t"));

	my $tt_ef = "templates/$ef";
	if (-f $to) {
		$tt_ef .= ".tt";
		$et .= ".tt";
	}
	$self->mv($tt_ef, "templates/$et") if ($cstr =~ m#$tt_ef#);
}

sub available_commands { return (
add_class => [ '<class> - adds new class.', 1 ]
, add_db_class => [ '<class> - adds new database class.', 1 ]
, add_ht_page => [ '<class> - adds new HTML::Tested based page.', 1 ]
, add_page => [ '<class> - adds new page.', 1 ]
, add_test => [ '<file> - adds new test file.' ]
, install => [ '<dir> - installs into dir.' ]
, mv => [ '<from> <to> - moves file or directory updating all things which
		reference it.', 1 ]
, override => [ '<class> - overrides page class by inheriting from it.' ]
, regenerate_httpd_conf => [ '- regenerates httpd.conf.' ]
, run_server => [ '<host:port> <db> - runs Apache on optional host:port using
			db name if given.' ]
, scaffold => [ '<table_name> - generates classes and templates supporting
		<table_name> CRUD operation.', 1 ]
, add_migration => [ '<name> <sql> - create migration test target', 1 ]
, freeze_schema => [ 'freezes schema' ]
, dump_db => [ 'dumps temporary database into t/conf/schema.sql' ]
, test_root => [ 'Runs tests in temporary directory as different user' ]
); }

sub swit_app_cmd_params {
	my ($self, $cmd) = @_;
	my %cmds = $self->available_commands;
	return $cmds{$cmd} if ($cmd && $cmds{$cmd});
	my $res = "Usage: $0 <cmd> <args> where available commands are:\n";
	for my $n (sort keys %cmds) {
		my $v = $cmds{$n};
		$res .= "$n $v->[0]\n";
	}
	print $res;
	return undef;
}

sub do_swit_app_cmd {
	my ($self, $cmd, @args) = @_;
	my $p = $self->swit_app_cmd_params($cmd) or return;
	my ($mf_before);
	local $ExtUtils::Manifest::Quiet = 1;
	my $bf_name = join("_", $cmd, @args);
	$bf_name =~ s/\W/_/g;
	my $cwd = getcwd();
	my $backup_dir = "$cwd/../$bf_name";
	if ($p->[1]) {
		$mf_before = maniread();
		manicopy($mf_before, $backup_dir);
		conv_silent_system("make realclean") if -f 'Makefile';
	}
	eval { $self->$cmd(@args); };
	my $err = $@;
	if ($err && $p->[1]) {
		chdir $backup_dir;
		manicopy($mf_before, $cwd);
		chdir $cwd;
	} elsif ($p->[1]) {
		mkpath("backups");
		my $mf = maniread();
		$mf->{$_} = 1 for keys %$mf_before;
		# diff returns 1 for some reason
		system("diff -uN $backup_dir/$_ $_ >> backups/$bf_name.patch")
				for (sort keys %$mf);
		conv_silent_system("perl Makefile.PL");
	}
	rmtree($backup_dir) if $p->[1];
	die "Rolled back. Original exception is $err" if $err;
	return 1;
}

sub test_root {
	my ($self, @args) = @_;
	my $td = tempdir("/tmp/swit_test_root_XXXXXX");
	my $cwd = abs_path(getcwd());
	my $mfiles = maniread();
	manicopy($mfiles, $td);
	chdir $td;
	system("chmod a+rwx `find . -type d`") and die;
	system("chmod a+rw `find . -type f`") and die;
	eval "use Test::TempDatabase";

	my $dn = __FILE__;
	for (; basename($dn) ne 'Apache'; $dn = dirname($dn))
		{} # nothing
	system("cp -a $dn .") and die;

	my $pid = fork();
	if (!$pid) {
		Test::TempDatabase->become_postgres_user;
		system("perl Makefile.PL") and die;
		system("make") and die;
		system("ln -s `pwd`/Apache blib/lib/Apache") and die;
		system("make", @args) and die;
		exit;
	}
	waitpid $pid, 0;
	die "Child finished abnormally: $?" if $?;
	my @to_copy = map { chomp; $_; } `find . -newer Makefile -type f`;
	for my $f (grep { !/^\.\/blib/ } @to_copy) {
		mkpath($cwd . "/" . dirname($f));
		copy($f, "$cwd/$f") or die $f;
	}
	chdir($cwd);
	rmtree($td);
}

1;
