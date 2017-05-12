#  -*- Perl -*-
# $Id: Makefile.PL,v 1.11 2002/10/10 14:24:58 steiner Exp $

$VERSION = "0.09";		# Module version number

use ExtUtils::MakeMaker;

# we want to be able to read in a non-standard path for kdb5_util
# via the command line.

# Default value if not told otherwise
my $kdb5_util_path = "/usr/local/sbin";

# Parse arguments and remove our special one, setting new path value
my @replacement_args;
foreach (@ARGV) {
  if (/^KDB5_UTIL_PATH=(.+)/) {
      $kdb5_util_path = $1;
      if ($kdb5_util_path =~ m|/kdb5_util$|) {
	  die "Don't include program name in path: $kdb5_util_path\n";
      }
  } else {
    push(@replacement_args, $_);
  }
}
@ARGV = @replacement_args;

# Let the installer know the status of things
print <<"EOP";

The path to kdb5_util has been set to '$kdb5_util_path'.

If this is not where your version of kdb5_util is located, use the
following options to Makefile.PL:

    KDB5_UTIL_PATH=...  To set the directory where kdb5_util is located

For example:

    perl Makefile.PL KDB5_UTIL_PATH=/usr/local/krb5/sbin

EOP

# Add constant definition to Makefile for our path
sub MY::constants {
    package MY;
    my $inherited = shift->SUPER::constants(@_);

    # Define additional constant
    $inherited .= "\nKDB5_UTIL_PATH = $kdb5_util_path\n";

    $inherited;
}

# We need our PL script to be given the above constant as an argument
sub MY::processPL {
    package MY;
    my $inherited = shift->SUPER::processPL(@_);

    # Add Makefile as a dependancy of KDB.pm
    $inherited =~ s{(^KDB.pm\s*::)\s*}
                   {$1 Makefile }m
	or die "Error: no target for KDB.pm in: $inherited";
    
    # Pass an extra argument to KDB_pm.PL.
    $inherited =~ s{(^\s+\$\(PERL(?:RUNINST)?\).*KDB_pm.PL\b)}
                   {$1 KDB5_UTIL_PATH=\$\(KDB5_UTIL_PATH\)}m
	or die "Error: no call to KDB_pm.PL in: $inherited";

    $inherited;
}

# Make sure that KDB.pm gets added to the list of PM files (it probably won't
#  exist at the time the list of PM files are generated.
# We need to do this since we can't easily add an additional file to the
#  list below.
# Also make sure MAN3POD includes this module.
sub MY::post_initialize {
    my ($self) = @_;
    my $name = 'KDB.pm';
    my $manname = $name;

    # need to add KDB.pm to PM files
    $self->{PM}->{$name} = $self->catfile('$(INST_LIBDIR)', $name);

    # also also to MAN3POD
    $manname = $self->catfile(split(/::/,$self->{PARENT_NAME}), $manname);
    $manname =~ s/\.p(od|m|l)$//;
    $manname = $self->replace_manpage_separator($manname);
    $self->{MAN3PODS}->{$name} = $self->catfile('$(INST_MAN3DIR)',"$manname.\$(MAN3EXT)");

    "";
}

# Now finally write out the Makefile
WriteMakefile(
    'NAME'	=> 'Authen::Krb5::KDB',
    'VERSION'   => $VERSION,
    'PREREQ_PM' => { 'Carp' => 0, 'POSIX' => 0 },
    'PL_FILES'  => { 'KDB_pm.PL' => 'KDB.pm' },
#    'PM'        => { 'KDB.pm' => '$(INST_LIBDIR)/KDB.pm' },
    'dist'      => {
	COMPRESS => 'gzip',
	suffix   => 'gz',
	DIST_DEFAULT => 'd/KDB.pm tardist',
    },
    'clean'     => { FILES => 'KDB.pm' },
);

sub MY::postamble {
    my $TARG = MM->catfile('d', 'KDB.pm');
    qq!$TARG : KDB.in
	\$(PERL) gen_dummy_kdb_pm.plx
!
}
