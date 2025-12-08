#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use Data::Dumper;
use English qw(-no_match_vars);

my %tests = (
  foo            => 'ssm://rds/mysql/host',
  bar            => 'ssm://rdxs/mysql/user',
  biz            => 'buz',
  level          => '${loglevel}',
  log4perl_level => '${loglevel == 5 ? "DEBUG" : "INFO"}',
  database       => '${env eq "prod" ? database.prod : database.dev}',
);

use_ok('Config::Resolver');

my $resolver = Config::Resolver->new( debug => 0, plugins => [] );

########################################################################
subtest 'resolve SSM parameter' => sub {
########################################################################
  SKIP: {
    skip 'no ssm', 1 if !$ENV{TEST_SSM};

    my $ref = $resolver->resolve( { foo => $tests{foo} } );

    is( $ref->{foo}, 'mysql-host' );
  }

};

########################################################################
subtest 'not found SSM parameter (warn)' => sub {
########################################################################
  SKIP: {
    skip 'no ssm', if !$ENV{TEST_SSM};

    local $SIG{__WARN__} = sub { };

    $resolver->set_warning_level('warn');

    my $ref = $resolver->resolve( { bar => $tests{bar} } );

    is( $ref->{bar}, q{} );

    $resolver->set_warning_level('error');

    $ref = eval { return $resolver->resolve( { bar => $tests{bar} } ); };

    ok( !$ref && $EVAL_ERROR, 'warn => error' );
  }

};

########################################################################
subtest 'constant' => sub {
########################################################################
  my $ref = $resolver->resolve( { biz => $tests{biz} }, { biz => 'buz' } );

  is( $ref->{biz}, $tests{biz} );
};

########################################################################
subtest 'lookup' => sub {
########################################################################
  my $ref = $resolver->resolve( { level => $tests{level} }, { loglevel => 4 } );

  is( $ref->{level}, 4 );
};

########################################################################
subtest 'ternary' => sub {
########################################################################
  my $ref = $resolver->resolve( { log4perl_level => $tests{log4perl_level} }, { loglevel => 4 } );

  is( $ref->{log4perl_level}, 'INFO' );

  my $result = $resolver->resolve(
    $tests{database},
    { env      => 'prod',
      database => {
        prod => 'PROD',
        dev  => 'DEV'
      }
    }
  );

  is( $result, 'PROD', 'using parameter hash' );
};

done_testing;

1;
