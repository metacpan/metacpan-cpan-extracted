#!/usr/bin/env perl
use lib '../lib';

use Data::Tubes qw< drain summon >;

# Load components from relevant plugins
summon(
   qw<
     +Plumbing::sequence
     +Source::iterate_files
     +Reader::read_by_line
     +Parser::parse_hashy
     +Renderer::render_with_template_perlish
     +Writer::write_to_files
     >
);

# define a tube made of a sequence of tubes, each of the relevant
# type and doing its specific job.
my $sequence = sequence(
   tubes => [
      iterate_files(\"n=Flavio|q=how are you\nn=X|q=Y"),
      read_by_line(),
      parse_hashy(chunks_separator => '|'),
      render_with_template_perlish(template => "Hi [% n %], [% q %]?\n"),
      write_to_files(filename => \*STDOUT),
   ]
);

# just "drain" whatever comes out of the tube, we're not really
# interesting in collecting output records as they are already
# written by write_to_file. This is necessary so that the actions are
# actually "run", as of now $sequence is only a promise to do some
# work.
drain($sequence);
