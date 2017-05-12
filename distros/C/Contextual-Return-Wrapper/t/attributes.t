# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Contextual-Return-Wrapper.t'

#########################

# change 'tests => 2' to 'tests => last_test_to_print';

use Test::More tests => 18 ;
use base 'Contextual::Return::Wrapper' ;

__PACKAGE__->import ;

## scalar

sub scalar_lowercase : ReturnContext( scalar => 'first' ) {
	return map { lc $_ } @_ ;
	}

sub scalar_uppercase : ReturnContext scalar last {
	return map { uc $_ } @_ ;
	}

sub scalar_stringlength : ReturnContext( 'scalar', 'count' ) {
	return map { length $_ } @_ ;
	}

sub scalar_secondchar : ReturnContext( qw( scalar arrayref ) ) {
	return map { substr $_, 1, 1 } @_ ;
	}

sub scalar_firstchar : ReturnContext( scalar => 'warn' ) {
	return map { substr $_, 0, 1 } @_ ;
	}

sub scalar_thirdchar : ReturnContext( requires => 'scalar', scalar => 'first' )
{
	return map { substr $_, 2, 1 } @_ ;
	}

sub void_lowercase : ReturnContext( void => 'warn' ) {
	return map { lc $_ } @_ ;
	}

sub void_uppercase : ReturnContext( requires => 'void' ) {
	return map { uc $_ } @_ ;
	}

sub array_lowercase : ReturnContext( requires => 'array' ) {
	return map { lc $_ } @_ ;
	}

sub listify_lowercase : Listify {
	return map { lc $_ } @_ ;
	}

my $warnings ;
my $warnct ;

close STDERR ;
open STDERR, '>', \$warnings ;
my @results ;

my @args = qw( Jim John ) ;

push @results, scalar scalar_lowercase( @args ) ;
is( $results[-1], 'jim', 'scalar => first' ) ;

push @results, scalar scalar_uppercase( @args ) ;
is( $results[-1], 'JOHN', 'scalar => last' ) ;

push @results, scalar scalar_stringlength( @args ) ;
is( $results[-1], 2, 'scalar => last' ) ;

push @results, scalar scalar_secondchar( @args ) ;
is( ref $results[-1], 'ARRAY', 'scalar => arrayref' ) ;

push @results, scalar scalar_firstchar( @args ) ;
is( $results[-1], 2, 'scalar => warn -1' ) ;
is( ( scalar split /\n/, $warnings ), ++$warnct, 'scalar => warn -2' ) ;

push @results, scalar scalar_thirdchar( @args ) ;
is( $results[-1], 'm', 'requires => scalar -1' ) ;
push @results, scalar_thirdchar( @args ) ;
is( ( scalar split /\n/, $warnings ), ++$warnct, 'requires => scalar -2' ) ;
scalar_thirdchar( @args ) ;
is( ( scalar split /\n/, $warnings ), ++$warnct, 'requires => scalar -3' ) ;

void_lowercase( @args ) ;
is( ( scalar split /\n/, $warnings ), ++$warnct, 'void => warn -1' ) ;
scalar void_lowercase( @args ) ;
is( ( scalar split /\n/, $warnings ), $warnct, 'void => warn -2' ) ;

void_uppercase( @args ) ;
is( ( scalar split /\n/, $warnings ), $warnct, 'requires => void -1' ) ;
push @results, scalar void_uppercase( @args ) ;
is( ( scalar split /\n/, $warnings ), ++$warnct, 'requires => void -2' ) ;
push @results, void_uppercase( @args ) ;
is( ( scalar split /\n/, $warnings ), ++$warnct, 'requires => void -3' ) ;

array_lowercase( @args ) ;
is( ( scalar split /\n/, $warnings ), ++$warnct, 'requires => array -1' ) ;
push @results, scalar array_lowercase( @args ) ;
is( ( scalar split /\n/, $warnings ), ++$warnct, 'requires => array -2' ) ;
push @results, array_lowercase( @args ) ;
is( ( scalar split /\n/, $warnings ), $warnct, 'requires => array -3' ) ;

push @results, listify_lowercase( @args ) ;
is( $results[-1], 'john', 'requires => listify' ) ;

1 ;
