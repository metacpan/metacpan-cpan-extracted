#!/usr/bin/env perl

# vim: tabstop=4 expandtab

###### PACKAGES ######

use Modern::Perl;
use Data::Printer alias => 'pdump';
use CLI::Driver;
use Test::More;

use Getopt::Long;
Getopt::Long::Configure('no_ignore_case');
Getopt::Long::Configure('pass_through');
Getopt::Long::Configure('no_auto_abbrev');

###### CONSTANTS ######

use constant REQ_ATTR_VALUE => 'foo';
use constant OPT_ATTR_VALUE => 'bar';
use constant REQ_ARG_VALUE  => 'biz';
use constant OPT_ARG_VALUE  => 'baz';

###### GLOBALS ######

use vars qw(
  $Driver
);

###### MAIN ######

unshift @INC, 't/lib';

$| = 1;

#test11:
#  desc: "test cli-driver-v2 with optionals"
#  class:
#    name: CLI::Driver::Test3
#    attr:
#      required:
#        h: reqattr
#      optional:
#        o: optattr
#      flags:
#  method:
#    name: test11_method
#    args:
#      required:
#        a: reqarg
#      optional:
#        b: optarg
#      flags:

$Driver = CLI::Driver->new(
	path     => 't/etc',
	file     => 'cli-driver.yml',
	argv_map => {
		reqattr => REQ_ATTR_VALUE,
		optattr => OPT_ATTR_VALUE,
		reqarg  => REQ_ARG_VALUE,
		optarg  => OPT_ARG_VALUE
	}
);

###

my $action = $Driver->get_action( name => 'test11' );
ok($action);

my $result;
eval { $result = $action->do };
ok( !$@ );

my $opt = _find_option( $action->class->attr, 'reqattr' );
ok( $opt->value eq REQ_ATTR_VALUE );

$opt = _find_option( $action->class->attr, 'optattr' );
ok( $opt->value eq OPT_ATTR_VALUE );

$opt = _find_option( $action->method->args, 'reqarg' );
ok( $opt->value eq REQ_ARG_VALUE );

$opt = _find_option( $action->method->args, 'optarg' );
ok( $opt->value eq OPT_ARG_VALUE );

done_testing();

###### END MAIN ######

sub _find_option {
	my $aref     = shift;
	my $arg_name = shift;

	foreach my $opt (@$aref) {
		if ( $opt->method_arg eq $arg_name ) {
			return $opt;
		}
	}
}
