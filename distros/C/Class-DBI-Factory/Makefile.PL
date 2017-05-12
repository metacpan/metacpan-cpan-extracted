#!/usr/bin/perl -w                                         # -*- perl -*-

use strict;
use lib qw( ./lib );
use Class::DBI::Factory;
use ExtUtils::MakeMaker;
$|++;

use vars qw( $INSTALL_DEMO $DEMO_ROOT $DEMO_URL $DEMO_PORT $CDF_VERSION $SILENT);

$CDF_VERSION = $Class::DBI::Factory::VERSION;

#___________________

package MY;

sub postamble {
	return '' unless $main::INSTALL_DEMO;
	return <<'EOM';
demo ::
	perl ./cdfdemo/install.pl -v "$(DEMO_ROOT)" "$(DEMO_URL)" "$(DEMO_PORT)"

EOM
}

sub install {
    my $class = shift;
    my $makerule = $class->SUPER::install(@_);
    $makerule =~ s/^(install\s+::\s+.*)$/$1 demo/m if $main::INSTALL_DEMO;;
    return $makerule;
}

sub constants {
    my $class = shift;
    my $usual = $class->SUPER::constants(@_);
    $usual = "DEMO_ROOT = $main::DEMO_ROOT\nDEMO_URL = $main::DEMO_URL\nDEMO_PORT = $main::DEMO_PORT\n$usual" if $main::INSTALL_DEMO;
    return $usual;
}


#___________________

package main;

print <<"EOM";

*** Installing Class::DBI::Factory v${CDF_VERSION} ***

CDF by itself has a few more or less predictable requirements, including 
Class::DBI, Ima::DBI, AppConfig and Email::Send.

If you also choose to install the included demo application, which is highly
recommended unless you've used CDF before, the requirements will grow to include
DBD::SQLite, the Template Toolkit, File::NCopy and Text::CSV::Simple. All of
these dependencies will be followed automatically if you're installing through
CPAN.pm.

EOM

my %config = (
    NAME         => 'Class::DBI::Factory',
    VERSION_FROM => 'lib/Class/DBI/Factory.pm',
    PMLIBDIRS    => [ 'lib' ], 
    PREREQ_PM    => { 
    	'Class::DBI' => 0.96,
    	'Ima::DBI' => 0.33,
    	'AppConfig' => 0,
    	'Email::Send' => 0,
    	'Test::Exception' => 0,
    	'Error' => 0,
	},
    dist         => {
        'COMPRESS' => 'gzip',
        'SUFFIX'   => 'gz',
    },
);

$INSTALL_DEMO = confirm('install the demo application?');

if ($INSTALL_DEMO) {
	$DEMO_ROOT = ttprompt('installation directory for demo:', '/home/cdfdemo');
	$DEMO_URL = ttprompt('url for demo site (omit the http://):', 'localhost');
	$DEMO_PORT = ttprompt('listen on a particular port?');
	$config{PREREQ_PM}->{'DBD::SQLite'} = 1.08;
	$config{PREREQ_PM}->{'Template'} = 2;
	$config{PREREQ_PM}->{'File::NCopy'} = 0;
	$config{PREREQ_PM}->{'Text::CSV::Simple'} = 0;
}

if ($ExtUtils::MakeMaker::VERSION >= 5.43) {
    $config{ AUTHOR   } = 'William Ross <wrross@cpan.org>';
    $config{ ABSTRACT } = 'Factory interface to a set of Class::DBI classes, with optional mod_perl application framework.';
}

WriteMakefile( %config );

print "\nConfiguration complete: now run make, make test and make install.\n";
print "When you run 'make install', the demo application will be installed to
$DEMO_ROOT. See cdf_demo/README for more information.\n" if $INSTALL_DEMO && $DEMO_ROOT;
print "\n";

#___________________ends


# this is borrowed cargo-style from TT2 Makefile. 
# I don't know why AW dislikes the standard prompt()
# but am not qualified to argue.

sub ttprompt {
    my ($msg, $def)=@_;
    my $tty = -t STDIN && (-t STDOUT || !(-f STDOUT || -c STDOUT)) ;
    my $dispdef = defined $def ? "[$def] " : " ";
    $def = defined $def ? $def : "";
    my $ans = '';
    local $|=1;
    print "$msg $dispdef" unless $SILENT;
    if ($tty) {
        chomp($ans = <STDIN>);
    } else {
        print "$def\n" unless $SILENT;
    }
    return ($ans ne '') ? $ans : $def;
}

sub confirm {
    my ($msg)=@_;
    my $tty = -t STDIN && (-t STDOUT || !(-f STDOUT || -c STDOUT)) ;
    my $ans;
    local $|=1;
    print "$msg [y/N] " unless $SILENT;
    if ($tty) {
        chomp($ans = <STDIN>);
    } else {
        print "N\n" unless $SILENT;
    }
    return 0 unless $ans && $ans =~ /^[yY]/;
    return 1;
}

