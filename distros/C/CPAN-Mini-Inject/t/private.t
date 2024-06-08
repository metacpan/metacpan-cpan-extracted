#!perl

use strict;
use warnings;

use CPAN::Mini::Inject;
use Test::More;

subtest '_fmtmodule' => sub {
  my @tests = (
    {
      in => [ 'foo', 'foo.tar.gz', '0.01' ],
      out => 'foo                                0.01  foo.tar.gz',
    },
    {
      in => [
        'fooIsAModuleWithAReallyLongNameSoLong'
         . 'InFactThatItScrewsWithTheFormatting',
        'foo.tar.gz',
        '0.01'
      ],
      out => 'fooIsAModuleWithAReallyLongNameSoLong'
       . 'InFactThatItScrewsWithTheFormatting 0.01  foo.tar.gz',
    },
  );
  for my $test ( @tests ) {
    my $got = CPAN::Mini::Inject::_fmtmodule( @{ $test->{in} } );
    is $got, $test->{out}, '_fmtmodule';
  }
};

done_testing();
