# -*- perl -*-
#
#   $Id: Makefile.PL,v 1.2 1999/02/13 00:24:43 joe Exp $
#
#
#   Apache::Roaming - A mod_perl handler for Roaming Profiles
#
#
#   Based on mod_roaming by
#	Vincent Partington <vincentp@xs4all.nl>
#	See http://www.xs4all.nl/~vincentp/software/mod_roaming.html
#
#
#   Copyright (C) 1999    Jochen Wiedmann
#                         Am Eisteich 9
#                         72555 Metzingen
#                         Germany
#
#                         Phone: +49 7123 14887
#                         Email: joe@ispsoft.de
#
#   All rights reserved.
#
#   You may distribute this module under the terms of either
#   the GNU General Public License or the Artistic License, as
#   specified in the Perl README file.
#
############################################################################

require 5.004;
use strict;


use ExtUtils::MakeMaker;
use Getopt::Long;
use Cwd;


use vars qw($opt_config);
Getopt::Long::GetOptions('config');


my %prereq = ('File::Spec' => 0,
	      'Data::Dumper' => 0,
	      'URI::Escape' => 0,
	      'Apache' => 0);

use lib 'lib';
eval { require Apache::Roaming::LiPrefs::Config };

my $cfg;
eval {require File::Spec; require Data::Dumper};
if (!$@  &&
    (!($cfg = eval { require ".status"})  or  $opt_config)) {
    $cfg = {} if !$cfg or ref($cfg) ne 'HASH';
    my $httpd_path = $cfg->{'httpd_path'};
    if (!$httpd_path) {
	foreach my $dir (File::Spec->path()) {
	    my $file = File::Spec->catfile($dir, "httpd");
	    if (-x $file) {
		$httpd_path = $file;
		last;
	    }
	}
    }
    $cfg->{'httpd_path'} = prompt("Path of the Apache server: ",
				  $httpd_path || '/usr/sbin/httpd');
    die "Cannot execute HTTPD server $cfg->{'httpd_path'}: No such file"
	unless -x $cfg->{'httpd_path'};

    my $httpd_V_output = `$cfg->{'httpd_path'} -V`;
    my $httpd_conf_path =
	($httpd_V_output =~ /\s+-D\s+SERVER_CONFIG_FILE="(.*?)"/) ?
	    $1 : "/etc/httpd/httpd.conf";
    $cfg->{'httpd_conf_path'} = prompt("Path of the httpd.conf file: ",
				       $httpd_conf_path);
    my $httpd_conf_contents;
    die "Failed to read httpd config file $cfg->{'httpd_conf_path'}: $!"
	unless open(FILE, "<$cfg->{'httpd_conf_path'}");

    my(@module_list, $server_root);
    while (defined(my $line = <FILE>)) {
	if ($line =~ /\s*ServerRoot\s+\"?(.*?)\"?\s*$/) {
	    $server_root = $1;
	}
	if ($line =~ /^\s*(AddModule|LoadModule)\s+/  ||
	    $line =~ /^\s*ClearModuleList\s*$/) {
	    push(@module_list, $line);
	}
    }
    close(FILE);
    @module_list = map {
	if ($_ =~ /^\s*LoadModule\s+(\S+)\s+(.*)/) {
	    my $module = $1;
	    my $path = $2;
	    if ($path !~ /^\//) {
		die "Cannot parse httpd config file $cfg->{'httpd_conf_path'}:"
		    . " Missing ServerRoot" unless $server_root;
		$_ = "LoadModule $module $server_root/$path\n";
	    }
	}
	$_;
    } @module_list;
    $cfg->{'dynamic_module_list'} = join("", @module_list);

    $cfg->{'httpd_user'} = prompt("HTTPD's UID for running tests: ",
				  $cfg->{'httpd_user'} || ('#' . $>));
    my $gid = $);
    $gid =~ s/\s.*//;
    $cfg->{'httpd_group'} = prompt("HTTPD's GID for running tests: ",
				   $cfg->{'httpd_group'} || ('#' . $gid));
    $cfg->{'httpd_port'} = prompt("Port to use for running tests: ",
				  $cfg->{'httpd_port'} || 8259);

    my $tdir = $cfg->{'t_dir'} = File::Spec->catdir(Cwd::getcwd(), "t");
    $cfg->{'httpd_conf'} = File::Spec->catfile($tdir, "httpd.cnf");
    $cfg->{'access_conf'} = File::Spec->catfile($tdir, "access.cnf");
    $cfg->{'srm_conf'} = File::Spec->catfile($tdir, "srm.cnf");
    $cfg->{'types_conf'} = File::Spec->catfile($tdir, "mime.types");
    $cfg->{'user_file'} = File::Spec->catfile($tdir, "htusers");
    my $log_dir = File::Spec->catdir($tdir, "logs");
    $cfg->{'log_dir'} = $log_dir;
    $cfg->{'access_log'} = File::Spec->catfile($log_dir, "access.log");
    $cfg->{'error_log'} = File::Spec->catfile($log_dir, "error.log");
    $cfg->{'lock_file'} = File::Spec->catfile($log_dir, "httpd.lck");
    $cfg->{'pid_file'} = File::Spec->catfile($log_dir, "httpd.pid");
    my $o_dir = $cfg->{'output_dir'} = File::Spec->catdir($tdir, "output");
    $cfg->{'roaming_dir'} = File::Spec->catdir($o_dir, "roaming");

    my $dump = Data::Dumper->new([$cfg], ['cfg']);
    $dump->Indent(1);
    if (!open(STATUS, ">.status")  ||
	!(print STATUS $dump->Dump())  ||
	!close(STATUS)) {
	die "Error while creating file .status: $!";
    }

    my $reply = prompt("Do you want to configure the Apache::Roaming::LiPrefs module?", "y");
    if ($reply =~ /y/i) {
	foreach my $ref
	    (['Enable Autoupdate', 'bool', 'initial', 'autoupdate.enabled',
	      'false'],
	     ["Enable what's related?", 'bool', 'initial',
	      'browser.related.enabled', 'true'],
	     ['Startup Page', 'string', 'initial', 'browser.startup.page',
	      'none',
	      sub {
		  my $in = shift;
		  $in = 'none' if !defined($in) or $in eq '0';
		  $in;
	      },
	      sub {
		  my $out = shift;
		  $out = '0' if !defined($out) or $out eq 'none';
	      }],
	     ['By default send HTML mail', 'bool', 'initial',
	      'mail.html_compose', 'false'],
	     ['Default domain', 'string', 'initial',
	      'mail.identity.defaultdomain'],
	     ['Leave mail on server', 'bool', 'initial',
	      'mail.leave_on_server', 'false'],
	     ['Remember mail password', 'bool', 'initial',
	      'mail.remember_password', 'false'],
	     ['Default NNTP server', 'string', 'initial',
	      'network.hosts.nntp_server'],
	     ['Default POP3 server', 'string', 'initial',
	      'network.hosts.pop_server'],
	     ['Default SMTP server', 'string', 'initial',
	      'network.hosts.smtp_server'],
	     ['Proxy autoconfiguration URL', 'string', 'initial',
	      'network.proxy.autoconfig_url'],
	     ['FTP Proxy', 'string', 'initial',
	      'network.proxy.ftp'],
	     ['FTP Proxy Port', 'string', 'initial',
	      'network.proxy.ftp_port'],
	     ['Gopher Proxy', 'string', 'initial',
	      'network.proxy.gopher'],
  	     ['Gopher Proxy Port', 'string', 'initial',
  	      'network.proxy.gopher_port'],
  	     ['HTTP Proxy', 'string', 'initial',
  	      'network.proxy.http'],
  	     ['HTTP Proxy Port', 'string', 'initial',
  	      'network.proxy.http_port'],
  	     ['SSL Proxy', 'string', 'initial',
  	      'network.proxy.ssl'],
  	     ['SSL Proxy Port', 'string', 'initial',
  	      'network.proxy.ssl_port'],
  	     ['WAIS Proxy', 'string', 'initial',
  	      'network.proxy.wais'],
  	     ['WAIS Proxy Port', 'string', 'initial',
	      'network.proxy.wais_port'],
  	     ['No Proxies for', 'string', 'initial',
  	      'network.proxy.no_proxies_on', '127.0.0.1 localhost'],
	     ['Send Email address as FTP password', 'bool', 'initial',
  	      'security.email_as_ftp_password', 'true'],
	     ['Send Warning while submitting an insecure POST', 'bool',
  	      'initial', 'security.warn_entering_secure', 'true'],
	     ['Send Warning while entering a secure area', 'bool', 'initial',
  	      'security.warn_submit_insecure', 'true']) {
		my($prompt, $type, $initial, $var, $default, $in_filter,
		   $out_filter) = @$ref;
		if (exists($Apache::Roaming::LiPrefs::ALWAYS{$var})) {
		    $initial = 'always';
		    $default = $Apache::Roaming::LiPrefs::ALWAYS{$var};
		} elsif (exists($Apache::Roaming::LiPrefs::INITIAL{$var})) {
		    $initial = 'initial';
		    $default = $Apache::Roaming::LiPrefs::INITIAL{$var};
		}
		$default = &$in_filter($default) if $in_filter;
		if ($type eq 'bool') {
		    if (defined($default)
			and  $default ne 'true'
			and  $default ne 'false') {
			$default = $default ? 'true' : 'false';
		    }
		}
		$default = defined($default) ?
		    prompt($prompt, $default) : prompt($prompt);
		if ($type eq 'bool') {
		    if (defined($default)
			and  $default ne 'true'
			and  $default ne 'false') {
			$default = $default ? 'true' : 'false';
		    }
		}
		$default = &$out_filter($default) if $out_filter;
		$initial = prompt("  Allow user to override this variable?",
				  ($initial eq 'initial') ? 'y' : 'n')
		    if defined($default);
		if ($initial =~ /y/i) {
		    delete $Apache::Roaming::LiPrefs::ALWAYS{$var};
		    $Apache::Roaming::LiPrefs::INITIAL{$var} = $default;
		    delete $Apache::Roaming::LiPrefs::INITIAL{$var}
			unless defined($default);
		} else {
		    delete $Apache::Roaming::LiPrefs::INITIAL{$var};
		    $Apache::Roaming::LiPrefs::ALWAYS{$var} = $default;	    
		    delete $Apache::Roaming::LiPrefs::ALWAYS{$var}
			unless defined($default);
		}
	    }
    }
}

if (!open(CONF, ">$cfg->{'access_conf'}")  ||  !close(CONF)) {
    die "Error while writing $cfg->{'access_conf'}: $!";
}
if (!open(CONF, ">$cfg->{'srm_conf'}")  ||  !close(CONF)) {
    die "Error while writing $cfg->{'srm_conf'}: $!";
}
if (!open(CONF, ">$cfg->{'types_conf'}")  ||  !close(CONF)) {
    die "Error while writing $cfg->{'types_conf'}: $!";
}

my $config_dir = File::Spec->catdir(File::Spec->curdir(),
				    "lib", "Apache", "Roaming", "LiPrefs");
if (!-d $config_dir   and  !(mkdir $config_dir, 0755)) {
    die "Error while creating directory $config_dir";
}
my $config_file = File::Spec->catfile($config_dir, "Config.pm");
my $initial = Data::Dumper->new([\%Apache::Roaming::LiPrefs::INITIAL],
				['initial']);
$initial->Indent(1);
my $always = Data::Dumper->new([\%Apache::Roaming::LiPrefs::ALWAYS],
			       ['always']);
$always->Indent(1);
my $config_contents = sprintf(<<'EOF', $initial->Dump(), $always->Dump());
package Apache::Roaming::LiPrefs::Config;
my %s
my %s
%%Apache::Roaming::LiPrefs::INITIAL = %%$initial;
%%Apache::Roaming::LiPrefs::ALWAYS = %%$always;
1;
EOF
if (!open(CONF, ">$config_file")
    ||  !(print CONF $config_contents)  ||  !close(CONF)) {
    die "Error while creating $config_file: $!";
}

my %opts = (
    'NAME'      => 'Apache::Roaming',
    'dist'      => { SUFFIX   => '.gz', DIST_DEFAULT => 'all tardist',
                     COMPRESS => 'gzip -9vf' },
    'VERSION_FROM' => 'lib/Apache/Roaming.pm', # finds $VERSION
    'clean' => { 'FILES' => 't/logs t/output t/htusers'},
    'realclean' => { 'FILES' => '.status t/*.cnf'},
);

if ($ExtUtils::MakeMaker::VERSION >= 5.43) {
    $opts{'AUTHOR'} = 'Jochen Wiedmann <joe@ispsoft.de>';
    $opts{'PREREQ_PM'} = \%prereq;
    $opts{'ABSTRACT'} = 'Netscape Roaming Access via Apache';
}

WriteMakefile(%opts);
exit 0;


package MY;

sub libscan {
    my $self = shift; my $path = shift;
    return undef if $path =~ /\~$/;
    $path;
}

sub postamble {
    qq{

pm_to_blib: README

README: lib/Apache/Roaming.pm
\tperldoc -t lib/Apache/Roaming.pm >README

};
}
