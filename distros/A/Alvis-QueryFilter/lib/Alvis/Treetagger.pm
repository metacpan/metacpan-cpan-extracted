#!/usr/bin/perl -w
package Alvis::Treetagger;

#  must hardwire the root directory for Treetagger below
#  error handling somewhat haphazard, and no auto restart
#  of treetagger if it shutsdown

$Alvis::Treetagger::VERSION = '0.1';

use strict;
use warnings;
use encoding 'utf8';
use open ':utf8';
binmode STDERR, ":utf8";

our $commandLine;
our $taggerRoot;
our $FIFO;
our $parFile;
our $errorFile;
our $verbose;

my $tagpid;

INIT {

  #   note that to get tagger to work without buffer hangs, 
  #   we need to stuff an extra two ".\n" at the end of each input;
  #   this requires we can eliminate the extra output as it comes;
  #   so don't fiddle with this format unless you
  #   fix up the output filtering too
  $commandLine = " -token -lemma -sgml";

  $taggerRoot = "/usr/local/treetagger";
  $FIFO = "/tmp/treetagger_$$";
  $parFile = "english.par";
  $verbose = 0;
  
}   #INIT

sub reopen() {
  
  #  paranoid step
  &Alvis::Treetagger::shut();

  if ( system('mkfifo',"$FIFO.in") || system('mkfifo',"$FIFO.out")  ) { 
    print STDERR "Cannot create pipes $FIFO.in or $FIFO.in\n";
    exit(1);
  }
  
  $tagpid = fork();
  if ( !$tagpid ) {
    #child
    if ( $verbose ) { print STDERR "Starting treetagger\n"; }
    my $execline = 
	"$taggerRoot/bin/tree-tagger $taggerRoot/lib/$parFile $commandLine"
         . " < $FIFO.in > $FIFO.out";
    if ( defined($errorFile) ) {
	$execline .= " 2>$errorFile ";
    }
    exec($execline);
  }
  sleep(1);
  
  if ( $verbose ) { print STDERR "Starting fifo input $FIFO.in\n"; }
  open(FI,">$FIFO.in");
  select((select(FI), $| = 1)[0]);

  #  send some stuff down the pipe to warm it up;
  #  note we add to extra "\n." two evey message
  #  to force TreeTagger to run the buffer
  print FI "Start\nup\nnow\n.\n.\n.\n";
  
  if ( $verbose ) { print STDERR "Starting fifo output $FIFO.out\n"; }
  open(FO,"<$FIFO.out");
  
  $_=<FO>; $_.=<FO>; $_.=<FO>; $_.=<FO>;
}

sub shut() {
  #  closing the input file for tagger will
  #   also shut it down gracefully
  close(FI);
  close(FO);
  unlink("$FIFO.in");
  unlink("$FIFO.out");
  $tagpid = undef;
  if ( $verbose ) { print STDERR "Shutdown fifos\n"; }
}

#  returns undef on a failure and a full reopen()
#  should be done
#  input will be carriage return delimited, as
#  Treetagger requires;
#  should be properly tokenised prior to use
sub tag() {
  if ( ! $tagpid ) {
	 print STDERR "Treetagger not opened\n";
	exit(1);
  }

  $_ = join("\n",split(/\s+/,shift())) . "\n.\n.\n.\n";

  if ( $verbose>1 ) { print "Writing " . join("#",split(/\n/,$_)) . "\n"; }
  
  if ( ! print(FI $_) ) {
    Alvis::Treetagger::shut();
    return undef;
  }

  #  first skip over initial "." from previous output forcing
  while ( defined($_=<FO>) && $_ =~ /^\.\t/ ) {
    ;
  }
  if ( ! defined($_) ) {
    Alvis::Treetagger::shut();
    return undef;
  }

  #  now pick up the results
  my $result = $_;  
  while ( defined($_=<FO>) && $_ !~ /^\.\t/ ) {
    $result .= $_;
  }
  if ( ! defined($_) ) {
    Alvis::Treetagger::shut();
    return undef;
  }  
  if ( $verbose>1 ) { print "Received: $result\n"; }
  return $result;
}

1;

__END__

=head1 NAME

Alvis::Treetagger - Perl module providing FIFO interface to Treetagger

=head1 SYNOPSIS

     $tagginglines = &Alvis::Treetagger::tag($linetotag);

=head1 DESCRIPTION

Interface to TreeTagger so it can be run efficiently via FIFOs.
Thus the Treetagger executable is already started up and loaded so the
&Alvis::Treetagger::tag() function can operate with a minimum of effort.
TreeTagger needs to have already been installed separately.
Note all input and output is assumed to be UTF-8, so character
set conversion required if something else is in use.

=head1 METHODS

=head2 $commandLine

Command line arguments for TreeTagger.
Defaults to "-token -lemma -sgml".

=head2 $errorFile

Where to place Treetaggers STDERR.  Goes to STDERR by default,
but otherwise set to a filename prior to opening.

=head2 $FIFO

Stem for the read/write FIFOs running Treetagger.  Defaults
to "/tmp".

=head2 $parFile

Name of parameter file to use in the Treetagger "lib/" directory.
Defaults to English, "english.par".

=head2 $taggerRoot

Location of Treetagger directory with executables ("bin/"), 
libraries ("lib/"), configure files, etc.
Should be set during installation.

=head2 $verbose

Set for more reports to STDERR during operation.

=head2 reopen()

    &Alvis::Treetagger::reopen();

Open the FIFO's and start and warm up the Treetagger process.

=head2 shut()

    &Alvis::Treetagger::shut();

Shutdown the FIFO's and the Treetagger process.

=head2 tag()

    $tagginglines = &Alvis::Treetagger::tag($linetotag);

Input text should have been tokenised, and is assumed
space delimited.  So "End." is one token with a "." being the
fourth character.  Output text is one token per line,
with its parts tab delimited giving
the original token, its part of speech, and then its lemmatised form.
Shuts down treetagger and returns undef if an error occurs.

=head1 AUTHOR

Wray Buntine

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 Wray Buntine

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either
version 2 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

=cut
