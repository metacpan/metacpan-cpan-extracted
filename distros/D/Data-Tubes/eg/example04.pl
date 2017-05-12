#!/usr/bin/env perl
use strict;
use warnings;
use lib '../lib';
use Data::Tubes qw< pipeline >;

my $id   = 0;
my $tube = pipeline(

   # automatic loading for simple cases
   (
      qw<
        Plumbing::sequence
        Source::iterate_files
        Reader::by_line
        Parser::hashy
        >,
   ),

   # a tube is a sub with a contract on the return value
   sub {
      my $record = shift;
      $record->{structured}{id} = $id++;
      return $record;
   },

   # automatic loading with arguments
   ['Renderer::with_template_perlish', ['example04.tp']],
   ['Writer::to_files', header => "---\n", footer => "...\n"],

   # options for tube, in this case just pour into the sink
   {tap => 'sink'}
);

my $input = <<'END';
a=Harry b=Sally
a=Jekyll b=Hide
a=Flavio b=Silvia
a=some b=thing
END
$tube->([\$input]);
