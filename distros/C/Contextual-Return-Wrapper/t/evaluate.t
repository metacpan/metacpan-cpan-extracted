# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Contextual-Return-Wrapper.t'

#########################

# change 'tests => 2' to 'tests => last_test_to_print';

use Test::More tests => 4 ;

## scalar

my $evalok ;
my $eval_me =<<'eof' ;
  use base 'Contextual::Return::Wrapper' ;

  sub scalar_thirdchar : ReturnContext( requires => 'scalar', scalar => 'first' ) {
	return map { substr $_, 2, 1 } @_ ;
	}

  main->import ;

  $evalok = 'ok' ;
eof

eval $eval_me ;
is( $evalok, 'ok', 'eval: '.$evalok ) ;

my $warnings ;
my $warnct ;

close STDERR ;
open STDERR, '>', \$warnings ;
my @results ;

my @args = qw( Jim John ) ;

push @results, scalar scalar_thirdchar( @args ) ;
is( $results[-1], 'm', 'requires => scalar -1' ) ;
push @results, scalar_thirdchar( @args ) ;
is( ( scalar split /\n/, $warnings ), ++$warnct, 'requires => scalar -2' ) ;
scalar_thirdchar( @args ) ;
is( ( scalar split /\n/, $warnings ), ++$warnct, 'requires => scalar -3' ) ;

1 ;
