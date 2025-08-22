#!/usr/bin/env perl

use strict;
use warnings;

use Data::Dumper;
use English qw(no_match_vars);

use Test::More;
use Test::Output;

use_ok('CLI::Simple');

use vars qw(@ARGV);

########################################################################
sub foo {
########################################################################
  print {*STDOUT} 'Hello World!';

  return 0;
}

my @options = qw(
  foo
  bar=s
);

########################################################################
subtest 'logging' => sub {
########################################################################
  CLI::Simple->use_log4perl(level => 'info');

  local @ARGV = qw(--foo --bar=buz foo);

  my $app = CLI::Simple->new( commands => { foo => \&foo }, option_specs => \@options );

  stderr_like(sub { $app->get_logger->info('hello world') }, qr/hello\sworld/xsm);
};

done_testing;

1;

__END__

1;
