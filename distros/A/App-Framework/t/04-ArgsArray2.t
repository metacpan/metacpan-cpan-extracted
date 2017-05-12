#!/usr/bin/perl
#
use strict ;
use Test::More;

use App::Framework '+Args(open=none)' ;

# VERSION
our $VERSION = '2.00' ;

my $DEBUG=0;
my $VERBOSE=0;

	my $stdout="" ;
	my $stderr="" ;

	diag( "Testing args (array no-check)" );

	plan tests => 1 ;

	## This should work	
	my $app = App::Framework->new('exit_type'=>'die',
		'feature_config' => {
			'Args'	=> {
				'debug'	=> 0,
			}
		},
	) ;

	@ARGV = () ;
	eval {
		local *STDOUT ;
		local *STDERR ;

		open(STDOUT, '>', \$stdout)  or die "Can't open STDOUT: $!" ;
		open(STDERR, '>', \$stderr) or die "Can't open STDERR: $!";
		$app->go() ;
	};
	print "reply: $stdout\n" ;
	unlike($stdout, qr/Error: Must specify/i, "Input array checking") ;

	$@ =~ s/Died.*//m if $@ ;
	print "$@" if $@ ;



#=================================================================================
# SUBROUTINES EXECUTED BY APP
#=================================================================================

#----------------------------------------------------------------------
# Main execution
#
sub app
{
	my ($app, $opts_href, $args_href) = @_ ;

}

#=================================================================================
# SUBROUTINES
#=================================================================================



#=================================================================================
# SETUP
#=================================================================================
__DATA__

[SUMMARY]

Tests named args handling

[ARGS]

* array=f*		All args are input files


[DESCRIPTION]

B<$name> does some stuff.

