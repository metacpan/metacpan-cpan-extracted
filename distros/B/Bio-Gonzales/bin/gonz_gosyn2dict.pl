#!/usr/bin/env perl

use warnings;
use strict;

use Data::Dumper;
use Carp;

use 5.010;

use Bio::Gonzales::Util::Cerial;
use List::MoreUtils qw/uniq/;
use Bio::Gonzales::GO::Util qw/get_recursive_related_terms_by_types/;
use Data::Stag;

use GO::Parser;
use GO::Model::Graph;
use Try::Tiny;

use Getopt::Long::Descriptive;

my ( $opt, $usage ) = describe_options(
  '%c %o <obo file>',
  [
    "format" => hidden => {
      one_of => [ [ "json|j" => "output in json format" ], [ "yaml|y" => "output in yaml format" ], ],
      default => 'json'
    }
  ],
  [ 'alt_id',        'include alternative ids' , { default => 1}],
  [ 'syn',           'include synonyms' , { default => 1}],
  [ 'all_types',     'also include (negatively/positively) regulates parent/child relations' ],
  [ 'namespace|n=s', 'restrict to certain namespace' ],
  [ 'verbose|v',     "print extra stuff" ],
  [ 'help',          "print usage message and exit" ],
);

print( $usage->text ), exit if $opt->help;

my $file = shift;
die "$file is no file" unless ( -f $file );

my $errhandler = Data::Stag->getformathandler('xml');
$errhandler->fh( \*STDERR );

my $parser = get_parser($file);
$parser->errhandler($errhandler);

my %go;

$parser->parse($file);    # parse file -> objects
my $graph = $parser->handler->graph;    # get L<GO::Model::Graph> object

my @terms;
if ( $opt->namespace ) {
  @terms = grep { $_->namespace eq $opt->namespace } @{ $graph->get_all_terms };
} else {
  @terms = @{ $graph->get_all_terms };
}

my $types = [qw/is_a part_of/];

if ( $opt->all_types ) {
  undef $types;
}

for my $t (@terms) {
  if ( $t->acc !~ /^GO:/ ) {
    say STDERR Dumper $t;
    next;
  }

  my @re1l_terms;
  for my $alt_id ( grep {/^GO:/} @{ $t->alt_id_list } ) {
    # no alternative ids wanted
    last unless ( $opt->alt_id );
    $go{$alt_id} = $t->acc;
  }

  for my $syn ( grep {/^GO:/} @{ $t->synonym_list } ) {
    # no alternative ids wanted
    last unless ( $opt->syn );
    $go{$syn} = $t->acc;
  }
}
$errhandler->finish;

if ( $opt->format eq 'json' ) {
  jspew( \*STDOUT, \%go );
} elsif ( $opt->format eq 'yaml' ) {
  yspew( \*STDOUT, \%go );
}

sub get_parser {
  my $f = shift;

  my $fmt;
  my $handler;
  if ( $f =~ /\.obo$/ ) {
    $fmt     = 'obo_text';
    $handler = 'obj';
  } elsif ( $f =~ /\.xml$/ ) {
    $fmt     = 'obo_xml';
    $handler = 'xml';
  } elsif ( $f =~ /\.obo-xml$/ ) {
    $fmt     = 'obo_xml';
    $handler = 'obj';
  } else {
    die "could not figure out format of obo file";
  }
  my $parser = GO::Parser->new( { handler => $handler, format => $fmt } );
  #$parser->litemode(1);

  return $parser;
}
