# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Contextual-Return-Wrapper.t'

#########################

# change 'tests => 2' to 'tests => last_test_to_print';

package main::one ;
use parent qw( Contextual::Return::Wrapper Exporter ) ;

use vars qw( @EXPORT ) ;

@EXPORT = qw( lowercase ) ;

sub lowercase : ReturnContext( requires => 'scalar', scalar => 'first' ) {
	return map { lc $_ } @_ ;
	}

package main ;
use Test::More tests => 2 ;

main::one->import ;

my $warnings ;
my $warnct ;
my @results ;
my @args = qw( Jim John ) ;

close STDERR ;
open STDERR, '>', \$warnings ;

push @results, scalar lowercase( @args ) ;
is( $results[-1], 'jim', 'scalar => first' ) ;
lowercase( @args ) ;
is( ( scalar split /\n/, $warnings ), ++$warnct, 'requires => scalar' ) ;

1 ;
