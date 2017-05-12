#!perl -w

use strict;
use if ($] >= 5.011), 'Test::More', 'skip_all' => 'This test is for old perls';
use Test::More tests => 4;
use Test::Exception;

use Data::Util qw(get_code_info install_subroutine);

use Attribute::Handlers;
sub UNIVERSAL::Foo :ATTR(CODE, BEGIN){
	my($pkg, $sym, $subr) = @_;

	lives_ok{
        scalar get_code_info($subr);
	} 'get_code_info()';

	lives_ok{
		no warnings 'redefine';
		install_subroutine 'main', 'foo', $subr;
	} 'install_subroutine()';
}

sub f :Foo;

my $anon = sub :Foo {};
