# Makefile.PL -- Makefile for makepatch
# Author          : Ulrich Pfeifer
# Created On      : Mon Feb 17 10:51:47 1997
# Last Modified By: Johan Vromans
# Last Modified On: Fri Oct 26 21:47:10 2012
# Update Count    : 107
# Status          : Released

# Verify perl version.
require 5.004;

# Verify CORE modules.
use Getopt::Long 2.00;
use IO qw(File);
use File::Basename;
use File::Spec;
use Config;

use ExtUtils::MakeMaker;

# WriteMakefile parameter hash.
my %p = ( NAME => 'Alt::App::makepatch', VERSION => "2.05" );

# Extra info for newer versions.
if ( $[ >= 5.005 ) {
    $p{AUTHOR} = 'Johan Vromans (jvromans@squirrel.nl)';
    $p{ABSTRACT} = 'patchkit generate and apply tool';
}

# Scripts.
my @scripts = qw (makepatch applypatch);

my $usrbin = "/usr/bin";
my $installscript = $Config{installscript};

print STDERR ("\n",
	      "WARNING: This Makefile will install user accessible scripts.\n");
print STDERR ("The location for these scripts is $installscript.\n")
  unless $installscript eq $usrbin;

print STDERR ("You may consider to pass INSTALLSCRIPT=$usrbin (or some other\n",
	      "convenient location) to \"make install\".\n\n");

if ( $^O eq "solaris" ) {
    print STDERR <<EOD;

I see you're running Solaris.
The Solaris version of the 'patch' program is extremely buggy.
If the 'make test' command fails with a message

  patch: Line must begin with '+ ', '  ', or '! '.

you must install a better version of 'patch', for example, GNU patch.

EOD
}

my $TMPDIR = $ENV{TMPDIR} || $ENV{TEMP};
$TMPDIR = File::Spec->tmpdir if !$TMPDIR && File::Spec->can("tmpdir");
$TMPDIR ||= "/usr/tmp";
unless ( -d $TMPDIR && -w $TMPDIR ) {
print STDERR <<EOD;
The default location for temporary files ($TMPDIR) does not
exist, or is not accessible.
You must use environment variable TMPDIR or TEMP to designate a writable
directory to hold temporary files.
EOD
    die ("Cannot continue\n");
}


=ignore

# Included modules.
my @mods = ();

# Required modules that are included in this kit for convenience.
# Syntax and semantics like PREREQ_PM.
my %req = ( Text::Filter => 0,
	    Text::Diff   => 0,
	    Text::Patch  => 0,
	  );

# Check modules, and ask to install them now.
$p{PREREQ_PM} = {};

foreach ( sort keys %req ) {
    my $mod = $_;
    my $rev = $req{$mod};
    my $eval = "use $mod $rev";
    eval $eval;
    if ( $@ ) {
	print STDERR ("\nI need the $mod package",
		      ($rev ? ", version $rev or higher" : ""), ".\n",
		      "Shall I install it for you? ");
	my $ans = <STDIN>;
	if ( $ans =~ /^y/i ) {
	    $mod =~ s/::/\//g;
	    push (@mods, "$mod.pm");
	}
	else {
	    # Have MakeMaker complain.
	    $p{PREREQ_PM}->{$mod} = 0;
	}
    }
}

=cut

# Append scripts and modules to WriteMakefile args.
$p{EXE_FILES} = [ map { "script/$_" } @scripts ];
foreach ( @mods ) {
    $p{PM}->{"lib/$_"} = '${INST_LIBDIR}'."/$_";
}

# Write the Makefile.
WriteMakefile (%p);
