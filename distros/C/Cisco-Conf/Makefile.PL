# -*- perl -*-

require 5.004;
use strict;

require ExtUtils::MakeMaker;


my($ok) = 1;
my($recommended) = 0;
print "Checking for Data::Dumper ... ";
$@ = '';
eval "use Data::Dumper ();";
if ($@) {
    $ok = 0;
    print("\nYou don't have installed the Data::Dumper module.\n");
} else {
    print "ok\n";
}

print "Checking for Net::Telnet ... ";
$@ = '';
eval "use Net::Telnet ();";
if ($@) {
    $ok = 0;
    print("\nYou don't have installed the Net::Telnet module.\n");
} else {
    print "ok\n";
}

print "Checking for IO::AtomicFile ... ";
$@ = '';
eval "use IO::AtomicFile;";
if ($@) {
    $recommended = 1;
    print("\nYou don't have installed the IO::Scalar module\n",
	  "This module is not required, but recommended.\n");
} else {
    print "ok\n";
}

if (!$ok  ||  $recommended) {
    print("\n",
	  "Missing modules are available from any CPAN mirror, for example\n",
	  "\tftp://ftp.funet.fi/pub/languages/perl/CPAN/modules/by-module\n",
	  "\n");
}

if (!$ok) {
    exit 1;
}


use lib "lib";
require Cisco::Conf::Install;
require Cisco::Conf;

if ( -f "configuration" ) {
    $Cisco::Conf::config = Cisco::Conf->_ReadConfigFile("configuration");
} else {
    $Cisco::Conf::config = Cisco::Conf::Install->Install("./configuration",
							 "/usr/local/cisco");
}


ExtUtils::MakeMaker::WriteMakefile(
    'NAME'	   => 'Cisco::Conf',
    'VERSION_FROM' => 'lib/Cisco/Conf.pm',
    'EXE_FILES'    => [ 'cisconf' ],
    'dist'         => { 'SUFFIX'       => ".gz",
			'DIST_DEFAULT' => 'all tardist',
			'COMPRESS'     => "gzip -9f" },
    'realclean'    => { 'FILES' => 'configuration' },
    'clean'        => { 'FILES' => 'cisconf' }
);


package MY;

sub postamble {
    my($config) = $Cisco::Conf::config;

    my $etcdir = $config->{'etc_dir'};
    my $tftpdir = $config->{'tftp_dir'};
    my $perl = $^X;

    <<"EOF";

test :: all
	\$(NOOP)

install ::
	if [ `perl -e 'print \$\$>'` -ne 0 ]; then                           \\
	    echo "Sorry, but you must be root to install this module.";      \\
	    exit 1;                                                          \\
	fi
	$perl -MFile::Path -e 'mkpath(["$etcdir", "$tftpdir"], 1, 0755)'
	chown root \$(INSTALLSCRIPT)/cisconf
	chmod 4755 \$(INSTALLSCRIPT)/cisconf
	chown root $etcdir
	chmod 700 $etcdir
	if [ -f "$etcdir/configuration" ]; then                              \\
	    echo "Not overwriting existing configfile $etcdir/configuration";\\
	else                                                                 \\
	    cp configuration "$etcdir/configuration";                        \\
	fi

EOF
}

sub libscan {
    my($self, $path) = @_;
    if ($path =~ /\~$/) {
	undef;
    } else {
	$path;
    }
}
