use strict;
use warnings FATAL => 'all';

package Apache::SWIT::Maker::Makefile;
use base 'Class::Accessor';
use File::Slurp;
use ExtUtils::MakeMaker;
use ExtUtils::Manifest;
use YAML;
use File::Path qw(mkpath);
use Cwd qw(abs_path);
use ExtUtils::Install;
use Apache::SWIT::Maker::Config;
use Apache::SWIT::Maker::Conversions;
use Carp;

__PACKAGE__->mk_accessors('overrides', 'blib_filter', 'no_swit_overrides');

sub Args {
	my $s = read_file('Makefile.PL');
	my ($args) = ($s =~ /(\([^;]+)/);
	return $args;
}

sub get_makefile_rules {
	my $rules = YAML::LoadFile('conf/makefile_rules.yaml')
		or die "No makefile rules found";
	my $res = "";
	for my $r (@$rules) {
		while (my ($n, $v) = each %{ $r->{vars} || {} }) {
			$res .= "$n = $v\n";
		}
		$res .= join(' ',  @{ $r->{targets} }) . " :: ";
		$res .= join(' ', @{ $r->{dependencies} || [] }) . "\n\t";
		$res .= join("\n\t", @{ $r->{actions} || [] }) . "\n\n";
	}
	return $res;
}

sub _Blib_Filter {
	$_ = shift;
	return (/templates/ || /startup\.pl/ || /public_html/);
}

sub _init_dirscan {
	my $self = shift;
	my $bf = $self->blib_filter || $self->can('_Blib_Filter');
	my $fs = ExtUtils::Manifest::maniread();
	my @files = grep { $bf->($_); } keys %$fs;
	return unless @files;
	$self->overrides->{const_config} = sub {
		my $this = shift;
		my $res = $this->MY::SUPER::const_config(@_);
		$this->{PM}->{$_} = "blib/$_" for @files;
		return $res;
	};
}

sub _mm_install {
	return <<ENDS;
install :: all
	./scripts/swit_app.pl install \$(INSTALLSITELIB)
ENDS
}

sub _mm_constants {
	my $str = shift()->MY::SUPER::constants(\@_);
	my $an = Apache::SWIT::Maker::Config->instance->app_name;
	my $rep = "INSTALLSITELIB=\$(SITEPREFIX)/share/$an";
	$str =~ s#INSTALLSITELIB[^\n]+#$rep#;
	return $str;
}

sub _mm_test {
	my $res = shift()->MY::SUPER::test(@_);
	if ($<) {
		$res =~ s/PERLRUN\)/PERLRUN) -I t\//g;
	} else {
		my $cmd = "./scripts/swit_app.pl test_root test";
		$res =~ s#\$\(FULLPERLRUN\).*#$cmd#;
		$res =~ s#test_ : .*#test_ :\n\t$cmd\_#;
	}
	return $res;
}

sub find_tests_str {
	return sprintf('`find t/%s -name "*.t" | sort`', $_[1]);
}

sub test_apache_lines {
	return ('$(RM_F) t/logs/access_log  t/logs/error_log'
		, 'ulimit -c unlimited && PERL_DL_NONLAZY=1 $(FULLPERLRUN) '
			. '-I t -I blib/lib t/apache_test.pl ' . $_[1]);
}

sub _mm_postamble {
	my $tests_str = $< ? sprintf(q{
test_dual :: test_direct test_apache 

test :: test_direct test_apache 

APACHE_TEST_FILES = %s

test_direct :: pure_all
	PERL_DL_NONLAZY=1 $(FULLPERLRUN) -I t -I blib/lib t/direct_test.pl $(APACHE_TEST_FILES)

test_apache :: pure_all
	%s
}, __PACKAGE__->find_tests_str('dual'), join("\n\t"
	, __PACKAGE__->test_apache_lines('$(APACHE_TEST_FILES)'))) : q{
test_dual :: pure_all
	./scripts/swit_app.pl test_root test_dual
test_apache :: pure_all
	./scripts/swit_app.pl test_root test_apache
test_direct :: pure_all
	./scripts/swit_app.pl test_root test_direct
};

	return __PACKAGE__->get_makefile_rules . $tests_str . q{
realclean ::
	$(RM_RF) t/htdocs t/logs
	$(RM_F) t/conf/apache_test_config.pm  t/conf/modperl_inc.pl t/T/Test.pm
	$(RM_F) t/conf/extra.conf t/conf/httpd.conf t/conf/modperl_startup.pl
	$(RM_F) blib/conf/httpd.conf t/conf/mime.types t/conf/schema.sql
};
}

my @_swit_overrides = qw(test postamble constants install);

sub _init_swit_sections {
	my $self = shift;
	return if $self->no_swit_overrides;
	$self->overrides({}) unless $self->overrides;
	for my $o (@_swit_overrides) {
		next if $self->overrides->{$o};
		my $f = $self->can("_mm_$o") or next;
		$self->overrides->{$o} = $f;
	}
}

sub write_makefile {
	my $self = shift;
	$self->_init_swit_sections;
	$self->_init_dirscan;
	my $o = $self->overrides || {};
	while (my ($n, $f) = each %$o) {
		no strict 'refs';
		no warnings 'redefine';
		*{ "MY::" . $n } = $f;
	}
	WriteMakefile(@_);
}

sub deploy_httpd_conf {
	my ($class, $from, $to) = @_;
	mkpath("$to/conf");
	my $from_ap = abs_path($from);
	my $to_ap = abs_path($to);
	$_ = read_file("$from_ap/conf/httpd.conf");
	s#$from_ap#$to_ap#g;
	conv_forced_write_file("$to_ap/conf/httpd.conf", "PerlSetEnv "
			. "APACHE_SWIT_DB_NAME $ENV{APACHE_SWIT_DB_NAME}\n$_");
}

sub update_db_schema {
	my ($class, $to) = @_;
	if (!$ENV{APACHE_SWIT_DB_NAME} && -f "$to/conf/httpd.conf") {
		my @lines = read_file("$to/conf/httpd.conf");
		($ENV{APACHE_SWIT_DB_NAME}) = ($lines[0]
				=~ /PerlSetEnv APACHE_SWIT_DB_NAME (\w+)/);
	}
	confess "No APACHE_SWIT_DB_NAME given" unless $ENV{APACHE_SWIT_DB_NAME};
	push @INC, "t", "blib/lib";

	# become_postgres_user changes uid of the process. We will not be
	# able to copy files afterwards. Do it in child then.
	if (fork) {
		wait;
	} else {
		conv_eval_use("T::TempDB");
		exit;
	}
}

sub install_files {
	my ($class, $from, $to) = @_;
	my $pf = "$to/.packfile";
	ExtUtils::Install::install({ $from, $to, "write" => $pf, "read", $pf });
}

sub do_install {
	my ($class, $from, $to) = @_;
	$class->update_db_schema($to);
	$class->install_files($from, $to);
	$class->deploy_httpd_conf($from, $to);
}

1;
