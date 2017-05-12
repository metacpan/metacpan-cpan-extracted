#!perl -w

use strict;

use Benchmark qw(:all);

use FindBin qw($Bin);
use lib $Bin, "$Bin/../example/lib";
use Common;

use Data::Util qw(:all);

signeture
	'Data::Util'    => \&install_subroutine,
	'Sub::Exporter' => \&Sub::Exporter::import,
	'Exporter'      => \&Exporter::import,
;

BEGIN{
	package SE;
	use Sub::Exporter -setup => {
		exports => [qw(foo bar baz hoge fuga piyo)],
	};
	$INC{'SE.pm'} = __FILE__;

	package SEL;
	use Sub::Exporter::Lexical
		exports => [qw(foo bar baz hoge fuga piyo)],
	;
	$INC{'SEL.pm'} = __FILE__;

	package E;
	use Exporter qw(import);
	our @EXPORT = qw(foo bar baz hoge fuga piyo);

	$INC{'E.pm'} = __FILE__;
}

cmpthese timethese -1 => {
	'S::Exporter' => sub{
		package A;
		eval q{ use SE; };
	},
	'S::E::Lexical' => sub{
		package B;
		eval q{ use SEL; };
	},
	'Exporter' => sub{
		package C;
		eval q{ use E; };
	},
}
	