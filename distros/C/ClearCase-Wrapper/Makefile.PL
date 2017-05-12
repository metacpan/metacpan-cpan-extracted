use ExtUtils::MakeMaker;
use File::Basename;
use File::Find;

### Sample installation: perl Makefile.PL PREFIX=/opt/local/perl5

# The upgrade may be cleaner if the old version is uninstalled manually.
# Try to catch that situation here.
my $cnt = 0;
sub wanted {
    return unless /^Burrow.al$/;
    my $d = dirname($File::Find::name);
    return unless $d =~ /Wrapper/;
    return if $cnt++;
    warn qq(Warning: found old version in $d/....
You may prefer to remove this manually - see README for details.\n);
}
find(\&wanted, @INC);

# Explain a little background at install time.
print q(
    This module installs a wrapper script 'cleartool.plx'.  Typically
    you'll want to access it by a shorthand such as 'ct', 'cl', 'clt',
    'Ct', or even just 'c'. This must be set up by hand and may be
    done on UNIX via a symbolic link, e.g.:

	% cd /opt/local/bin; ln -s cleartool.plx ct

    or on Windows by making a tiny ct.bat file containing:

	@echo off
	perl //UNC/path/to/cleartool.plx %*

*NOTE*  There are additional 'overlay' modules available which
*NOTE*  extend the functionality of this module.
*NOTE*  Consider ClearCase::Wrapper::DSB, ClearCase::Wrapper::MGi, etc.

);

# The regular stuff.
WriteMakefile(
    'NAME'		=> 'ClearCase::Wrapper',
    'VERSION_FROM'	=> 'Wrapper.pm', # finds $VERSION
    'EXE_FILES'		=> [ qw(cleartool.plx cleartool.dbg) ],
    'PREREQ_PM' => {
	  File::Spec			=> 0.82,
	  Getopt::Long			=> 2.17,
	  ClearCase::Argv		=> 1.06,
	  Argv				=> 1.06,
	  ClearCase::ClearPrompt	=> 1.24,
    },
    'dist' => {
	  DIST_DEFAULT	=> 'all tardist',
	  COMPRESS	=> 'gzip --force --best',
	  TAR		=> 'gtar',
	  TARFLAGS	=> '--mode=u+w -cvf',
    },
);
