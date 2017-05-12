use Test::More tests => 4;

use strict; use warnings;

my $this_class = 'Bot::Cobalt::Logger::Output::Term';

use_ok( $this_class );

my $output = new_ok( $this_class );

my $stdout;
{
  local *STDOUT;
  open STDOUT, '>', \$stdout
    or die "Could not reopen STDOUT: $!";

  ok( $output->_write("This is a test string"), '_write()' );

  close STDOUT;
}

cmp_ok( $stdout, 'eq', "This is a test string" );
