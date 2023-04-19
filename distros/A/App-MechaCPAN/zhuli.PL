#!/usr/bin/env perl

use strict;
use warnings;

use 5.010000;

use autodie;
use FindBin;
use Pod::Simple;
use File::Find;

open my $ouFH, '>', $ARGV[0];
my $prefix = "$FindBin::Bin/lib/";
my @files;
find(
  {
    wanted => sub
    {
      my $file = $_;
      if ( -f $file && $file =~ m/^[^.] .* [.]pm$/xms )
      {
        warn "Will include '$file' in '$ARGV[0]'\n";
        my $filename = $File::Find::name;
        $filename =~ s[^$prefix][]xms;
        push @files, $filename;
        $ouFH->say("BEGIN { \$INC{'$filename'} = __FILE__ };");
      }
    },
  },
  $prefix
);

foreach my $file (sort @files)
{
  my $parser = Pod::Simple->new;

  my $in_end;
  $parser->cut_handler(
    sub
    {
      my $line        = shift;
      my $line_number = shift;
      my $parser      = shift;
      $ouFH->say(qq{# line $line_number "$file"})
        unless $in_end;
    }
  );
  $parser->code_handler(
    sub
    {
      my $line        = shift;
      my $line_number = shift;
      my $parser      = shift;
      $in_end = 1
        if $line =~ m/^__END__/xms;
      $ouFH->say($line)
        unless $in_end;
    }
  );
  $ouFH->say(qq{# line 1 "$file"});
  $parser->parse_file("$prefix/$file");
}

open my $mc_fh, "<", "$FindBin::Bin/script/mechacpan";
$ouFH->say("package main;");
$ouFH->say(do { local $/; <$mc_fh> });
