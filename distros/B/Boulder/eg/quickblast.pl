#!/usr/local/bin/perl

# do a quick BLAST search a la fasta
use Getopt::Long;
use IO::File;
use File::Basename 'basename','dirname';
use File::Path 'mkpath','rmtree';
use Boulder::Stream;
use Boulder::Blast;
use strict 'vars';
use sigtrap qw(die normal-signals);

use constant BLAST_DEFAULT => 'blastn';
use constant ARGS => '-gapall -hspmax 10';
use constant WUBLAST => '/usr/local/wublast/bin';

use vars qw/$DB $PROGRAM $PARAMS $DIR $STREAM
  $TMPDIR $DELETE_TMPDIR $BOULDER $TABULAR $CUTOFF $MINLEN 
  $target $blast $hit $hsp/;

GetOptions(
	   'tabular!'    => \$TABULAR,
	   'boulder!'    => \$BOULDER,
	   'db=s'        => \$DB,
           'tmp=s'      => \$TMPDIR,
	   'dir=s'      => \$DIR,
	   'program=s'  => \$PROGRAM,
	   'params=s'   => \$PARAMS,
	   'cutoff=f'   => \$CUTOFF,
	   'minlen=f'   => \$MINLEN,
	  ) || die <<USAGE;
Usage: $0 -db <database file> [options] <search file>

Run BLAST on one or more sequences and summarize the results.  The
source database is an ordinary fasta file.  The program runs pressdb
to create a temporary blast database in /usr/tmp (or other location of
TMPDIR).

Options:
       -source  <database>  source fasta database (no default)
       -dir     <path>      Where to save intermediate results in directory (don\'t save)
       -tmp     <temporary directory>
       -program <path>      Variant of BLAST to run (blastn)
       -params  <string>    Parameters to pass to program
       -minlen  <float>     Minimum HSP length, as fraction of total search length (0.0)
       -cutoff  <float>     Minimum significance cutoff
       -tabular             Produce output in tabular format
       -boulder             Produce output in boulder format (default)
USAGE
;

my $WUBLAST = -d WUBLAST ? WUBLAST : dirname(`which blastn`);
die "Can't find blast" unless -x "$WUBLAST/blastn";
my $PRESSDB = "$WUBLAST/pressdb";
my $SETDB   = "$WUBLAST/setdb";
my $DO_UNLINK = 0;

# parameter consistency checking
$TMPDIR  ||= $ENV{TMPDIR} || '/usr/tmp';
$DB      || die "Specify database to search.  Try -h for help.\n";
$PROGRAM ||= BLAST_DEFAULT;
$BOULDER = !$TABULAR if defined $TABULAR;
$BOULDER++ if !defined($BOULDER) && !defined($TABULAR);

$PARAMS = ARGS unless defined $PARAMS;
if ($DIR) {
  die "Specify a valid directory for output files. Try -h for help.\n" unless -d $DIR || mkpath($DIR);
} else {
  $DIR = make_tmpdir();
  $DELETE_TMPDIR++;
}
$CUTOFF   = 0.01 unless defined($CUTOFF);
$MINLEN ||= 0.0;
die "minimum length must be between 0.0 and 1.0"
  unless $MINLEN >= 0.0 && $MINLEN <= 1.0;

$target = pressdb($DB,$PROGRAM);
$STREAM = new Boulder::Stream if $BOULDER;

$|=1;
{ # localize input record
  local($/) = ">";
  while (<>) {
    chomp;
    next unless my($description,@dna) = split("\n");
    my ($identifier) = $description=~/^(\S+)/;
    my $output_file = "$DIR/$identifier.blast";
    my $blast = IO::File->new("| $PROGRAM $target - $PARAMS > $output_file  2>/dev/null ") ||
      die "Couldn't open BLAST program: $!";
    print $blast ">$description\n";
    foreach (@dna) { print $blast $_,"\n"; }
    $blast->close;
    die "Error during execution of blast program, status code $? ($!)\n" if $?;
    summarize_results($output_file);
  }
}

sub summarize_results {
  my $file = shift;
  $blast = Boulder::Blast->parse($file);
  return unless $blast->Blast_hits;

  # this code is called to write out the boulder stream, if requested
  if ($BOULDER) {
    $STREAM->put($blast);
    return;
  }
  
  # if we get here, we're producing the tabular summary

  # find the longest hit
  foreach $hit ($blast->Blast_hits) {
    next unless $hit->Signif < $CUTOFF;
    foreach $hsp ($hit->Hsps) {
      next unless $hsp->Signif < $CUTOFF;
      next unless abs($hsp->Length/$hit->Length) >= $MINLEN;
      write;
    }
  }
}

sub pressdb {
  my $db = shift;
  my $program = shift;

  # see if there's already a suitable database around
  if ($ENV{BLASTDB}) {
    my @paths = split(':',$ENV{BLASTDB});
    foreach (@paths) {
      next unless  -r "$_/$db.csq";
      undef $DO_UNLINK;
      return "$_/$db";
    }
  }

  # find a suitable temporary name
  $target = "$TMPDIR/quickblast${$}aaaa";
  my $tries = 100;
  while (--$tries) {
    last if IO::File->new($target,O_WRONLY|O_EXCL|O_CREAT,0600);
    $target++;
  }
  return unless $tries;
  my $base = basename($db);

  # Convert source file into temporary file for processing
  if ($program =~ /^(blastp|blastx)$/) {
    # setdb is a pain in the a**.  We have to play stupid little
    # tricks to get it to work the way we want it to work
    unless ($db =~ m!^/!) { # resolve relative paths
      require Cwd;
      my $cwd = Cwd::cwd();
      $db = "$cwd/$db";
    }
    unlink $target;
    symlink($db,$target) || die "Couldn't symlink $db=>$target";
    system($SETDB,'-t',$base,$target);
  } else {
    system($PRESSDB,'-o',$target,'-t',$base,$db);
  }
  die "Couldn't make temporary BLAST database: $!" if $?;
  $DO_UNLINK++;
  return $target;
}

sub make_tmpdir {
  my $dir = "$TMPDIR/quickblastout${$}aaaa";
  my $tries = 100;
  while (--$tries) {
    my ($success) = mkpath ($dir++,0,0700);
    return $success if $success;
  }
}

format STDOUT_TOP=
Search                      Target                            Score          P   Len   % Idnty  Search Range      Target Range
.
format STDOUT=
@<<<<<<<<<<<<<<<<<<<<<<<<<<<@<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< @##### @>>>>>>>> @#####   @>>>>   @>>>>>> @>>>>>>  @>>>>>>> @>>>>>>
{
  $blast->Blast_query      ." (".$blast->Blast_query_length.")",
  $hit->Name ." (".$hit->Length.")",
  $hsp->Score,$hsp->Signif,$hsp->Length,
  $hsp->Identity,
  $hsp->Query_start,$hsp->Query_end,
  ($hsp->Orientation eq 'plus' ? ( $hsp->Subject_start,$hsp->Subject_end ) : ( $hsp->Subject_end,$hsp->Subject_start ) )
}
.

# tidy up by removing temporary database
END {  
  if ($target && $DO_UNLINK) {
    unlink $target;
    unlink <$target.*>;
  }
  rmtree ($DIR) if $DIR && $DELETE_TMPDIR;
}

