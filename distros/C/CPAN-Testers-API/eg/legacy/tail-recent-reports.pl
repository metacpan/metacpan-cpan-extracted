#!/usr/bin/env perl
use 5.010;
use strict;
use warnings;
use lib '/home/ubuntu/perl5/lib/perl5';

use autodie;
use JSON;
use Metabase::Fact              ();
use Metabase::Resource;
use Metabase::User::Profile;
use CPAN::Testers::Fact::TestSummary;
use CPAN::Testers::Metabase::AWS;
use Path::Class;
use Time::Piece;

use Getopt::Lucid ':all';

my $opts = Getopt::Lucid->getopt([
  Param('output|o'),
  Switch('verbose|v'),
  Param('limit|l')->default(250),
]);

my $mb = CPAN::Testers::Metabase::AWS->new(
  bucket => 'cpantesters',
  namespace => 'beta10',
);

my $librarian = $mb->public_librarian;

# my $time = gmtime->subtract($opts->get_hours * 3600)->datetime() . "Z";

say "Searching for last " . $opts->get_limit . " facts" if $opts->get_verbose;

my $guids = $librarian->search(
  'core.type' => 'CPAN-Testers-Fact-TestSummary',
  'core.update_time' => { ">", 0 },
  -desc => 'core.update_time',
  -limit => $opts->get_limit,
);

my $output_fh;
if ( $opts->get_output ) {
  open $output_fh, ">", $opts->get_output . $$;
  binmode( $output_fh, ":encoding(UTF-8)" );
}
binmode( STDOUT, ":encoding(UTF-8)" );

my $header = "The last " . $opts->get_limit 
	. " reports as of " . gmtime->datetime . "Z:";

if ( $output_fh ) {
      say $output_fh $header;
}
else {
      say $header;
}

for my $g ( @$guids ) {
  my $fact = eval { $librarian->extract($g) };
  if ($fact) {
    my $guid = $fact->guid;
    my $content = $fact->content;
    my $resource = $fact->resource;
    my $ts = $fact->update_time;
    my $ct = $fact->creation_time;
    my $fn = creator_name( $fact->creator );
    my $df = $resource->dist_file;
    my $gr = $content->{grade};
    my $ar = $content->{archname};
    my $pv = $content->{perl_version};
    my $msg = "[$ts] [$fn] [$gr] [$df] [$ar] [perl-$pv] [$guid] [$ct]";
    if ( $output_fh ) {
      say $output_fh $msg;
    }
    else {
      say $msg;
    }
  }
  else {
    warn "Error extracting $g\: $@";
  }
}

if ( $opts->get_output ) {
  close $output_fh;
  rename $opts->get_output . $$ => $opts->get_output;
}

my %creator_fn;
sub creator_name {
  my $resource = shift;
  return $creator_fn{$resource} if exists $creator_fn{$resource};
  my $creator = $librarian->extract( $resource->guid );
  my ($fn_fact) = grep { ref $_ eq 'Metabase::User::FullName' } $creator->facts;
    die "Couldn't find FullName" unless $fn_fact;
  return $creator_fn{$resource} = $fn_fact->content;
}
  


