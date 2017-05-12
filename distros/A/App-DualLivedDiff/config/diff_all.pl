#!/usr/bin/env perl
use strict;
use warnings;
use Getopt::Long;
use File::Spec;
use File::Path ();
use File::Temp ();
use DBM::Deep;
use IPC::Cmd ();

my $dualLivedDiffCmd = 'dualLivedDiff';

sub usage {
  my $msg = shift;
  warn "$msg\n" if defined $msg;

  warn <<HERE;
Usage: $0 --blead path/to/blead --dir path/to/dir/with/config --outfile path/to/output
HERE
  exit(1);
}

my ($confDir, $outFile, $bleadPath, $reverse);
GetOptions(
  'h|help' => \&usage,
  'd|dir|directory=s' => \$confDir,
  'o|outfile=s' => \$outFile,
  'b|blead=s' => \$bleadPath,
  'r|reverse' => \$reverse,
);

usage("Could not find configuration directory") 
  if not defined $confDir or not -d $confDir;
usage()
  if not defined $outFile;
usage("Blead perl path does not exist")
  if not defined $bleadPath or not -d $bleadPath;


my $db = DBM::Deep->new( $outFile );


my @confDirs;
{
  opendir(my $dh, $confDir) or die $!;
  @confDirs =
    grep {-d File::Spec->catdir($confDir, $_)}
    grep {!/^\.\.?$/}
    grep {!/^\.svn$/}
    readdir $dh;
  closedir $dh;
}

foreach my $conf (sort @confDirs) {
  my $confFile = File::Spec->catfile($confDir, $conf, '.dualLivedDiffConfig');

  my $modname  = $conf;
  $modname =~ s/-/::/g;
  print STDERR "modname: $modname";

  if (not -f $confFile) {
    warn "Config file for $modname does not exist ($confFile)!\n";
    next;
  }
  
  my ($tempFH, $tmpOutFile) = File::Temp::tempfile(
    "dldiffTmpXXXXXX",
    UNLINK => 0,
    DIR => File::Spec->tmpdir(),
    EXLOCK => 0,
  );

  my $outBuffer;
  my @cmd = (
    $dualLivedDiffCmd,
    ($reverse ? ('-r') : ()),
    '-b', $bleadPath,
    '-o', $tmpOutFile,
    '-d', $modname,
    '-c', $confFile,
    '-w',
  );
  my $res = IPC::Cmd::run(
    command => \@cmd,
    buffer => \$outBuffer,
  );

  if (!$res) {
    unlink $tmpOutFile;
    warn "Error running dualLivedDiff: '$outBuffer'!";
    next;
  }

  $outBuffer =~ /Found the '([^']+)' distribution on CPAN/i or die;
  my $dist = $1;

  seek $tempFH, 0, 0;
  my $diff = join '', <$tempFH>;
  my $isDiff = ($diff =~ /\S/);
  close $tempFH;

  #$db->begin_work;

  $db->{$dist} = {
    name => $dist,
    diff => $diff,
    status => ($isDiff ? 'not ok' : 'ok'),
    cmd => \@cmd,
    module => $modname,
    date => time(),
    config => do {open my $fh, '<', $confFile or die $!; local $/ = undef; <$fh>},
  };

  #$db->rollback;
  #$db->commit;

  warn " - " . uc($db->{$dist}{status}) . "\n";

}



