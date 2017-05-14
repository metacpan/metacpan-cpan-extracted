#!/usr/bin/env perl

use warnings;
use strict;

use Data::Dumper;
use Carp;

use 5.010;

use Getopt::Long::Descriptive;
use Bio::Gonzales::Search::IO::BLAST qw/makeblastdb/;
use File::Temp qw/tempdir tempfile/;

use constant {
  BLAST_CMD => 0,
  ALPHABET  => 1
};

our %blast_type = (
  n  => [ 'blastn',  'n' ],
  p  => [ 'blastp',  'p' ],
  tn => [ 'tblastn', 'n' ],
  tx => [ 'tblastx', 'n' ],
  x  => [ 'blastx',  'p' ]
);

my ( $opt, $usage ) = describe_options(
  "%c %o <query> <subject>\n" . "%c %o --db_only <subject>\n",
  [],
  [ 'verbose|v', "print extra stuff" ],
  [ 'db_only'     => 'create only the database, do not run any blast cmd' ],
  [ 'db_prefix=s' => 'set this as db_prefix for the blast db name' ],
  [
    "type" => hidden => {
      one_of => [
        [ 'n',  'use blastn' ],
        [ 'p',  'use blastp' ],
        [ 'tn', 'use tblastn' ],
        [ 'tx', 'use tblastx' ],
        [ 'x',  'use blastx' ],
      ],
      required => 1,

    }
  ],
  [ 'use_db=s' => 'use preexisting database' ],
  [ 'opt|o=s@', "add these options to the blast search, e.g. --opt '-evalue 10e-5'" ],
  [ 'help',     "print usage message and exit" ],
  [ 'wd=s',     "set working dir, use temp dir as default" ],
);

print( $usage->text ), exit if $opt->help;

my $dir = $opt->wd // tempdir( CLEANUP => 1 );

my ( $qfile, $sfile ) = @ARGV;

if ( $opt->use_db ) {
  say STDERR "Using existing db " . $opt->use_db;

} elsif ( $opt->db_only && $qfile && -f $qfile ) {
  $sfile = $qfile;
} else {
  map { confess $_ ? "$_ does not exist" : "no files given" unless ( $_ && -f $_ ); } ( $qfile, $sfile );
}

my $db_location;
if ( $opt->use_db ) {
  $db_location = $opt->use_db;
} else {
  my $opts = {
    seq_file   => $sfile,
    alphabet   => $blast_type{ $opt->type }[ALPHABET],
    wd         => $dir,
    hash_index => 0
  };
  $opts->{db_prefix} = $opt->db_prefix if ( $opt->db_prefix );
  $db_location = makeblastdb($opts);
}

exit if ( $opt->db_only );

my @cmd;
push @cmd, $blast_type{ $opt->type }[BLAST_CMD], '-db', $db_location, '-query', $qfile;

push @cmd, '-verbose' if ( $opt->verbose );
push @cmd, map { split /\s+/, $_, 2 } @{ $opt->opt } if ( $opt->opt );
say STDERR join( " ", @cmd );
system(@cmd);
