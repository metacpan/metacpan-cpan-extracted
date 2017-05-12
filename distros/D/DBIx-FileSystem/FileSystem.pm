#
# DBIx::FileSystem;
#
# Manage database tables with a simulated filesystem shell environment
#
# Mar 2003    Alexander Haderer
#
# License:
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
#
# Last Update:		$Author: marvin $
# Update Date:		$Date: 2007/12/13 15:06:46 $
# Source File:		$Source: /home/cvsroot/tools/FileSystem/FileSystem.pm,v $
# CVS/RCS Revision:	$Revision: 1.22 $
# Status:		$State: Exp $
#

package DBIx::FileSystem;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS );
use Exporter;

# for access class: return results
use constant OK     => 0;	# everything ok
use constant NOFILE => 1;	# file not found in db
use constant NFOUND => 2;	# more than one entry found
use constant ERROR  => 3;	# nothing found, errorstring set

$DBIx::FileSystem::VERSION = '1.7';

@ISA = qw( Exporter );
@EXPORT = qw( );
@EXPORT_OK = qw(
	     &recreatedb
	     &mainloop
	      OK
	      NOFILE
	      NFOUND
	      ERROR
	     );
%EXPORT_TAGS = ( symbols => [ qw( OK NOFILE NFOUND ERROR ) ] );

use vars qw( $OUT $vwd $dbh );

use DBI;
use Term::ReadLine;
use POSIX qw{tmpnam};

use Fcntl;

########################################################################
########################################################################
## classical interface: the shell
########################################################################
########################################################################



########################################################################
# c o m m a n d s
########################################################################
my %commands =
  ('cd'=> 	{ func => \&com_cd,
		  doc => "change to directory: 'cd DIR'" },
   'help' => 	{ func => \&com_help,
		  doc => "display help text: 'help [command]'" },
   'quit' => 	{ func => \&com_quit,
		  doc => "quit it" },
   'ls' => 	{ func => \&com_ls,
		  doc => "list dirs and files" },
   'ld'=> 	{ func => \&com_ld,
		  doc => "list long dirs and files with comments" },
   'll' => 	{ func => \&com_ll,
		  doc => "list long files with comments" },
   'rm' => 	{ func => \&com_rm,
		  doc => "remove file: 'rm FILE'" },
   'cp' => 	{ func => \&com_cp,
		  doc => "copy file: 'cp OLD NEW'" },
   'cat' => 	{ func => \&com_cat,
		  doc => "show contents of a file: 'cat FILE'" },
   'sum' => 	{ func => \&com_sum,
		  doc => "show summary of a file: 'sum FILE'" },
   'vi' => 	{ func => \&com_vi,
		  doc => "edit/create a file: 'vi FILE'" },
   'ver' => 	{ func => \&com_ver,
		  doc => "show version" },
   'vgrep' => 	{ func => \&com_vgrep,
		  doc => "grep var/value pairs in all files: vgrep PATTERN" },
   'wrefs' => 	{ func => \&com_wref,
		  doc => "show who references a file: 'wrefs FILE'" },
  );


########################################################################
# C o n s t a n t s
########################################################################

# for ls output
my $NUM_LS_COL = 4;
my $LS_COL_WIDTH = 16;
my $EDITOR = $ENV{EDITOR};
$EDITOR = "/usr/bin/vi" unless $EDITOR;


########################################################################
# m a i n
#
# input:
#  vdirs:	reference to vdir hash
#  PRG:		program name for the shell-program
#  VERSION	four digit version string for program/database version
#  DBCONN	DBI connect string for the database
#  DBUSER       database user
#
# returns nothing
########################################################################

my $vdirs;	# reference to vdir hash
# $vwd ;	# current virtual working directory (exported)

# my $dbh;	# database handle (exported)
my $term;
# $OUT;		# the stdout (exported)

my $DBCONN;	# DBI database connect string
my $DBUSER;	# DBI database user
my $DBPWD;	# DBI password
my $VERSION;

my $PRG;	# program name of the shell


sub mainloop(\%$$$$$\%) {

  my $customcmds;
  ($vdirs,$PRG,$VERSION,$DBCONN,$DBUSER,$DBPWD,$customcmds) = @_;

  # merge custom commands, if any
  if( defined $customcmds ) {
    foreach my $cucmd (keys (%{$customcmds} ) ) {
      if( defined $commands{$cucmd} ) {
	die "$PRG: redefinition of command '$cucmd' by customcommands";
      }
      unless( defined $customcmds->{$cucmd}{func} ) {
	die "$PRG: customcommand '$cucmd': elem func not set";
      }
      unless( defined $customcmds->{$cucmd}{doc} ) {
	die "$PRG: customcommand '$cucmd': elem doc not set";
      }
      $commands{$cucmd} = $customcmds->{$cucmd};
    }
  }

  # connect to db
  ($dbh = DBI->connect( $DBCONN, $DBUSER, $DBPWD,
     {ChopBlanks => 1, AutoCommit => 1, PrintError => 0})) 
     || die "$PRG: connect to '$DBCONN' failed:\n", $DBI::errstr;

  # check vdirs
  if( check_vdirs_struct() ) {
    $dbh->disconnect || die "$PRG: Disconnect failed. Reason: ", $DBI::errstr;
    die "$PRG: check 'vdirs' structure in $PRG\n";
  }

  # check database
  if( check_db_tables() ) {
    $dbh->disconnect || die "$PRG: Disconnect failed. Reason: ", $DBI::errstr;
    die "$PRG: database wrong: run '$PRG recreatedb' to recreate tables\n";
  }

  # readline settings
  $term = new Term::ReadLine 'dbshell console';
  $OUT = $term->OUT || \*STDOUT;
  $term->ornaments( 0 );
  $term->Attribs->{attempted_completion_function} = \&dbshell_completion;

  my $line;	# command line
  my $cmd;	# the command 
  my @arg;	# the command's parameters

  my $prompttemplate = "$PRG (/%s): ";
  my $prompt = sprintf( $prompttemplate, $vwd );

  # the loop
  while ( defined ($line = $term->readline($prompt)) ) {
    # remove whitespace
    $line =~ s/^\s*//;
    $line =~ s/\s*//;
    ($cmd, @arg ) = split( ' ', $line );
    next unless defined $cmd;
    
    my $command = $commands{$cmd};
    if( defined $command ) {
      last if &{$command->{func}}( @arg );
    }else{
      print $OUT "unknown command '$cmd', try 'help'\n";
    }
    $prompt = sprintf( $prompttemplate, $vwd );
  }
  $dbh->disconnect || die "$PRG: Disconnect failed. Reason: ", $DBI::errstr;
  return;
}


sub recreatedb(\%$$$$$) {

  ($vdirs,$PRG,$VERSION,$DBCONN,$DBUSER,$DBPWD) = @_;

  # connect to db
  ($dbh = DBI->connect( $DBCONN, $DBUSER, $DBPWD,
     {ChopBlanks => 1, AutoCommit => 1, PrintError => 0})) 
     || die "$PRG: connect to '$DBCONN' failed:\n", $DBI::errstr;

  # check vdirs
  if( check_vdirs_struct() ) {
    die "$PRG: check 'vdirs' structure in $PRG\n";
  }

  recreate_db_tables();

  $dbh->disconnect || die "$PRG: Disconnect failed. Reason: ", $DBI::errstr;
  return;
}


########################################################################
# c o m m a n d   f u n c t i o n s
########################################################################

########################################################################
# com_help()
#
sub com_help() {
  my $arg = shift;
  if( defined $arg ) {
    if( defined $commands{$arg} ) {
      print $OUT "$arg\t$commands{$arg}->{doc}\n";
    }else{
      print $OUT "no help for '$arg'\n";
    }
  }else{
    foreach my $i (sort keys(%commands) ) {
      print $OUT "$i\t$commands{$i}->{doc}\n";
    }
  }
  return 0;
}

########################################################################
# com_ls()
#
sub com_ls() {
  my @files;
  my $i;

  my $x = shift;
  if( defined $x ) {
    print $OUT "ls: usage: $commands{ls}->{doc}\n";
    return 0;
  }

  # get dirs
  foreach $i (sort keys(%{$vdirs}) ) {
    push @files, "($i)";
  }

  # get files
  if( length($vwd) ) {
    my $st;
    my $col = $vdirs->{$vwd}{fnamcol};
    $st = $dbh->prepare("select $col from $vwd order by $col");
    unless( $st ) {
      print $OUT "$PRG: can't prepare ls query '$vwd':\n  " . $dbh->errstr;
      return 0;
    }
    unless( $st->execute() ) {
      print $OUT "$PRG: can't exec ls query '$vwd':\n  " . $dbh->errstr;
      return 0;
    }
    while( $i = $st->fetchrow_array() ) {
      push @files, "$i";
    }
    $st->finish();
  }

  # show it
  my $numrow = int( $#files / $NUM_LS_COL ) + 1;
  my $r = 0;
  my $c = 0;
  my $placeh = $LS_COL_WIDTH - 2;
  for( $r=0; $r<$numrow; $r++ ) {
    for( $c=0; $c<$NUM_LS_COL; $c++ ) {
      $i = $c*$numrow+$r;
      printf $OUT "%-${placeh}s  ", $files[$i] if $i <= $#files;
    }
    print $OUT "\n";
  }
  return 0;
}

########################################################################
# com_ld()
#
sub com_ld() {
  my @files;
  my @com;	# comments
  my $i;
  my $x = shift;
  if( defined $x ) {
    print $OUT "ls: usage: $commands{ld}->{doc}\n";
    return 0;
  }

  # get dirs
  foreach $i (sort keys(%{$vdirs}) ) {
    push @files, "($i)";
    push @com, $vdirs->{$i}{desc};
  }

  # show it
  my $maxlen = 0;
  foreach $i (@files) {
    if( length($i) > $maxlen ) {$maxlen = length($i); }
  }

  for( $i=0; $i<=$#files; $i++ ) {
    printf $OUT "%-${maxlen}s| %s\n", $files[$i], $com[$i];
  }
  print $OUT "\n";
  com_ll();
  return 0;
}

########################################################################
# com_ll()
#
sub com_ll() {
  my @files;
  my @com;	# comments
  my $i;
  my $c;

  my $x = shift;
  if( defined $x ) {
    print $OUT "ls: usage: $commands{ll}->{doc}\n";
    return 0;
  }

  # get files
  if( defined $vdirs->{$vwd}{comcol} ) {
    my $comcol = $vdirs->{$vwd}{comcol};
    my $col = $vdirs->{$vwd}{fnamcol};
    my $st;
    $st = $dbh->prepare("select $col, $comcol from $vwd order by $col");
    unless( $st ) {
      print $OUT "$PRG: can't prepare ll query '$vwd':\n  " . $dbh->errstr;
      return 0;
    }
    unless( $st->execute() ) {
      print $OUT "$PRG: can't exec ll query '$vwd':\n  " . $dbh->errstr;
      return 0;
    }
    while( ($i,$c) = $st->fetchrow_array() ) {
      $c = "" unless defined $c;
      push @files, "$i";
      push @com, "$c";
    }
    $st->finish();
  }else{
    my $st;
    my $col = $vdirs->{$vwd}{fnamcol};
    $st = $dbh->prepare("select $col from $vwd order by $col");
    unless( $st ) {
      print $OUT "$PRG: can't prepare ls query '$vwd':\n  " . $dbh->errstr;
      return 0;
    }
    unless( $st->execute() ) {
      print $OUT "$PRG: can't exec ls query '$vwd':\n  " . $dbh->errstr;
      return 0;
    }
    while( $i = $st->fetchrow_array() ) {
      push @files, "$i";
      push @com, "";
    }
    $st->finish();
  }

  # show it
  my $maxlen = 0;
  foreach $i (@files) {
    if( length($i) > $maxlen ) {$maxlen = length($i); }
  }

  for( $i=0; $i<=$#files; $i++ ) {
    printf $OUT "%-${maxlen}s| %s\n", $files[$i], $com[$i];
  }
  return 0;
}

########################################################################
# com_cd()
#
sub com_cd() {
  my ($arg,$x) = @_;
  if( defined $arg and !defined $x) {
     if( exists $vdirs->{$arg} ) {
       $vwd = "$arg";
     }else{
       print $OUT "no such directory '$arg'\n";
     }
  }else{
    print $OUT "cd: usage: $commands{cd}->{doc}\n";
  }
  return 0;
}


########################################################################
# com_quit()
#
sub com_quit() {
  return 1;
}

########################################################################
# com_ver()
#
sub com_ver() {
  print $OUT "   DBIx-FileSystem Version: $DBIx::FileSystem::VERSION\n";
  print $OUT "   $PRG \%vdirs version: $VERSION\n";
  return 0;
}

########################################################################
# com_rm()
#
sub com_rm() {
  my $r;
  my ($arg,$x) = @_;
  if( defined $arg and !defined $x ) {
    if( $vdirs->{$vwd}{edit} ) {
      if( $vdirs->{$vwd}{defaultfile} and $vdirs->{$vwd}{defaultfile} eq $arg ) {
	print $OUT "rm: error: cannot remove default file '$arg'\n";
      }else{
	my @reffiles = get_who_refs_me( $vwd, $arg );
	if( $#reffiles == -1 ) {
	  my $rmerr;
	  if( exists $vdirs->{$vwd}{rmcheck} ) {
	    $rmerr = &{$vdirs->{$vwd}->{rmcheck}}( $vwd, $arg, $dbh);
	  }
	  if( defined $rmerr ) {
	    print $OUT "rm: cannot remove: $rmerr\n";
	  }else{
	    my $fnc = $vdirs->{$vwd}{fnamcol};
	    $r = $dbh->do( "delete from $vwd where $fnc='$arg'");
	    if( !defined $r ) { 
	      print $OUT "rm: database error:\n" . $dbh->errstr;
	    }elsif( $r==0 ) { 
	      print $OUT "rm: no such file '$arg'\n";
	    }
	  }
	}else{
	  print $OUT "rm: cannot remove: file '$arg' referenced by:\n  ";
	  print $OUT join( "\n  ", @reffiles );
	  print $OUT "\n";
	}
      }
    }else{
      print $OUT "rm: error: read only directory '/$vwd'\n";
    }
  }else{
    print $OUT "rm: usage: $commands{rm}{doc}\n";
  }
  return 0;
}


########################################################################
# com_cp()
#
sub com_cp() {
  my $r;
  my ($old,$new,$x) = @_;
  if( defined $old and defined $new and !defined $x) {
    if( $vdirs->{$vwd}{edit} ) {
      my $fnc = $vdirs->{$vwd}{fnamcol};
      if( (length($new)<=$vdirs->{$vwd}{cols}{$fnc}{len}) and !($new=~/\W+/)) {
	my $fnc = $vdirs->{$vwd}{fnamcol};
	my $insert = "insert into $vwd (";
	my $select = "select ";
	my $cols   = $vdirs->{$vwd}{cols};
	foreach my $col (sort keys(%{$cols}) ) {
	  $insert .= "$col,";
	  if( $col eq $fnc ) {
	    $select .= "'$new',";
	  }elsif( exists $vdirs->{$vwd}{cols}{$col}{uniq} ) {
	    $select .= "NULL,";
	  }else{
	    $select .= "$col,";
	  }
	}
	chop $insert;
	chop $select;
	$insert .= ")";
	$select .= " from $vwd where $fnc='$old'";
	$r = $dbh->do( "$insert $select");
	if( !defined $r or $r!=1 ) { 
	  print "cp: error: no file '$old' or file '$new' exists\n"; 
	}
      }else{
	print $OUT "cp: error: illegal or to long filename '$new'\n";
      }
    }else{
      print $OUT "cp: error: read only directory '/$vwd'\n";
    }
  }else{
    print $OUT "cp: usage: $commands{cp}{doc}\n";
  }
  return 0;
}


########################################################################
# com_sum()
#
sub com_sum() {
  my ($arg,$x) = @_;
  if( defined $arg and !defined $x ) {
    if( print_file( $OUT, $arg, 0 ) == 1 ) {
      print $OUT "sum: no such file '$arg'\n";
    }
  }else{
    print $OUT "sum: usage: $commands{sum}{doc}\n";
  }
  return 0;
}

########################################################################
# com_cat()
#
sub com_cat() {
  my ($arg,$x) = @_;

  if( defined $arg and !defined $x ) {
    if( print_file( $OUT, $arg, 1 ) == 1 ) {
      print $OUT "cat: no such file '$arg'\n";
    }
  }else{
    print $OUT "cat: usage: $commands{cat}{doc}\n";
  }
  return 0;
}

########################################################################
# com_vi()
#
sub com_vi() {
  my ($arg,$x) = @_;
  my $tmpf;
  my $tmpf_mtime;
  my $r;	# 0: file printed exists / create update SQL string
  	;	# 1: file printed did not exist / create insert SQL string
  my $err;
  my $sql;
  my $ln = 1;		# line number where editor starts

  if( defined $arg and !defined $x ) {
    if( $vdirs->{$vwd}{edit} ) {
      my $fnc = $vdirs->{$vwd}{fnamcol};
      if( (length($arg)<=$vdirs->{$vwd}{cols}{$fnc}{len}) and !($arg=~/\W+/)) {
	while( 1 ) { $tmpf = tmpnam();
		     sysopen( FN, $tmpf, O_RDWR | O_CREAT | O_EXCL ) && last; }
	$r = print_file( \*FN, $arg, 2 );
	close( FN );
	$tmpf_mtime = (stat $tmpf)[9];	# remember mtime of tempfile
	if( $r==0 or $r==1 ) {
	  while( 1 ) {
	    system( "$EDITOR +$ln $tmpf" );
	    ($ln,$err,$sql) = create_sql_from_file( $tmpf, $vwd, $arg, $r );
	    if( defined $err ) {
	      my $inp = want_to_edit_again( $err );
	      next if $inp eq 'y';
	      last if $inp eq 'n';
	    }
	    ### print $OUT ">>>$sql<<<\n";	######### hierhierhier
	    if( length($sql) and $tmpf_mtime != (stat $tmpf)[9] ) {
	      my $res = $dbh->do( $sql );
	      if( !defined $res ) {
		my $inp=want_to_edit_again( "save to database:\n".$dbh->errstr);
		if($inp eq 'y') { $ln = 1; next; }
	      }elsif( $res == 0 ) {
		print $OUT "\n\n\n\n\nvi: nothing saved\n";
	      }
	    }else{
	      print $OUT "\n\n\n\n\nvi: nothing saved\n";
	    }
	    last;
	  }
	}else{
	  print $OUT "vi: no such file '$arg'\n";
	}
	unlink( $tmpf );
      }else{
	print $OUT "vi: error: illegal or too long filename '$arg'\n";
      }
    }else{
      print $OUT "vi: error: read only directory '/$vwd'\n";
    }
  }else{
    print $OUT "vi: usage: $commands{vi}{doc}\n";
  }
  return 0;
}

########################################################################
# com_wref()
#
sub com_wref() {
  my ($arg,$x) = @_;
  if( defined $arg and !defined $x ) {
    my @reffiles = get_who_refs_me( $vwd, $arg );
    if( $#reffiles > -1 ) {
      print $OUT join( "\n", @reffiles );
      print $OUT "\n";
    }else{
      print $OUT "wrefs: no one references '$arg'\n";
    }
  }else{
    print $OUT "wrefs: usage: $commands{wrefs}{doc}\n";
  }
  return 0;
}

########################################################################
# com_vgrep()
#
sub com_vgrep() {
  my ($arg,$x) = @_;
  if( defined $arg and !defined $x ) {
    do_vgrep( $arg );
  }else{
    print $OUT "vgrep: usage: $commands{vgrep}{doc}\n";
  }
  return 0;
}






########################################################################
# c o m p l e t i o n 
########################################################################

# from p5-ReadLine example 'FileManager'

# Attempt to complete on the contents of TEXT.  START and END bound
# the region of rl_line_buffer that contains the word to complete.
# TEXT is the word to complete.  We can use the entire contents of
# rl_line_buffer in case we want to do some simple parsing.  Return
# the array of matches, or NULL if there aren't any.
sub dbshell_completion {
  my ($text, $line, $start, $end) = @_;
  
  my @matches = ();

  # If this word is at the start of the line, then it is a command
  # to complete.  Otherwise it is the name of a file in the current
  # directory.
  if ($start == 0) {
    @matches = $term->completion_matches($text, \&command_generator);
  }elsif($line =~ /^cd\s.*/ ) {
    @matches = $term->completion_matches($text, \&vdir_generator);
  }else{
    @matches = $term->completion_matches($text, \&vfile_generator);
  }

  return @matches;
}

# from p5-ReadLine example 'FileManager'
# Generator function for command completion.  STATE lets us know
# whether to start from scratch; without any state (i.e. STATE == 0),
# then we start at the top of the list.

## Term::ReadLine::Gnu has list_completion_function similar with this
## function.  I defined new one to be compared with original C version.
{
  my $list_index;
  my @name;

  sub command_generator {
    my ($text, $state) = @_;
    $text =~ s/\./\\\./g;
    $text =~ s/\*/\\\*/g;
    $text =~ s/\[/\\\[/g;
    $text =~ s/\]/\\\]/g;
    $text =~ s/\$/\\\$/g;
    $text =~ s/\^/\\\^/g;

    # If this is a new word to complete, initialize now.  This
    # includes saving the length of TEXT for efficiency, and
    # initializing the index variable to 0.
    unless ($state) {
      $list_index = 0;
      @name = keys(%commands);
    }

    # Return the next name which partially matches from the
    # command list.
    while ($list_index <= $#name) {
      $list_index++;
      return $name[$list_index - 1]
	if ($name[$list_index - 1] =~ /^$text/);
    }
    # If no names matched, then return NULL.
    return undef;
  }
}

{
  my $list_index;
  my @name;

  sub vdir_generator {
    my ($text, $state) = @_;
    $text =~ tr/a-zA-Z0-9_\///cd;
    $text =~ s/\./\\\./g;
    $text =~ s/\*/\\\*/g;
    $text =~ s/\[/\\\[/g;
    $text =~ s/\]/\\\]/g;
    $text =~ s/\$/\\\$/g;
    $text =~ s/\^/\\\^/g;
    
    # If this is a new word to complete, initialize now.  This
    # includes saving the length of TEXT for efficiency, and
    # initializing the index variable to 0.
    unless ($state) {
      $list_index = 0;
      @name = keys(%{$vdirs});
    }

    # Return the next name which partially matches 
    while ($list_index <= $#name) {
      $list_index++;
      return $name[$list_index - 1]
	if ($name[$list_index - 1] =~ /^$text/);
    }
    # If no names matched, then return NULL.
    return undef;
  }
}

{
  my $list_index;
  my @name;

  sub vfile_generator {
    my ($text, $state) = @_;
    $text =~ tr/a-zA-Z0-9_\///cd;
    $text =~ s/\./\\\./g;
    $text =~ s/\*/\\\*/g;
    $text =~ s/\[/\\\[/g;
    $text =~ s/\]/\\\]/g;
    $text =~ s/\$/\\\$/g;
    $text =~ s/\^/\\\^/g;

    unless ($state) {
      undef @name;
      $list_index = 0;
      my $st;
      my $col = $vdirs->{$vwd}{fnamcol};
      $st = $dbh->prepare("select $col from $vwd order by $col");
      unless( $st ) {
	print $OUT "$PRG: prep completion query '$vwd':\n  " . $dbh->errstr;
	return undef;
      }
      unless( $st->execute() ) {
	print $OUT "$PRG: exec completion query '$vwd':\n  " . $dbh->errstr;
	return undef;
      }
      my $i;
      while( $i = $st->fetchrow_array() ) {
	push @name, $i;
      }
      $st->finish();
    }

    # Return the next name which partially matches 
    while ($list_index <= $#name) {
      $list_index++;
      return $name[$list_index - 1]
	if ($name[$list_index - 1] =~ /^$text/);
    }
    # If no names matched, then return NULL.
    return undef;
  }
}

########################################################################
# c h e c k i n g  &  c r e a t i o n
########################################################################

########################################################################
# check_vdirs_struct()
#
sub check_vdirs_struct() {
  my $pre = "internal error: vdirs structure:\n ";
  foreach my $dir (keys(%{$vdirs}) ) {
    # init refby: 
    # a hash holding the dir (key) and list of columns (value) this dir 
    # is referenced by. Will be set up 57 lines later (# setup refby)
    $vdirs->{$dir}->{refby} = {};
  }

  foreach my $dir (sort keys(%{$vdirs}) ) {
    $vwd = $dir unless defined $vwd; # set $vwd to alphabetic first dir 

    unless( defined $vdirs->{$dir}->{desc}) {
      print "$pre dir '$dir': 'desc' missing\n";
      return 1;
    }
    unless( defined $vdirs->{$dir}->{edit}) {
      print "$pre dir '$dir': 'edit' missing\n";
      return 1;
    }

    unless( defined $vdirs->{$dir}->{cols}) {
      print "$pre dir '$dir': 'cols' missing\n";
      return 1;
    }

    unless( defined $vdirs->{$dir}->{refby}) {
      print "$pre dir '$dir': 'refby' missing \n";
      return 1;
    }

    my $fnamcol = $vdirs->{$dir}{fnamcol};
    unless( defined $fnamcol) {
      print "$pre dir '$dir': 'fnamcol' missing\n";
      return 1;
    }
    unless( defined $vdirs->{$dir}{cols}{$fnamcol} ) {
      print "$pre dir '$dir', fnamcol set to '$fnamcol', but column missing\n";
      return 1;
    }
    if( $vdirs->{$dir}{cols}{$fnamcol}{type} ne 'char' ) {
      print "$pre dir '$dir', fnamcol-column '$fnamcol' type must be 'char'\n";
      return 1;
    }
    if( $vdirs->{$dir}{edit} == 1 ) {
      unless( defined $vdirs->{$dir}{cols}{$fnamcol}{len} ) {
	print "$pre dir '$dir', fnamcol-column '$fnamcol': missing 'len'\n";
	return 1;
      }
    }
    if( $vdirs->{$dir}{cols}{$fnamcol}{len} + 2 > $LS_COL_WIDTH ) {
      my $maxlen = $LS_COL_WIDTH - 2;
      print "$pre dir '$dir', fnamcol-column '$fnamcol' len > $maxlen\n";
      return 1;
    }

    my $comcol = $vdirs->{$dir}{comcol};
    if( defined $comcol) {
      unless( defined $vdirs->{$dir}{cols}{$comcol} ) {
	print "$pre dir '$dir', comcol set to '$comcol', but column missing\n";
	return 1;
      }
      if( $vdirs->{$dir}{cols}{$comcol}{type} ne 'char' ) {
	print "$pre dir '$dir', comcol-column '$comcol' type must be 'char'\n";
	return 1;
      }
      unless( defined $vdirs->{$dir}{cols}{$comcol}{len} ) {
	print "$pre dir '$dir', comcol-column '$comcol': missing 'len'\n";
	return 1;
      }
    }

    my %varnames = ();	# duplicate check: key=varname  value=column name
    my $cols = $vdirs->{$dir}{cols};
    foreach my $col (keys(%{$cols} )) {
      # check for deprecated 'delcp' option
      if( exists $cols->{$col}{delcp} ) {
	$cols->{$col}{uniq} = 1;
	print "\nWARNING: $PRG: internal vdirs struct:\n   dir '$dir', column '$col', option 'delcp' deprecated, use 'uniq'\n\n";
      }

      # check for 'type' / 'ref'
      unless( defined $cols->{$col}{type} || defined $cols->{$col}{ref} ) {
	print "$pre dir '$dir', column '$col', either 'type' or 'ref' must be set\n";
	return 1;
      }
      if( defined $cols->{$col}{ref} and !defined $vdirs->{$cols->{$col}{ref}}){
	print "$pre dir '$dir', column '$col', elem 'ref': no dir '$cols->{$col}{ref}'\n"; 
	return 1;
      }

      # check for flags
      if( exists $cols->{$col}{flags} ) {
	if(  $cols->{$col}{type} ne 'int' ) {
	  print "$pre dir '$dir', column '$col', when using 'flags' type must be 'int'\n";
	  return 1;
	}
	unless( ref( $cols->{$col}{flags} ) eq "HASH" ) {
	  print "$pre dir '$dir', column '$col', 'flags' must be a hash\n";
	  return -1;
	}
	foreach my $i (sort keys(%{$cols->{$col}{flags} }) ) {
	  if( $i =~ /\D/ ) {
	    print "$pre dir '$dir', column '$col', flags: bitno must be an int\n";
	    return 1;
	  }
	  unless( ref( $cols->{$col}{flags}{$i} ) eq "ARRAY" ) {
	    print "$pre dir '$dir', column '$col', bitno '$i': missing array with flagname + flagdescritpion\n";
	    return -1;
	  }
	  unless( defined $cols->{$col}{flags}{$i}->[0] ) {
	    print "$pre dir '$dir', column '$col', bitno '$i': missing flagname\n";
	    return -1;
	  }
	  if( $cols->{$col}{flags}{$i}->[0] =~ / / ) {
	    print "$pre dir '$dir', column '$col', bitno '$i': flagname must be a single word\n";
	    return -1;
	  }
	  unless( defined $cols->{$col}{flags}{$i}->[1] ) {
	    print "$pre dir '$dir', column '$col', bitno '$i': missing flagdescription\n";
	    return -1;
	  }
	}
      }

      # check for enums
      if( exists $cols->{$col}{enums} ) {
	if(  $cols->{$col}{type} ne 'int' ) {
	  print "$pre dir '$dir', column '$col', when using 'enums' type must be 'int'\n";
	  return 1;
	}
	unless( ref( $cols->{$col}{enums} ) eq "HASH" ) {
	  print "$pre dir '$dir', column '$col', 'enums' must be a hash\n";
	  return -1;
	}
	foreach my $i (sort keys(%{$cols->{$col}{enums} }) ) {
	  if( $i =~ /\D/ ) {
	    print "$pre dir '$dir', column '$col', enums: enumvalue must be an int\n";
	    return 1;
	  }
	  unless( ref( $cols->{$col}{enums}{$i} ) eq "ARRAY" ) {
	    print "$pre dir '$dir', column '$col', enumvalue '$i': missing array with enumname + enumdescritpion\n";
	    return -1;
	  }
	  unless( defined $cols->{$col}{enums}{$i}->[0] ) {
	    print "$pre dir '$dir', column '$col', enumvalue '$i': missing enumname\n";
	    return -1;
	  }
	  if( $cols->{$col}{enums}{$i}->[0] =~ / / ) {
	    print "$pre dir '$dir', column '$col', enumvalue '$i': enumname must be a single word\n";
	    return -1;
	  }
	  unless( defined $cols->{$col}{enums}{$i}->[1] ) {
	    print "$pre dir '$dir', column '$col', enumvalue '$i': missing enumdescription\n";
	    return -1;
	  }
	}
      }

      # setup refby
      if( defined $cols->{$col}{ref} ) {
	push @{$vdirs->{$cols->{$col}{ref}}{refby}{$dir} }, $col;
      }

      if( defined $cols->{$col}{type} and $vdirs->{$dir}{edit}==1) {
	if( $cols->{$col}{type} ne 'char' and
	    $cols->{$col}{type} ne 'int' and
	    $cols->{$col}{type} ne 'smallint' and
	    $cols->{$col}{type} ne 'inet' and
	    $cols->{$col}{type} ne 'cidr' )
	{
	  print "$pre dir '$dir', column '$col', type must be one of char/int/smallint/inet/cidr when edit=1\n"; 
	  return 1;
	}
      }

      unless( defined $cols->{$col}{var} ) {
	print "$pre dir '$dir', column '$col', missing elem 'var'\n"; 
	return 1;
      }
      unless( defined $cols->{$col}{desc} ) {
	print "$pre dir '$dir', column '$col', missing elem 'desc'\n"; 
	return 1;
      }
      unless( defined $cols->{$col}{pos} ) {
	print "$pre dir '$dir', column '$col', missing elem 'pos'\n"; 
	return 1;
      }

      # check for duplicate var
      my $varname = $cols->{$col}{var};
      if( defined $varnames{ $varname } ) {
	print "$pre dir '$dir', var '$varname' used for columns '$col' and '$varnames{$varname}'\n";
	return 1;
      }
      $varnames{ $varname } = $col;

    }
  }
  return 0;
}

########################################################################
# check_db_tables()
#
sub check_db_tables() {
  my $st;

  # check version no of db tables
  $st = $dbh->prepare("select value from tablestatus where tag='version' ");
  unless( $st ) {
    print "$PRG: can't prepare query 'version':\n  " . $dbh->errstr;
    return 1;
  }
  unless( $st->execute() ) {
    print "$PRG: can't execute query 'version':\n  " . $dbh->errstr;
    return 1;
  }
  
  my ($dbversion) = $st->fetchrow_array();
  unless( $dbversion ) {
    print "$PRG: can't query db: table version\n";
    return 1;
  }
  
  $st->finish();
  if( $VERSION ne $dbversion ) {
    print 
      "$PRG: version mismatch: $PRG='$VERSION' dbtables='$dbversion'\n";
    return 1;
  }

  # check (existence) of other tables
  foreach my $i (sort keys(%{$vdirs}) ) {
    $st = $dbh->prepare("select * from $i limit 1");
    unless( $st ) {
      print "$PRG: can't prepare query '$i':\n  " . $dbh->errstr;
      return 1;
    }
    unless( $st->execute() ) {
      print "$PRG: can't execute query '$i':\n  " . $dbh->errstr;
      return 1;
    }
    my @dummy = $st->fetchrow_array();
    $st->finish();
  }
  return 0;	# all Ok
}



########################################################################
# recreate_db_tables();
#
sub recreate_db_tables() {
  my $r;
  $dbh->do( "drop table tablestatus" );
  $r = $dbh->do( 
     qq{ create table tablestatus ("tag" char(16), 
				   "value" char(16) PRIMARY KEY) } );
  unless( $r ) {
    print "$PRG: create table tablestatus:\n  " . $dbh->errstr;
    return;
  }
  $r = $dbh->do( 
     qq{ insert into tablestatus (tag, value) values ('version','$VERSION' )});
  unless( $r ) {
    print "$PRG: insert version into tablestatus:\n  " . $dbh->errstr;
    return;
  }

  # recreate other tables
  foreach my $tab (sort keys(%{$vdirs}) ) {
    $dbh->do( "drop table $tab" );
    my $create = "create table $tab (";
    my $cols   = $vdirs->{$tab}{cols};
    foreach my $col (keys(%{$cols}) ) {
      if( defined $cols->{$col}{ref} ) {
	my $rdir = $cols->{$col}{ref};
	my $rfnc = $vdirs->{$rdir}{fnamcol};
	if( defined $vdirs->{$rdir}{cols}{$rfnc}{len} ) {
	  $create .= "$col $vdirs->{$rdir}{cols}{$rfnc}{type}($vdirs->{$rdir}{cols}{$rfnc}{len})";
	}else{
	  $create .= "$col $vdirs->{$rdir}{cols}{$rfnc}{type}";
	}
      }else{
	if( defined $cols->{$col}{len} ) {
	  $create .= "$col $cols->{$col}{type}($cols->{$col}{len})";
	}else{
	  $create .= "$col $cols->{$col}{type}";
	}
	$create .= " $cols->{$col}{colopt}" if defined $cols->{$col}{colopt};
      }
      $create .= ",";
    }
    chop $create;
    $create .= ")";
    $r = $dbh->do( $create );
    unless( $r ) {
      print "$PRG: create table $tab:\n  " . $dbh->errstr;
      return;
    }
    my $df = $vdirs->{$tab}{defaultfile} if exists $vdirs->{$tab}{defaultfile};
    if( $df ) {
      my $fnc = $vdirs->{$tab}{fnamcol};
      if( (length($df)<=$vdirs->{$tab}{cols}{$fnc}{len}) and !($df=~/\W+/)) {
	$r = $dbh->do( "insert into $tab ($fnc) values ('$df')");
	if( !defined $r or $r==0 ) {
	  print "ERROR: couldn't create default entry '$df' in '/$tab':" .
	    $dbh->errstr;
	}
      }else{
	print "ERROR: illegal or to long default filename '$df' in '/$tab'\n";
      }
    }
  }
  return;

} # recreate_db_tables()

########################################################################
# print_file( FH, fnam, verbose );
# create new pseudo file for cat/vi from database
#   FH:		file handle for output
#   fnam:	the filename (key from db)
#   verbose:	0: exclude comments, print only if fnam exists
#	 	1: include comments, print only if fnam exists
#	 	2: include comments, always print: print values if fnam exists,
#		   else print NULL values
# return:
# 	0: Ok
#	1: file does not exist, (but NULL valued file was printed if verbose=2)
#	2: other error
#
sub print_file() {
  my $FH = shift;
  my $fnam = shift;
  my $verbose = shift;

  my @vars;
  my @dbvars;
  my $var;
  my $maxvarlen = 0;
  my @values;
  my @defaults;
  my @descs;
  my @isref;
  my @flags;
  my @enums;
  my $select = "select ";
  my $retval = 2;

  # prepare db query
  my $fnc = $vdirs->{$vwd}{fnamcol};
  my $cols = $vdirs->{$vwd}{cols};
  foreach my $col (sort {$cols->{$a}{pos} <=> $cols->{$b}{pos}} 
		   keys(%{$cols}) ) 
    {
      next if $col eq $fnc;
      $var = $cols->{$col}{var};
      if( length($var) > $maxvarlen ) {$maxvarlen = length($var); }
      push @vars,  $var;
      push @dbvars,$col;
      push @descs, $cols->{$col}{desc};
      push @isref, exists $cols->{$col}{ref} ? $cols->{$col}{ref} : undef;
      push @flags, exists $cols->{$col}{flags} ? $cols->{$col}{flags} : undef;
      push @enums, exists $cols->{$col}{enums} ? $cols->{$col}{enums} : undef;
      $select .=  "$col,";
    }
  chop $select;
  $select .= " from $vwd where $fnc=?";
  
  # query db
  my $st;
  $st = $dbh->prepare( $select );
  unless( $st ) {
    print $FH "$PRG: can't prep print query '$vwd':\n  " . $dbh->errstr;
    return 2;
  }
  unless( $st->execute( $fnam ) ) {
    print $FH "$PRG: can't exec print query 1 '$vwd' :\n  " . $dbh->errstr;
    return 2;
  }
  @values = $st->fetchrow_array();
  $st->finish();

  if( $vdirs->{$vwd}{defaultfile} and $vdirs->{$vwd}{defaultfile} ne $fnam ) {
    unless( $st->execute( $vdirs->{$vwd}{defaultfile} ) ) {
      print $FH "$PRG: can't exec print query 2 '$vwd':\n  " . $dbh->errstr;
      return 2;
    }
    @defaults = $st->fetchrow_array();
  }
  $st->finish();

  # print it
  my $em = "*unset*";

  if( $verbose == 0 ) {
    if( @values ) {
      # print short version (command 'sum')
      $retval = 0;
      for( my $i=0; $i<= $#values; $i++ ) {
	print $FH &var_value_s( $maxvarlen, $vars[$i], $values[$i], 
				$defaults[$i], $flags[$i], $enums[$i],
				@defaults ? 1 : 0
			      );
      }
    }else{
      $retval = 1;
    }
  }else{
    # verbose == 1: (print long)   2: (print long, even if file does not exist)
    my $newfilemsg = "";
    my $print_it = 0;
    if( @values ) {
      # file exists
      $retval   = 0;
      $print_it = 1;
    }else{
      # file does not exist
      $retval = 1;
      if( $verbose == 2 ) {
	$newfilemsg = "#\n#  NEW FILE   NEW FILE   NEW FILE   NEW FILE\n#\n";
	$print_it = 1;
	for( my $i=0; $i<= $#vars; $i++ ) {
	  $values[$i] = undef;
	}
      }
    }
    if( $print_it == 1 ) {
      # command 'cat/vi': long version
      print $FH "$newfilemsg" ;
      print $FH "#\n# Settings for $vdirs->{$vwd}{cols}{$fnc}{desc} '$fnam'" ;
      if( $vdirs->{$vwd}{defaultfile} and 
	  $vdirs->{$vwd}{defaultfile} ne $fnam ) {
	print $FH " (defaults: '$vdirs->{$vwd}{defaultfile}')";
      }
      print $FH "\n#\n".
	"# - this is a comment, comments always start in the first column.\n".
	"# - all lines begin in the first column or are blank lines\n".
	"# - a unset variable will write NULL into the database column\n";
      if( $vdirs->{$vwd}{defaultfile} and 
	  $vdirs->{$vwd}{defaultfile} ne $fnam ) {
	print $FH "# - unset variables use the default values\n";
      }
      print $FH "#\n";
      for( my $i=0; $i<= $#values; $i++ ) {
	# variable with comment header
	printf $FH "\n# %-50s(%s)\n", $vars[$i], $dbvars[$i];
	foreach my $descline (split '\n', $descs[$i] ) {
	  print $FH "# $descline\n";
	}
	print $FH "#\n";
	if( @defaults ) {
	  my $def;
	  if( defined $defaults[$i] and defined $flags[$i] ) {
	    $def = build_flags( $defaults[$i], $flags[$i] );
	  }elsif( defined $defaults[$i] and defined $enums[$i] ) {
	    $def = build_enums( $defaults[$i], $enums[$i] );
	  }elsif( defined $defaults[$i] ) {
	    $def = $defaults[$i];
	  }
	  print $FH  "# default: ";
	  print $FH  defined $def ? "$def\n#\n" : "$em\n#\n";
	}
	print $FH &var_value_v( $vars[$i],$values[$i],$isref[$i],
				$flags[$i],$enums[$i] );
      }
      print $FH "\n# end of file '$fnam'\n";
    }
  }
  return $retval;

} # print_file()

########################################################################
# var_value_v( var, value, ref, flags, enums )
# return a var = value string for verbose print_file()
#   var:	variable name (long version for cat/vi)
#   value:	the value of var or undef
#   ref:	the dir/table referenced by this var or undef
#   flags:	anon hashref with flags setup from vdir or undef
#   enums:	anon hashref with enums setup from vdir or undef
# return:
# 	the string to be printed
#
sub var_value_v() {
  my ($var, $value, $ref, $flags, $enums ) = @_;
  my $s = '';
  if( defined $ref ) {
    # query db
    my $rval;
    my $st;
    my $select = 
      "select $vdirs->{$ref}{fnamcol} from $ref order by $vdirs->{$ref}{fnamcol}";
    $s .= "#   This is a reference to a file in dir '$ref'.\n";
    $st = $dbh->prepare( $select );
    unless( $st ) {
      $s .= "$PRG: can't prep var query '$ref':\n  " . $dbh->errstr;
      return $s;
    }
    unless( $st->execute( ) ) {
      $s .= "$PRG: can't exec var query '$ref' :\n  " . $dbh->errstr;
      return $s;
    }
    $s .= "$var = \n" unless defined $value;
    my $found = 0;
    while( ($rval) = $st->fetchrow_array() ) {
      if( defined $value and $value eq $rval ) {
	$found = 1;
      }else{
	$s .= "#";
      }
      $s .= "$var = $rval\n";
    }
    $st->finish();
    if( $found == 0 and defined $value ) {
      $s .= "### NOTE: File '$value' does not exist in dir '$ref'!\n";
      $s .= "### NOTE: This value will be rejected when saving!\n";
      $s .= "$var = $value\n";
    }
  }elsif( defined $flags ) {
    my $i;
    my $maxlen = 0;
    for( $i=0; $i<32; $i++ ) {
      if( exists $flags->{$i} ) {
	if( length( $flags->{$i}[0] ) > $maxlen ) {
	  $maxlen = length( $flags->{$i}[0] );
	}
      }
    }
    $s .= "# Flags:\n";
    my $hash = defined $value ? '' : '#';
    my $on = "$hash  On:\n";
    my $off = "$hash  Off:\n";
    for( $i=0; $i<32; $i++ ) {
      if( exists $flags->{$i} ) {
	my $first = 1;
	foreach my $dscline (split '\n', $flags->{$i}[1] ) {
	  if( $first ) {
	    $first = 0;
	    $s .= sprintf( "#  %${maxlen}s: %s\n",$flags->{$i}[0], $dscline );
	  }else{
	    $s .= sprintf( "#  %${maxlen}s  %s\n", ' ', $dscline );
	  }
	}
	if( defined $value and ($value & (1<<$i) ) ) {
	  $on .= "$hash    $flags->{$i}[0]\n";
	}else{
	  $off .= "$hash    $flags->{$i}[0]\n";
	}
      }
    }
    if( defined $value ) {
      $s .= "#\n$var = {\n$on$off}\n";
    }else{
      $s .= "#\n$var = \n#$var = {\n$on$off#}\n";
    }

  }elsif( defined $enums ) {
    my $i;
    my $maxlen = 0;
    foreach $i (sort keys(%{$enums}) ) {
      if( length( $enums->{$i}[0] ) > $maxlen ) {
	$maxlen = length( $enums->{$i}[0] );
      }
    }
    $s .= "# Enums:\n";
    my $selected = "  Selected:\n";
    my $avail = "  Available:\n";
    if( defined $value and !exists $enums->{$value} ) {
      $selected .= "    *unknown-enum-value*\n";
    }
    foreach $i (sort keys(%{$enums}) ) {
      my $first = 1;
      foreach my $dscline (split '\n', $enums->{$i}[1] ) {
	if( $first ) {
	  $first = 0;
	  $s .= sprintf( "#  %${maxlen}s: %s\n",$enums->{$i}[0], $dscline );
	}else{
	  $s .= sprintf( "#  %${maxlen}s  %s\n", ' ', $dscline );
	}
      }
      if( defined $value and $value == $i) {
	$selected .= "    $enums->{$i}[0]\n";
      }else{
	$avail .= "    $enums->{$i}[0]\n";
      }
    }
    $s .= "#\n$var = {\n$selected$avail}\n";

  }else{
    $s .= "$var = ";
    $s .= "$value" if defined $value;
    $s .= "\n";
  }
  return $s;

} # var_value_v()

########################################################################
# var_value_s( aligned, var, value, flags, enums, hasdefault )
# return a var = value string for short output (sum & vgrep)
#   maxvarlen:	if not 0: align all '=' using $maxvarlen, else: no alignment
#   var:	variable name (long version for cat/vi)
#   value:	the value of var or undef
#   default:	the default value of var or undef
#   flags:	anon hashref with flags setup from vdir or undef
#   enums:	anon hashref with enums setup from vdir or undef
#   hasdefault:	1: we have a defaults file  0: we don't have
# return:
# 	the string to be printed
#
sub var_value_s() {
  my ($maxvarlen,$var,$value,$default,$flags,$enums,$hasdefault) = @_;
  my $s = '';
  my $i;

  if( defined $flags ) {
    $value = build_flags( $value, $flags );
    $default = build_flags( $default, $flags );
  }elsif( defined $enums ) {
    $value = build_enums( $value, $enums );
    $default = build_enums( $default, $enums );
  }

  if( $maxvarlen ) {
    $s = sprintf( "%-${maxvarlen}s ", $var );
  }else{
    $s = "$var ";
  }
  if( $hasdefault ) {
    if( defined $value ) {
      $s .= "= $value\n";
    }else{
      $s .= defined $default ? "-> $default\n" : "-> *unset*\n";
    }
  }else{
    $s .= defined $value ? "= $value\n" : "= *unset*\n";
  }
  return $s;

} # var_value_s()

########################################################################
# build_flags( value, flags )
# return a string containing all flags set in value
#   value:	the value of var or undef
#   flags:	anon hashref with flags setup from vdir or undef
# return:
# 	the string of set flags if any flags are set
#	'' if no flags set
#	undef if value or flags is undef
#
sub build_flags() {
  my ( $value, $flags ) = @_;
  my $s;
  my $i;

  if( defined $flags and defined $value ) {
    $s = '';
    for( $i=0; $i<32; $i++ ) {
      if( exists $flags->{$i} ) {
	if( $value & (1<<$i) ) {
	  $s .= "$flags->{$i}[0],";
	}
      }
    }
    chop $s;	# chop ,
  }
  return $s;

} # build_flags()

########################################################################
# build_enums( value, enums )
# return a string containing the enum set in value
#   value:	the value of var or undef
#   enums:	anon hashref with enums setup from vdir or undef
# return:
# 	the string of set enum if enum is set
#	undef if - value is undef
#		 - enum is undef
#	         - value is not contained in enums
#
sub build_enums() {
  my ( $value, $enums ) = @_;
  my $s;
  my $i;

  if( defined $enums and defined $value ) {
    if( exists $enums->{$value} ) {
      $s = "$enums->{$value}[0]";
    }else{
      $s = "*unknown-enum-value*";
    }
  }
  return $s;

} # build_enums()


########################################################################
# get_who_refs_me( dir, file )
# return all files referenced by FILE
#   dir:	an existing directory
#   file:	the (probably existing) file within DIR which references 
#		to be checked
# return:
# 	- a list of strings in format "dir/file" if references are found
#	- empty list if no references are found
#	- a list whith one entry holding the errormessage in case of an error
#
sub get_who_refs_me() {
  my ($dir,$file) = @_;
  my @res = ();

  foreach my $refdir (sort keys(%{$vdirs->{$dir}{refby}}) ) {
    my $select = "select $vdirs->{$refdir}{fnamcol} from $refdir where ";
    my @rcols = @{$vdirs->{$dir}{refby}{$refdir}};
    my $st;
    map { $_ .= "='$file'" } @rcols;
    $select .= join( " or ", @rcols );
    $select .= " order by $vdirs->{$refdir}{fnamcol}";

    $st = $dbh->prepare( $select );
    unless( $st ) {
      push @res,"$PRG: can't prep wrefs query '$file':\n  " . $dbh->errstr;
      return @res;
    }
    unless( $st->execute( ) ) {
      push @res,"$PRG: can't exec wrefs query '$file':\n  " . $dbh->errstr;
      return @res;
    }
    my $reffile;
    while( ($reffile) = $st->fetchrow_array() ) {
      push @res, "$refdir/$reffile";
    }
    $st->finish();
  }
  return @res;
}

########################################################################
# create_sql_from_file( tempfile, dir, vfile, insert_flag );
#
# tmpfile:	Absolute path to temporary file on local disk holding
#		the edited parameters
# vdir:		exisiting virtual dir (table)
# vfile:	A file (db-row) for which to generate the $sql SQL code
# insert_flag:	0: $sql --> 'update' string    1: $sql --> 'insert' string
#
# return
# 	a list: ($lineno,$err, $sql):
#	- $lineno: when an error was detected: the errornous line
# 	- $err: when an error was detected: a one line error text, else: undef 
#	        when $err is set then $sql is invalid
#	- $sql: when no error was detected: a SQL insert/update string or ''
#	      	   if nothing to do, when $err is set: trash or undef
#	
#
sub create_sql_from_file( ) {
  my ($tmpfile,$vdir,$vfile,$insert_flag) = @_;
  my $lineno = 0;
  my $line;
  my $var;
  my $val;
  my $err;
  my $sql1;
  my $sql2;
  my %varcol;			# translataion varname -> columnname
  my %isset;			# flags: variable already set? 1: yes
  my %filevars;			# variables from file for phase 2
  my %filevarslineno;		# lineno of variables from file for phase 2

  if( $insert_flag ) {
    $sql1 = "insert into $vdir ($vdirs->{$vdir}{fnamcol},";
    $sql2 = " values('$vfile',";
  }else{
    $sql1 = "update $vdir set ";
    $sql2 = " where $vdirs->{$vdir}{fnamcol}='$vfile'";
  }
  # setup varname translation
  my $cols = $vdirs->{$vdir}{cols};
  foreach my $col ( keys( %{$cols} ) ) {
    $varcol{ $cols->{$col}{var} } = $col;
  }

  # phase 1: do the basic checks, remember var values and their lineno for 
  #	     phase 2 check (user supplied check functions)
  open( TF, $tmpfile ) or return ( 1,"can't open tempfile '$tmpfile'", undef );
 MAIN: while( <TF> ) {
    $line = $_;
    $lineno++;
    chop( $line );
    $line =~ s/^\s*//;		# remove leading space
    next MAIN if $line =~ /^$/;	# skip empty lines
    next MAIN if $line =~ /^\#.*/;	# skip comment lines
    unless( $line =~ /=/ ) {	# missing = ?
      $err = "line $lineno: missing '='";
      last MAIN;
    }
    ($var,$val) = split( /=/, $line, 2 );
    $var =~ s/\s*$//;		# remove trailing space
    $val =~ s/^\s*//;		# remove leading space
    $val =~ s/\s*$//;		# remove trailing space

    if( length($var)==0 or $var =~ /\W+/ ) {	# var name ok?
      $err = "line $lineno: syntax error";
      last MAIN;
    }

    # check if variable name exists
    if( defined $varcol{$var} ) {
      if( defined $isset{$var} ) {
	$err = "line $lineno: variable '$var' set twice"; 
	last MAIN;
      }

      my $col = $varcol{$var};
      my $vlen = length( $val );
      if(  $vlen > 0 ) {
	# check types
	if( defined $cols->{$col}{ref} ) {
	  # type ref
	  my $rdir = $cols->{$col}{ref};
	  my $rfnc = $vdirs->{$rdir}{fnamcol};
	  if( defined $vdirs->{$rdir}{cols}{$rfnc}{len} ) {
	    my $rlen = $vdirs->{$rdir}{cols}{$rfnc}{len};
	    if( $vlen > $rlen ) {
	      $err = "line $lineno: value longer than $rlen"; 
	      last MAIN;
	    }
	  }else{
	    if( $vlen > 1 ) {
	      $err = "line $lineno: value longer than 1"; 
	      last MAIN;
	    }
	  }
	  # check if val exists in referneced table
	  my $st;
	  my $dbval;
	  $st = $dbh->prepare("select $rfnc from $rdir where $rfnc=?");
	  unless( $st ) {
	    $err = "$PRG: internal error: prepare 'exist' query '$rdir':\n  ";
  	    $err .= $dbh->errstr;
	    last MAIN;
	  }
	  unless( $st->execute( $val ) ) {
	    $err = "$PRG: internal error: exec 'exist' query '$rdir':\n  ";
  	    $err .= $dbh->errstr;
	    last MAIN;
	  }
	  $dbval = $st->fetchrow_array();
	  $st->finish();
	  unless( defined $dbval ) {
	    $err = "line $lineno: reference '$val' does no exist in '$rdir'";
	    last MAIN;
	  }
	  if( $insert_flag ) {
	    $sql1 .= "$col,";
	    $sql2 .= "'$val',";
	  }else{
	    $sql1 .= "$col='$val',";
	  }
	  $filevars{$col}       = $val;
	  $filevarslineno{$col} = $lineno;

	}elsif( $cols->{$col}{type} eq 'char' ) {
	  # type char
	  if( defined $cols->{$col}{len} ) {
	    if( $vlen > $cols->{$col}{len} ) {
	      $err = "line $lineno: value longer than $cols->{$col}{len}";
	      last MAIN;
	    }
	  }else{
	    if( $vlen > 1 ) {
	      $err = "line $lineno: value longer than 1"; 
	      last MAIN;
	    }
	  }
	  if( $insert_flag ) {
	    $sql1 .= "$col,";
	    $sql2 .= $dbh->quote( $val ) . ",";
	  }else{
	    $sql1 .= "$col=" . $dbh->quote( $val ) . ",";
	  }
	  $filevars{$col}       = $val;
	  $filevarslineno{$col} = $lineno;

	}elsif( $cols->{$col}{type} eq 'int' ) {
	  # type int
	  if( exists $cols->{$col}{flags} ) {	# flags: process the flags
	    if( $val eq '{' ) {
	      $val = 0;
	      my $mode = '{';
	      my $l;
	      my $flagfound;
	    FLAGS: while( defined ( $l = <TF> ) ) {
		chop( $l );
		$lineno++;
		$l =~ s/\s*$//;			# remove trailing space
		$l =~ s/^\s*//;			# remove leading space
		next FLAGS if $l =~ /^$/;	# skip empty lines
		next FLAGS if $l =~ /^\#.*/;	# skip comment lines
		if( $l eq 'On:' )  { $mode = 'on';  next FLAGS; }
		if( $l eq 'Off:' ) { $mode = 'off'; next FLAGS; }
		if( $l eq '}' ) { 
		  $val = 'NULL' if $mode eq '{';
		  $mode = '}';
		  last FLAGS;
		}
		$flagfound = 0;
		foreach my $bit ( keys( %{$cols->{$col}{flags}} ) ) {
		  if( $cols->{$col}{flags}{$bit}[0] eq $l ) {
		    $flagfound = 1;
		    $val |= (1<<$bit) if $mode eq 'on';
		    last;
		  }
		}
		unless( $flagfound ) {
		  $err = "line $lineno: unknown flag '$l' for '$var'";
		  last MAIN;
		}
	      } # loop FLAGS

	      if( $mode ne '}' ) {
		$err = "line $lineno: missing '}' from flags section";
		last MAIN;
	      }
	    }else{
	      $err = "line $lineno: flags must start with '{'";
	      last MAIN;
	    }
	  }elsif( exists $cols->{$col}{enums} ) {	# enums: process the enums

	    if( $val eq '{' ) {
	      $val = 'NULL';
	      my $mode = '{';
	      my $l;
	      my $enumfound;
	    ENUMS: while( defined ( $l = <TF> ) ) {
		chop( $l );
		$lineno++;
		$l =~ s/\s*$//;			# remove trailing space
		$l =~ s/^\s*//;			# remove leading space
		next ENUMS if $l =~ /^$/;	# skip empty lines
		next ENUMS if $l =~ /^\#.*/;	# skip comment lines
		if( $l eq 'Selected:' )  { $mode = 'sel'; next ENUMS; }
		if( $l eq 'Available:' ) { $mode = 'ava'; next ENUMS; }
		if( $l eq '}' ) 	 { $mode = '}';   last ENUMS; }
		$enumfound = 0;
		foreach my $enumval ( keys( %{$cols->{$col}{enums}} ) ) {
		  if( $cols->{$col}{enums}{$enumval}[0] eq $l ) {
		    $enumfound = 1;
		    if( $mode eq 'sel' ) {
		      if( $val eq 'NULL' ) {
			$val = $enumval;
		      }else{
			$err = "line $lineno: only one elem may be selected for '$var'";
			last MAIN;
		      }
		    }
		    last;
		  }
		}
		unless( $enumfound ) {
		  $err = "line $lineno: unknown enum tag '$l' for '$var'";
		  last MAIN;
		}
	      } # loop ENUMS
	      if( $mode ne '}' ) {
		$err = "line $lineno: missing '}' from enums section";
		last MAIN;
	      }
	    }else{
	      $err = "line $lineno: enums must start with '{'";
	      last MAIN;
	    }
	  }else{				# no flags,no enums, normal int
	    unless( $val =~ /^-?\d+$/ ) {
	      $err = "line $lineno: value not an integer"; 
	      last MAIN;
	    }
	    if( $val <= -2147483648 or $val >= 2147483647 ) {
	      $err = "line $lineno: value out of int range"; 
	      last MAIN;
	    }
	  }
	  if( $insert_flag ) {
	    $sql1 .= "$col,";
	    $sql2 .= "$val,";
	  }else{
	    $sql1 .= "$col=$val,";
	  }
	  $filevars{$col}       = $val;
	  $filevarslineno{$col} = $lineno;

	}elsif( $cols->{$col}{type} eq 'smallint' ) {
	  # type smallint
	  unless( $val =~ /^-?\d+$/ ) {
	    $err = "line $lineno: value not an integer"; 
	    last MAIN;
	  }
	  if( $val <= -32768 or $val >= 32767 ) {
	    $err = "line $lineno: value out of smallint range"; 
	    last MAIN;
	  }
	  if( $insert_flag ) {
	    $sql1 .= "$col,";
	    $sql2 .= "$val,";
	  }else{
	    $sql1 .= "$col=$val,";
	  }
	  $filevars{$col}       = $val;
	  $filevarslineno{$col} = $lineno;

	}elsif( $cols->{$col}{type} eq 'cidr' ) {
	  # type cidr
	  my $st;
	  my $dbval;
	  $st = $dbh->prepare( "select cidr '$val'" );
	  unless( $st ) {
	    $err = "$PRG: internal error: select cidr\n  ";
	    $err .= $dbh->errstr;
	    last MAIN;
	  }
	  unless( $st->execute(  ) ) {
	    $err = $dbh->errstr;
	    last MAIN;
	  }
	  ($dbval) = $st->fetchrow_array();
	  $st->finish();

	  if( $insert_flag ) {
	    $sql1 .= "$col,";
	    $sql2 .= "'$val',";
	  }else{
	    $sql1 .= "$col='$val',";
	  }
	  $filevars{$col}       = $val;
	  $filevarslineno{$col} = $lineno;

	}elsif( $cols->{$col}{type} eq 'inet' ) {
	  # type inet
	  my $st;
	  my $dbval;
	  $st = $dbh->prepare( "select inet '$val'" );
	  unless( $st ) {
	    $err = "$PRG: internal error: select inet\n  ";
	    $err .= $dbh->errstr;
	    last MAIN;
	  }
	  unless( $st->execute(  ) ) {
	    $err = $dbh->errstr;
	    last MAIN;
	  }
	  ($dbval) = $st->fetchrow_array();
	  $st->finish();

	  if( $insert_flag ) {
	    $sql1 .= "$col,";
	    $sql2 .= "'$val',";
	  }else{
	    $sql1 .= "$col='$val',";
	  }
	  $filevars{$col}       = $val;
	  $filevarslineno{$col} = $lineno;

	}else{
	  # type unknown!
	  $err = "line $lineno: unsupported datatype from vdirs for $var"; 
	  last MAIN;
	}
      }else{			 # $vlen == 0
	if( $insert_flag ) {
	  $sql1 .= "$col,";
	  $sql2 .= "NULL,";
	}else{
	  $sql1 .= "$col=NULL,";
	}
	$filevars{$col}       = undef;
	$filevarslineno{$col} = $lineno;
      }
      $isset{$var} = 1;	# remember that this var is set
    }else{
      $err = "line $lineno: unknown variable '$var'";
      last MAIN;
    }
  }
  close( TF );
  if( $insert_flag ) {
    chop( $sql1 );
    chop( $sql2 );
    $sql1 .= ")";
    $sql2 .= ")";
  }else{
    if( chop( $sql1 ) ne ',' ) {
      # no columns to update
      $sql1 = "";
      $sql2 = "";
    }
  }

  # phase 2: if basic check didn't show an error, do the user supplied checks

  my $hasuniqcols = 0;
  $filevars{ $vdirs->{$vdir}{fnamcol} } = $vfile;  # add our filename to hash
  if( !defined $err ) {
    foreach my $col (keys(%filevars) ) {
      my $valerr;
      if( exists $cols->{$col}{uniq} ) { $hasuniqcols = 1; }
      if( exists $cols->{$col}{valok} ) {
	$valerr = &{$cols->{$col}{valok}}( $filevars{$col}, \%filevars, $dbh );
	if( defined $valerr ) {
	  $err = "line $filevarslineno{$col}: $valerr";
	  $lineno = $filevarslineno{$col};
	  last;
	}
      }
    }
  }

  # phase 3: check if there are columns/vars that have to be uniq

  my $fnc = $vdirs->{$vwd}{fnamcol};
  if( !defined $err and $hasuniqcols == 1 ) {
    foreach my $col (keys(%filevars) ) {
      my $valerr = "";
      if( exists $cols->{$col}{uniq} ) {
	my $st;
	my $dbval;
	$st = $dbh->prepare(
		"select $fnc from $vwd where $col=? and $fnc != '$vfile'");
	unless( $st ) {
	  $err = "$PRG: internal error: prepare 'uniq' query '$vwd':\n  ";
	  $err .= $dbh->errstr;
	  last;
	}
	unless( $st->execute( "$filevars{$col}" ) ) {
	  $err = "$PRG: internal error: exec 'uniq' query '$vwd':\n  ";
	  $err .= $dbh->errstr;
	  last;
	}
	while( ($dbval) = $st->fetchrow_array() ) {
	  $valerr .= " $dbval";
	}
	$st->finish();
	if( $valerr ne "" ) {
	  $err = "line $filevarslineno{$col}: uniq value '$filevars{$col}' " .
		 "already in file(s): $valerr";
	  $lineno = $filevarslineno{$col};
	  last;
	}
      }
    }
  }
  return ( $lineno, $err, "$sql1$sql2" );

} # create_sql_from_file()

########################################################################
# want_to_edit_again( errortext )
# ask the user if he wants to edit again
#   errortext:	one line error text
# return:
# 	'y' or 'n'
#
sub want_to_edit_again() {
  my $errortext = shift;
  my $inp = '';
  my $IN = $term->IN;
  print $OUT "\n\n\n\n\n\n\n$errortext\n";
  while( $inp ne 'y' and $inp ne 'n' ) {
    print $OUT "Do you want to edit again ('n' will abort) [y/n] ? ";
    $inp = <$IN>; 
    $inp = '\n' unless defined $inp;
    chop $inp;
  }
  return $inp;
}

########################################################################
# do_vgrep( pattern );
# grep all val/value pairs in vwd for pattern and print matching lines
#   pattern:	the pattern to grep for
#
# return:
# 	nothing
#
sub do_vgrep() {
  my $pattern = quotemeta shift;

  my @vars;
  my @dbvars;
  my $var;
  my @values;
  my @defaults;
  my @flags;
  my @enums;
  my $fnam;
  my $em = "*unset*";
  my $hasdefault;

  # prepare db query
  my $fnc = $vdirs->{$vwd}{fnamcol};
  my $select = "select $fnc,";
  my $seldef = "select ";
  my $cols = $vdirs->{$vwd}{cols};
  my $fnlen = $cols->{$fnc}{len};
  foreach my $col (sort {$cols->{$a}{pos} <=> $cols->{$b}{pos}} 
		   keys(%{$cols}) ) 
    {
      next if $col eq $fnc;
      $var = $cols->{$col}{var};
      push @vars,  $var;
      push @dbvars,$col;
      push @flags, exists $cols->{$col}{flags} ? $cols->{$col}{flags} : undef;
      push @enums, exists $cols->{$col}{enums} ? $cols->{$col}{enums} : undef;
      $select .=  "$col,";
      $seldef .=  "$col,";
    }
  chop $select;
  chop $seldef;
  $select .= " from $vwd order by $fnc";
  $seldef .= " from $vwd where $fnc=?";
  
  # query default if available
  if( $vdirs->{$vwd}{defaultfile} ) {
    my $st;
    $st = $dbh->prepare( $seldef );
    unless( $st ) {
      print $OUT "$PRG: prep vgrep default query '$vwd':\n  " . $dbh->errstr;
      return;
    }
    unless( $st->execute( $vdirs->{$vwd}{defaultfile} ) ) {
      print $OUT "$PRG: exec vgrep default query '$vwd':\n  " . $dbh->errstr;
      return;
    }
    @defaults = $st->fetchrow_array();
    $st->finish();
  }
  
  # query all files
  my $st;
  $st = $dbh->prepare( $select );
  unless( $st ) {
    print $OUT "$PRG: prep vgrep query '$vwd':\n  " . $dbh->errstr;
    return;
  }
  unless( $st->execute() ) {
    print $OUT "$PRG: exec vgrep query 1 '$vwd' :\n  " . $dbh->errstr;
    return;
  }

  # print result
  while (($fnam, @values ) = $st->fetchrow_array() ) {
    if( @values ) {
      for( my $i=0; $i<= $#values; $i++ ) {
	if( $vdirs->{$vwd}{defaultfile} and 
	    $vdirs->{$vwd}{defaultfile} ne $fnam ) {
	  $hasdefault = 1;
	}else{
	  $hasdefault = 0;
	}
	
	my $line = &var_value_s( 0, $vars[$i], $values[$i], 
				 $defaults[$i], $flags[$i], $enums[$i],
				 $hasdefault
			       );
	printf $OUT "%${fnlen}s: %s", $fnam, $line if $line =~ /$pattern/i;
      }
    }
  }
  $st->finish();
  
  return;
}


########################################################################
########################################################################
## obejct orientated interface: the access class for config database
########################################################################
########################################################################

########################################################################
# new();
# contructor for DBIx::FileSystem access class
# parameter:
#       dbconn: database connect string used for DBI database connect
#	dbuser: database user
#     dbpasswd: database user's password
#    progdbver: program's databaase layout version string
#
# return: the object
#
sub new {
  my $class = shift;
  my %params = @_;
  my $self = {};
  bless( $self, $class );

  $self->{dbh} = undef;
  $self->{err} = "Ok";

  # initialize object
 FINI: while( 1 ) {
    if( exists $params{dbconn} and defined( $params{dbconn} ) ){
      $self->{dbconn} = $params{dbconn};
    }else{
      $self->{dbconn} = undef;
      $self->{err} = "parameter 'dbconn' undefined";
      last FINI;
    }
    if( exists $params{progdbver} and defined( $params{progdbver} ) ) {
      $self->{progdbver} = $params{progdbver};
    }else{
      $self->{progdbver} = undef;
      $self->{err} = "parameter 'progdbver' undefined";
      last FINI;
    }
    $self->{dbh} = DBI->connect( $self->{dbconn}, 
				 $params{dbuser}, $params{dbpasswd}, 
				 { PrintError => 0, AutoCommit => 1, 
				   ChopBlanks =>1 } );
    unless( $self->{dbh} ) {
      $self->{err} = "connect: " . $DBI::errstr;
      last FINI;
    }
    last FINI;
  }

  return $self;

} # new()

########################################################################
# DESTROY();
# parameter: none
#
# return:  nothing
#
sub DESTROY {
  my $self = shift;

  $self->{dbh}->disconnect() if defined $self->{dbh};

  $self->{dbh} = undef;
  $self->{dbconn} = undef;
  $self->{progdbver} = undef;
  $self->{err} = "object destroyed";

  return;

} # DESTROY()

########################################################################
# database_bad();
# check if the database connection is ok. If not, set an errormessage into 
# the errorbuffer
#
# parameter: none
#
# return:  0: database ok
#	   1: database wrong
#
sub database_bad {
  my $self = shift;
  my $ret = 1;

  if( defined $self->{dbh} ) {	
    # check version number
    my $st = $self->{dbh}->prepare( 
		       "SELECT value FROM tablestatus WHERE tag='version'" );
    if( $st ) {
      if( $st->execute() ) {
	my ($dbdbver) = $st->fetchrow_array();
	if( $dbdbver eq $self->{progdbver} ) {
	  $ret = 0;
	}else{
	  $self->{err} = 
	      "version mismatch: program <--> db ('$self->{progdbver}' <--> '$dbdbver')";
	}
	$st->finish();
      }else{
	$self->{err} = "exec query dbversion: " . $self->{dbh}->errstr;
      }
    }else{
      $self->{err} = "prepare qry dbversion: " . $self->{dbh}->errstr;
    }
  }
  if( $ret ) {
    $self->{dbh}->disconnect() if defined $self->{dbh};
    $self->{dbh} = undef;
  }
  return $ret;

} # database_bad()

########################################################################
# get_err();
# read the last error message from the error buffer
# parameter: none
#
# return:  last errorstring
#
sub get_err {
  my $self = shift;
  return $self->{err};

} # get_err()

########################################################################
# get_conf_by_var();
#
# parameter: 
#   in:
#	$dir:		the directory (table) to search in
#	$defaultfname:	the filename of the defaultfile if availalble,
#			else undef
#	$fnamcol:	the column which contains the symbolic filename
#   in/out:
#	\%vars:		a hashref pointing to a hash containing the column
#			names to fetch as a key, values will be set by function
#   in: \%searchvars	a hashref pointing to a hash containing the values to
#			to use as a filter (SQL WHERE part). Key: column name
#			value: The value or an anon array-ref with
#			   [ 'compare-operator', 'value-to-search-for' ]
#
# return:  OK		Ok, one file found, \%vars filled with values from db
#	   NOFILE	no file found, \%vars's values will be undef
#	   NFOUND	more than one file found, \%vars's values will be undef
#	   ERROR	error, call method get_err to pick the error message
#			\%vars's values will be undef
#
sub get_conf_by_var {
  my $self = 	    shift;
  my $dir = 	    shift;
  my $defaultfname =shift;
  my $fnamcol =	    shift;
  my $vars = 	    shift;
  my $searchvars =  shift;

  my $r = ERROR;
  my $st;

  unless( defined $self->{dbh} ) {
    $self->{err} = "DBIx::FileSystem object not initialized";
    return $r;
  }

  # check parameter
  if( !defined $dir or $dir eq '' ) {
    $self->{err} = "get_conf_by_var(): parameter 'dir' is empty";
    return $r;
  }
  if( !defined $fnamcol or $fnamcol eq '' ) {
    $self->{err} = "get_conf_by_var(): parameter 'fnamcol' is empty";
    return $r;
  }
  if( ref( $vars ) ne 'HASH' ) {
    $self->{err} = "get_conf_by_var(): parameter 'vars' is no hashref";
    return $r;
  }
  if( keys( %{$vars} ) == 0 ) {
    $self->{err} = "get_conf_by_var(): hash 'vars' is empty";
    return $r;
  }
  if( ref( $searchvars ) ne 'HASH' ) {
    $self->{err} = "get_conf_by_var(): parameter 'searchvars' is no hashref";
    return $r;
  }
  if( keys( %{$searchvars} ) == 0 ) {
    $self->{err} = "get_conf_by_var(): hash 'searchvars' is empty";
    return $r;
  }

  foreach my $v ( keys %{$vars} ) {
    $vars->{$v} = undef;
  }

 DB: while( 1 ) {
    my %extra;
    my $qry = '';
    my $res;

    # check query parameters against defaultfile
    if( defined $defaultfname ) {
      foreach my $searchvar (keys %{$searchvars} ) {
	$qry = "SELECT count($fnamcol) FROM $dir WHERE $searchvar" .
	  $self->sqlize( $searchvars->{$searchvar} ) .
	  " AND $fnamcol = '$defaultfname'";
	$st = $self->{dbh}->prepare( "$qry" );
	unless( $st ) {
	  $self->{err} = "prepare extra qry: " . $self->{dbh}->errstr;
	  last DB;
	}
	if( $st->execute() ) {
	  ($res) = $st-> fetchrow_array();
	  if( defined $res and $res == 1 ) {
	    $extra{$searchvar} = " OR $searchvar IS NULL";
	  }else{
	    $extra{$searchvar} = "";
	  }
	  $st->finish();
	}else{
	  $self->{err} = "exec extra qry: " . $self->{dbh}->errstr;
	  last DB;
	}
      }
    }else{
      foreach my $searchvar (keys %{$searchvars} ) {
	$extra{$searchvar} = "";
      }
    }

    # base query

    $qry = "SELECT ";
    foreach my $var (keys %{$vars} ) {
      $qry .= "$var,";
    }
    chop $qry;
    $qry .= " FROM $dir WHERE ";
    my $rest = 0;
    foreach my $searchvar (keys %{$searchvars} ) {
      $qry .= " AND " if $rest;
      $qry .= "( $searchvar" . $self->sqlize( $searchvars->{$searchvar} ) .
	      "$extra{$searchvar} )";
      $rest = 1 unless $rest;
    }
    ### print "qry: '$qry'\n";

    $res = $self->{dbh}->selectall_arrayref( $qry, { Slice => {} } );
    if( !defined $res or defined $self->{dbh}->{err} ) {
      $self->{err} = "get_conf_by_var(): query: " . $self->{dbh}->errstr;
      last DB;
    }

    if( @$res == 0 ) {
      $self->{err} = "no file found";
      $r = NOFILE;
      last DB;
    }elsif( @$res == 1 ) {
      foreach my $col (keys %{$res->[0]} ) {
	$vars->{$col} = $res->[0]->{$col};
      }
      $r = OK;
    }else{
      $self->{err} = "more than one file found";
      $r = NFOUND;;
      last DB;
    }

    # read defaults from defaultfile if necessary

    if( defined $defaultfname ) {
      my %sv = ( $fnamcol => $defaultfname );
      my %v = %{$vars};
      $r = $self->get_conf_by_var( $dir, undef, $fnamcol, \%v, \%sv );

      if( $r == OK ) {
	foreach my $var ( keys %v ) {
	  $vars->{$var} = $v{$var} unless defined $vars->{$var};
	}
      }else{
	if( $r == NOFILE ) {
	  $self->{err} = "defaultfile '$dir/$defaultfname' not found";
	}elsif( $r == NFOUND ) {
	  $self->{err} = "more than one file '$dir/$defaultfname' found";
	}
	foreach my $v ( keys %{$vars} ) {
	  $vars->{$v} = undef;
	}
	$r = ERROR;
      }
    }

    last DB;

  } # while( DB )

  return $r;

} # get_conf_by_var()

########################################################################
# sqlize();
# build the right-hand-side of the WHERE part, incl. compare operator.
# respect quoting of strings, integer values and 'undef' / NULL
# parameter: 
#	$val: the value to SQLize
#
# return:  the sqlized string
#
sub sqlize {
  my $self = shift;
  my $val = shift;
  my $r;
  if( ! defined $val ) {
    $r = " IS NULL";
  }elsif( ref( $val ) eq 'ARRAY' ) {
    if( defined $val->[0] and defined $val->[1] ) {
      if( $self->isanumber( $val->[1] ) ) {
	$r = " $val->[0] $val->[1]";
      }else{
	$r = " $val->[0] " . $self->{dbh}->quote( $val->[1] );
      }
    }else{
      $r = " IS NULL";
    }
  }else{
    if( $self->isanumber( $val ) ) {
      $r = "=$val";
    }else{
      $r = "=" . $self->{dbh}->quote( $val );
    }
  }

  return $r;

} # sqlize()


########################################################################
# isanumber();
# check if $str is a number or not
# parameter: 
#	$str
#
# return:  0	$val is string
# 	   1	$val is number
#
sub isanumber() {
  my $self = shift;
  my $str = shift;
  my $r = 1;

  if( !defined $str ) {
    $r = 0;
  }elsif( $str eq '' ) {
    $r = 0;
  }elsif( $str =~ / / ) {
    $r = 0;
  }elsif( $str =~ /infinity/i ) {
    $r = 0;
  }elsif( $str =~ /nan/i ) {
    $r = 0;
  }else{
    $! = 0;
    my ($num, $unparsed ) = POSIX::strtod( $str );
    if( ($unparsed != 0) || $!) {
      $r = 0;
    }
  }
  return $r;

} # isanumber()


########################################################################
########################################################################
########################################################################
########################################################################

1;
__END__


=head1 NAME

DBIx::FileSystem - Manage tables like a filesystem


=head1 SYNOPSIS

  ##############################################################
  # access the data using the access class
  ##############################################################
  use DBIx::FileSystem qw( :symbols );

  my $fs = new DBIx::FileSystem( dbconn => $DBCONN,
				 dbuser => $DBUSER,
				 dbpasswd => $DBPWD,
				 progdbver => $PROGDBVER );

  my %vars = ( column_1 => undef,	# columns to read from db
	       column_2 => undef   );

  my %searchvars = ( column_a => "myvalue",	# the WHERE part
 		     column_b => 1234,
		     column_c => [ 'LIKE', 'abc%' ] );

  $r = $fs->get_conf_by_var( $dir, $default_filename, $filename_column,
			     \%vars, \%searchvars );
  die $fs->get_err if $r != OK;


  ##############################################################
  # implement the interactive configure shell
  ##############################################################

  use DBIx::FileSystem qw( mainloop recreatedb );
  my %vdirs = 
  ( 
     table_one => 
     { 
       # ... column description here ...
     },
     table_two => 
     { 
       # ... column description here ...
     },
  );

  my %customcmds = ();

  if( $#ARGV==0 and $ARGV[0] eq 'recreatedb' ) {
    recreatedb(%vdirs, $PROGNAME, $VERSION, 
	       $DBCONN, $DBUSER, $DBPWD);
  }else{
    # start the command line shell
    mainloop(%vdirs, $PROGNAME, $VERSION, 
	     $DBCONN, $DBUSER, $DBPWD, %customcmds );
  }



The upper synopsis shows how to 
access the data using the access class.
The lower synopsis shows the program (aka 'the shell') to manage the 
database tables given in hash B<%vdirs>. 

=head1 DESCRIPTION

The module DBIx::FileSystem offers you a filesystem like view to
database tables. To interact with the database tables, FileSystem
implements:


=over 4

=item - 

An access class to read the data edited by the shell.

=item -

A user interface as a command line shell which offers not only a subset of well
known shell commands to navigate, view and manipulate data in tables, but
also gives the convenience of history, command line editing and tab
completion. FileSystem sees the database as a filesystem: each
table is a different directory with the tablename as the directory
name and each row in a table is a file within that directory.

=back

The motivation for FileSystem was the need for a terminal based
configuration interface to manipulate database entries which are used
as configuration data by a server process. FileSystem is neither
complete nor a replacement for dbish or other full-feature SQL shells
or editors. Think of FileSystem as a replacement for a Web/CGI based
graphical user interface for manipulating database contents.


=head1 REQUIREMENTS

The DBI module for database connections.  A DBD module used by DBI for
a database system.  And, recommended, Term::ReadLine::Gnu, to make
command line editing more comfortable, because perl offers only stub
function calls for Term::ReadLine. Note: Term::ReadLine::Gnu requires
the Gnu readline library installed.

=head1 DATABASE LAYOUT

FileSystem sees a table as a directory which contains zero or more
files. Each row in the table is a file, where the filename is defined
by a column. Each file holds some
variable = value pairs. All files in a directory are of the same
structure given by the table layout. A variable is an alias for a
column name, the value of the variable is the contents of the
database.

When editing a file via the shell's 'vi' command,
FileSystem generates a temporary configuration
file with comments for each variable and descriptive variable names
instead of column names. The variable names and comments are defined
in B<%vdirs> hash as shown below. So, in the following description:

    'directory' is a synonym for 'table'
    'file'      is a synonym for 'row',
    'variable'  is a synonym for 'column'

=head2 DEFAULTFILE FUNCTION

Each directory optionally supports a defaultfile. The idea: If a
variable in a file has value NULL then the value of the defaultfile
will be used instead. 
The application using the database (for reading
configuration data from it) has to take care of a defaultfile. The access
class implented in DBIx::FileSystem handles a defaultfile correctly.

FileSystem's shell knows about a defaultfile when viewing a file and shows the 
values from the defaultfile when a variable contains NULL. A defaultfile
can not be removed with 'rm'.

The chell commands cat, sum, and vgrep show the usage of the default 
value by showing '->'
instead of '=' when printing content. Example: "MyVar -> 1234". 
Here the value of MyVar is NULL in the database and the default value 
(1234) from the defaultfile is printed.


=head1 METHODS (access class)

new()

Constructor. Parameters are:

=over 4

=item dbconn

Mandatory.
DBI connect string to an existing database. Depends on the underlying 
database. Example: "dbi:Pg:dbname=myconfig;host=the_host";

=item dbuser

May be undef.
DBI database user needed to connect to the database given in $DBCONN.

=item dbpasswd

May be undef.
DBI password needed by $DBUSER to connect to the database given in $DBCONN.
May be set to undef if no password checking is done.

=item progdbver

Mandatory.
A character string with max. length of 16. Holds the version number of
the database layout. See VERSION INFORMATION elsewhere in this document.

=back



database_bad()

Checks the status of the database (connected, right version number). Returns
0 if database is ok, 1 otherwhise. Sets the errorstring for method 'get_err()'


get_err()

Returns the last error message as a string. May be a multiline string, 
because some DBD drivers report errors in multiline format. The error message
corresponds to the last DBIx::FileSystem method that has not returned OK.


get_conf_by_var()

Read data from the database.

$r = get_conf_by_var( $dir, $default_fname, $fname_column, \%v, \%sv )

Parameters are:

=over 4

=item $dir

String. Input parameter. The name of the directory / database table to 
search in.

=item $default_fname

String. Input parameter. The filename (symbolic name) of the defaultfile. 
If no defaultfile is defined for this $dir: undef.
See section "DEFAULTFILE FUNCTION" elsewhere in this document.

=item $fname_column

String. Input parameter. The name of the column holding the filename
(symobic name) for the files. This parameter is called 'fnamcol' 
in %vdir hash for the shell.

=item \%v

Hashref 'vars'. Input and output parameter. The columns we want to read 
from the
database. Keys: the column-names to fetch. Values: When get_conf_by_var() 
returns OK: the values from database, else: undef. When calling with 
$default_fname not undef, get_conf_by_var() will replace all database 
NULL values in the result with the values found in $default_file.
See section "DEFAULTFILE FUNCTION" elsewhere in this document.

=item \%sv

Hashref 'searchvars'. Input parameter. The filter critieria (SQL: WHERE part) 
for searching the database. Each key-value pair results in one SQL compare
term. If more than one key-value pair is given in %sv, the compare terms are
ANDed. Keys: the column-names to use for the compare.
Values: either the value itself (undef matches NULL in db) using compare
operator '=', or an anon array-ref with $aref->[0] = the SQL compare 
operator as a string and $aref->[1] = the value used for compare 
(undef matches NULL in db). 
Examples:

                                        # --> SQL WHERE part:
  my %sv = ( a => "myvalue",		# a = 'myvalue' AND
	     b => 1234,			# b = 1234      AND
             c => undef			# c IS NULL     AND
	     d => [ 'LIKE', 'abc%' ] );	# d LIKE 'abc%' AND
	     e => [ '<', 55 ] );	# e < 55
	   );

Note: When checking the search criteria against a defaultfile 
(parameter $default_fname defined), then the SQL queries generated by
DBIx::FileSystem are more complex than given in the example above.

=back

Return values:

  OK      (0)  ok, one file found, result stored in %v's values.
  NOFILE  (1)  no file found, %v's values are undef
  NFOUND  (2)  more than one file found, %v's values are undef
  ERRROR  (3)  error, %v's values are undef, error string set

Import :symbols to use the short version of the symbolic names instead of 
the integer values or use DBIx::FileSystem::OK, ...

=head1 FUNCTIONS (interactive shell)

recreatedb(%vdirs,$PROGNAME,$VERSION,$DBCONN,$DBUSER,$DBPWD);


=over 2

Recreate the tables given in B<%vdirs>. Will destroy any existing tables
with the same name in the database including their contents. Will create
a table 'tablestatus' for version information.
Tables not mentioned in B<%vdirs> will not be altered. 
The database itself will 
not be dropped. Checks if B<%vdirs> is valid. Returns nothing.

=back

mainloop(%vdirs,$PROGNAME,$VERSION,$DBCONN,$DBUSER,$DBPWD,%customcmds);

=over 2

Start the interactive shell for the directory structure given in B<%vdirs>. 
Returns when the user quits the shell. Checks if B<%vdirs> is valid. 

=back

=head2 parameters

=over 4

=item %vdirs

A hash of hashes describing the database layout which will be under 
control of FileSystem. See DATABASE LAYOUT elsewhere in this document.

=item $PROGNAME

The symbolic name of the interactive shell. Used for errormessages and command
prompt.

=item $VERSION

A character string with max. length of 16. Holds the version number of
the database layout. See VERSION INFORMATION below for details.

=item $DBCONN

DBI connect string to an existing database. Depends on the underlying 
database. Example: "dbi:Pg:dbname=myconfig;host=the_host";

=item $DBUSER

DBI database user needed to connect to the database given in $DBCONN.

=item $DBPWD

DBI password needed by $DBUSER to connect to the database given in $DBCONN.
May be set to undef if no password checking is done.

=item %customcmds

A hash which contains user defined commands to extend the shell 
(custom commands).
If you do not have any commands then set %customcmds = (); before calling
mainloop(). The key of the hash is the commandname for the shell, the value 
is an anon hash with two fields: B<func> holding a function reference of the
function implementing the command and B<doc>, a one line help text for the
help command. 

=back

=head2 custom commands

All custom commands are integrated into the completion functions: command 
completion and parameter completion, where parameter completion uses the
files in the current directory.

A custom command gets the shells command line parameters as 
calling parameters. DBIx::FileSystem exports the following variables for use
by custom commands:

=over 4

=item $DBIx::FileSystem::vwd

The current working directory of the shell. Do not modify!

=item $DBIx::FileSystem::dbh

The handle to the open database connection for the config data. Do not modify!

=item $DBIx::FileSystem::OUT

A fileglob for stdout. Because FileSystem / Gnu ReadLine grabs the tty stdout
you can not directly print to stdout, instead you have to use this fileglob.
Do not modify!

=back

Please see 'count' command in the example 'pawactl' how to implement custom
commands. See the source of DBIx::FileSystem how to implement commands.

=head2 B<%vdirs hash>

The B<%vdirs> hash defines the database layout. It is a hash of hashes.

 %vdirs = (
   DIRECTORY_SETTING,
   DIRECTORY_SETTING,
   # ... more directory settings ...
 );

The DIRECTORY_SETTING defines the layout of a directory (database table):

  # mandatory: the directory name: dirname = tablename
  dirname  => {			

    # mandatory: description of table
    desc => "dir description",	

    # mandatory: Defines if this directory is read-
    # only or writable for the shell. If set to 1
    # then the commands vi/rm are allowed.
    edit => [0|1],		

    # mandatory: The column which acts as filename.
    # The column must be of type 'char' and len 
    # must be set and len should be < 15 for proper
    # 'ls' output
    fnamcol => 'colname',	

    # optional: The column which acts as comment
    # field. The column must be of type 'char' and 
    # len must be set. The comments will be shown
    # by 'll' command (list long).
    comcol => 'colname',	

    # optional: Name of a default file. This file
    # will be automatically created from 
    # &recreatedb() and cannot be removed. The
    # defaultfile is only usefull when edit = 1.
    # Note: directories which have a column with
    # colopt => 'NOT NULL' constraint (see below):
    # the constraint must also set a default value like
    # colopt => 'DEFAULT 0 NOT NULL', otherwise the creation
    # of the database table will fail.
    defaultfile => 'filename',	

    # optional: Function reference to a function 
    # that will be called when a file of this 
    # directory will be removed. The rm command
    # will call this function with parameters 
    # ($dir, $file, $dbh) of the file to be removed 
    # and after all other builtin checks are done.
    # $dbh is the handle to the database connection.
    # The function has to return undef if remove 
    # is ok, or a one line error message if it is 
    # not ok  to remove the file
    rmcheck => \&myRmCheckFunction,

    # mandatory: column settings
    cols => {		
  	COLUMN_SETTING,
  	COLUMN_SETTING,
	# ... more column settings ...
    },
  },

The COLUMN_SETTING defines the layout of a column (database column). 

  # mandatory: the columnname itself: colname = columnname
  colname => {			

    # mandatory: column type of this column 
    # (see below COLUMN_TYPE)
    COLUMN_TYPE,

    # optional: extra constraints for this column
    # when creating the database with 
    # &recreatedb(). Example: 'NOT NULL'
    colopt => 'OPTIONS',		

    # optional: Function reference to a function
    # that will be called before a value gets
    # inserted/updated for this column and after
    # builtin type, length, range and reference
    # checks has been done. Will be called with
    # ($value_to_check,$hashref_to_othervalues,$dbh)
    # hashref holds all values read in from file,
    # key is the columnname. All hashvalues are 
    # already checked against their basic type, 
    # empty values in the file will be set to undef.
    # $dbh is the handle to the database connection.
    # The valok function has to return undef
    # if the value is ok or a one line error
    # message if the value is not ok.
    valok => \&myValCheck,			

    # optional: when this option exists and is set
    # then this column will be set to NULL 
    # when copying a file with 'cp'. When saving a
    # file the value entered must be uniq for this
    # variable in all files in the dir.
    uniq => 1,			

    # optional: when this option is set the variable
    # behaves like a collection of flags. Each flag has
    # a bit number ranging from 0..31, a one word flag name,
    # and a long flag description. The value of the variable
    # is the bitwise or of all flags set. The variable's column
    # type COLUMN_TYPE must be integer: type => 'int', see below.
    flags => { bitnumber => [ "flagname", "flag description" ],
	       bitnumber => [ "flagname", "flag description" ],
	       # more flags settings ...
	     }

    # optional: when this option is set the variable
    # behaves like a enum type variable based on type 'int'.
    # Each enum entry in 'enums' has an integer value 'enumvalue',
    # a one word enum name 'enumname' and a long enum description.
    # The possible values of this variable are 'empty' or
    # one of the symbolic 'enumnames', corresponding to
    # NULL or the integer 'enumvalue' in the database. 
    # The variable's column  type COLUMN_TYPE must be integer: 
    # type => 'int', see below.
    enums => { enumvalue => [ "enumname", "enum description" ],
	       enumvalue => [ "enumname", "enum description" ],
	       # more enum settings ...
	     }

    # mandatory: Descriptive long variable name 
    # for this column. Will be used as an alias
    # for the columname for display or edit/vi.
    var => 'VarName',		

    # mandatory: Textual description what this
    # variable is good for. Will be show up as
    # a comment when displaying (cat) or editing
    # (vi) this file. Long lines can be split with
    # newline '\n'. When this column is 'fnamcol'
    # the text whill show up in header like:
    # "Settings for <desc-here>  <filename>
    desc => "...text...",	

    # mandatory: A counter used to sort the columns
    # for display/editing. Smaller numbers come 
    # first. See example pawactl how to setup.
    pos => NUMBER,		
 },


The COLUMN_TYPE defines, if the column is a normal database column or
a reference to another file in another directory. A column is either a
normal column or a ref-column.

normal column:

    # mandatory: database type for this column. 
    # Allowed types:
    # - when this column acts as the filename ( see 'fnamcol'in
    #   DIRECTORY_SETTING): char
    # - when edit=1 set in DIRECTORY_SETTING: char, int, smallint
    #   and if we have a Postgres backend: inet and cidr also
    # - when edit=0 set in DIRECTORY_SETTING: char, int, smallint,
    #   date, bool, ...
    type => 'dbtype',		

    # optional: length of column. Only usefull 
    # when type => 'char'. Mandatory if this
    # column is used as the filename.
    len => NUMBER,		


ref-column:

    # mandatory: A directory name of another 
    # directory. Allowed values for this variable
    # will be existing filenames from directory 
    # 'dirname' or NULL. rm uses this information
    # to check for references before removing a 
    # file. editing/vi uses this information to
    # check a saved file for valid values.
    ref   => 'dirname',		


=head1 DATABASE CONSTRAINTS

The user can set database constraints for scpecific columns with the
B<colopt> option in B<%vdirs>. FileSystem takes care of these constraints
and reports any errors regarding the use of these constraints to the 
user. Because the errormessages (from the DBI/DBD subsystem) are sometimes
not what the user expects it is a good idea to use column option 'uniq', 
and/or the custom B<rmcheck> and B<valok> functions within B<%vdirs> together 
with database constraints. This has more advantages:

=over 4

=item 1.

When using database constraints the database takes care about integrity. 
Other programs than FileSystem
can not destroy the integrity of the database.

=item 2.

FileSystem uniq-option, B<rmcheck> and B<valok> custom functions report 
'understandable' error messages to the user, they also report the 
errornous line number to the editor after editing and saving an odd file. 
Database errors have no line numbers.

=item 3.

FileSystem functions uniq test, and custom functions B<rmcheck> and B<valok> 
will be called just before a database operation. If they fail, 
the database operation will not take place.

=item 4.

FileSystem may be buggy.

=back


=head1 VERSION INFORMATION

When using FileSystem for managing configuration data for a server
process, you have three versions of database layout in use:

=over 4

=item 1.

database layout given in B<%vdirs> hash

=item 2.

database layout in the database itself

=item 3.

database layout the server process expects

=back

To make sure that all three participants use the same database layout
FileSystem supports a simple version number control. Besides the
tables given in B<%vdirs> FileSystem also creates a table called
'tablestatus'. This table has two columns, B<tag> and B<value>, both
of type char(16). FileSystem inserts one entry 'version' when
recreating the database and inserts the version string given as
parameter to &recreatedb. 

Before doing any operations on the database when calling &mainloop(), 
FileSystem
first checks if the version string given as parameter to &mainloop()
matches the version string from database in table 'tablestatus', row
'version', column 'value'. If they do not match, FileSystem terminates with
an error messages.

When modifying the B<%vdirs> hash it is strongly recommended to
change/increment the version number given to &mainloop() also.  To be
on the safe side you should recreate the database after changing
B<%vdirs>.  Keep in mind that you will loose all data in the tables
when calling &recreatedb(). Alternative way: Modify B<%vdirs> and
increment the version string for the &mainloop() call. Then start your
favourite SQL editor and manually change the database layout according
to B<%vdirs>.

The server
process should take care of the version number in 'tablestatus' also.

=head1 COMMAND SHELL

The command line shell offers command line history, tab completion and
commandline editing by using the functionality by using the installed
readline library. See the manpage B<readline(3)> for details and key bindings.

Supported commands are:

=over 5

=item cat

Usage: 'cat FILE'.
Show a file contents including generated comments. 

=item cd

Usage: 'cd DIR'. Change to directory DIR. The directory hierarchy is flat, 
there is no root
directory. The user can change to any directory any time. You can only
change to directories mentioned in the B<%vdirs> structure. FileSystem
does not analyze the system catalog of the underlying database.

=item cp

Usage: 'cp OLD NEW'. Copy file OLD to file NEW (clone a file). When
copying, the variables marked as 'uniq' will be set to NULL in file
NEW. Requires write access to the directory.

=item help

Usage: 'help [command]'. Show a brief command description.

=item ls

Usage: 'ls'. Show the contents of the current directory. The B<%vdirs>
hash defines, which columns are used as a filename.

=item ld

Usage: 'ld'. Show the contents (dirs and files) of the current directory 
in long format. The B<%vdirs> hash defines, which columns are used as a 
filename. For directories 'ld' will display the directory B<desc> field 
from B<%vdirs>. For files see command 'll' below.

=item ll

Usage: 'll'. Show the contents (files only) of the current directory, 
in long format. The B<%vdirs> hash defines, which columns are used as a 
filename. If B<comcol> (comment column) is set in B<%vdirs>, then 
additionally show the contents of this column for each file. 


=item quit

Usage: 'quit'. Just quit.

=item rm 

Usage: 'rm FILE'. Remove FILE. You can only remove files that are not
referenced. Reference checks are done by FileSystem using the
reference hierarchy given in the B<%vdirs> hash. To un-reference a file
set the reference entry in the referring file to NULL, to another file or
remove the referring file. 'rm' requires write access to the directory.

=item sum

Usage: 'sum FILE'. Show the summary of FILE. The summary only shows
the variables and their values, without any comments. 'sum' knows
about the 'defaultfile': If a FILE has variables = NULL and a
defaultfile is given, then sum shows '->' and the value of the
defaultfile instead of '=' and the value of the variable.

=item ver

Usage: 'ver'. Show version information.


=item vgrep

Usage: 'vgrep PATTERN'. Find a pattern in all files. Find all lines in 
all files in current dir where var/value pair matches PATTERN. Print 
out matching lines. Ignore case when doing pattern matching. 
Regex patterns will be ignored, all metacharacters will be quoted.
vgrep does not search the comments, but only the var=value lines
(like the result of command 'sum')


=item vi

Usage: 'vi FILE'. Edit FILE with an editor. Starts the default editor
given in the shell environment variable $EDITOR. If this is not
defined, it starts C</usr/bin/vi>. After quitting the editor the file
will be checked for proper format and values. If there is something
wrong, the user will be asked to reedit the file or to throwaway the
file. 

In case of reediting a file because
saving was rejected, the editor is started over with '+LINENO' as the
first parameter to let the cursor directly jump to the error line. If
the editor given in $EDITOR does not support this syntax an error will occur.

If FILE does not exist it will be created after saving and quitting the
editor. This is usefull when a column has a 'NOT NULL' constraint.

Note: Only the values will be saved in the database. All comments made
in the file will get lost. If you need comments, add a 'comment'
Variable for this directory in B<%vdirs>.

Note: The file parser currently is very simple. Currently it is not
possible to assign a string of spaces to a variable.

=item wrefs

Usage: 'wrefs FILE'. Show who references FILE. Reference checks are
done by FileSystem using the reference hierarchy given in the B<%vdirs>
hash. Other references to FILE will not be detected because FileSystem
does not read the system catalog of the database. Note: A non-existing
FILE will not be referenced by anyone.

=back



=head1 BUGS

=over 4

=item -

M:N relations currently not supported.

=item -

composite primary keys currently not supported

=item -

The database types 'cidr' and 'inet' are tested with Postgres database
and are expected to work with Postgres only.

=item -

Some database systems dislike the way, DBI uses for quoting the single quote
(Method DBI::quote()). They issue a warning when updating or inserting data
using quoted quotes. Users of the shell will see this warning when saving 
a new or existing file using shell's vi command. PostgreSQL version 8+ is known
to behave like this.

=back


=head1 AUTHOR

Alexander Haderer	afrika@cpan.org

=head1 SEE ALSO

perl(1), DBI(3), dbish(1), readline(3)

=cut
