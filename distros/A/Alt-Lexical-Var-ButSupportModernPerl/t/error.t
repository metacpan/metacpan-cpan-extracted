use warnings;
use strict;

use Test::More tests => 53;

BEGIN { $SIG{__WARN__} = sub { die "WARNING: $_[0]" }; }

require_ok "Lexical::Var";

eval q{ Lexical::Var->import(); };
like $@, qr/\ALexical::Var does no default importation/;
eval q{ Lexical::Var->unimport(); };
like $@, qr/\ALexical::Var does no default unimportation/;
eval q{ Lexical::Var->import('foo'); };
like $@, qr/\Aimport list for Lexical::Var must alternate /;
eval q{ Lexical::Var->import('$foo', \1); };
like $@, qr/\Acan't set up lexical variable outside compilation/;
eval q{ Lexical::Var->unimport('$foo'); };
like $@, qr/\Acan't set up lexical variable outside compilation/;

eval q{ use Lexical::Var; };
like $@, qr/\ALexical::Var does no default importation/;
eval q{ no Lexical::Var; };
like $@, qr/\ALexical::Var does no default unimportation/;

eval q{ use Lexical::Var 'foo'; };
like $@, qr/\Aimport list for Lexical::Var must alternate /;

eval q{ use Lexical::Var undef, \1; };
like $@, qr/\Avariable name is not a string/;
eval q{ use Lexical::Var \1, sub{}; };
like $@, qr/\Avariable name is not a string/;
eval q{ use Lexical::Var undef, "wibble"; };
like $@, qr/\Avariable name is not a string/;

eval q{ use Lexical::Var 'foo', \1; };
like $@, qr/\Amalformed variable name/;
eval q{ use Lexical::Var '$', \1; };
like $@, qr/\Amalformed variable name/;
eval q{ use Lexical::Var '$foo(bar', \1; };
like $@, qr/\Amalformed variable name/;
eval q{ use Lexical::Var '$1foo', \1; };
like $@, qr/\Amalformed variable name/;
eval q{ use Lexical::Var '$foo\x{e9}bar', \1; };
like $@, qr/\Amalformed variable name/;
eval q{ use Lexical::Var '$foo::bar', \1; };
like $@, qr/\Amalformed variable name/;
eval q{ use Lexical::Var '!foo', \1; };
like $@, qr/\Amalformed variable name/;
eval q{ use Lexical::Var 'foo', "wibble"; };
like $@, qr/\Amalformed variable name/;

eval q{ use Lexical::Var '$foo', "wibble"; };
like $@, qr/\Avariable is not scalar reference/;

eval q{ no Lexical::Var undef, \1; };
like $@, qr/\Avariable name is not a string/;
eval q{ no Lexical::Var \1, sub{}; };
like $@, qr/\Avariable name is not a string/;
eval q{ no Lexical::Var undef, "wibble"; };
like $@, qr/\Avariable name is not a string/;

eval q{ no Lexical::Var 'foo', \1; };
like $@, qr/\Amalformed variable name/;
eval q{ no Lexical::Var '$', \1; };
like $@, qr/\Amalformed variable name/;
eval q{ no Lexical::Var '$foo(bar', \1; };
like $@, qr/\Amalformed variable name/;
eval q{ no Lexical::Var '$foo::bar', \1; };
like $@, qr/\Amalformed variable name/;
eval q{ no Lexical::Var '!foo', \1; };
like $@, qr/\Amalformed variable name/;

require_ok "Lexical::Sub";

eval q{ Lexical::Sub->import(); };
like $@, qr/\ALexical::Sub does no default importation/;
eval q{ Lexical::Sub->unimport(); };
like $@, qr/\ALexical::Sub does no default unimportation/;
eval q{ Lexical::Sub->import('foo'); };
like $@, qr/\Aimport list for Lexical::Sub must alternate /;

eval q{ use Lexical::Sub; };
like $@, qr/\ALexical::Sub does no default importation/;
eval q{ no Lexical::Sub; };
like $@, qr/\ALexical::Sub does no default unimportation/;

eval q{ use Lexical::Sub 'foo'; };
like $@, qr/\Aimport list for Lexical::Sub must alternate /;

eval q{ use Lexical::Sub undef, sub{}; };
like $@, qr/\Asubroutine name is not a string/;
eval q{ use Lexical::Sub sub{}, \1; };
like $@, qr/\Asubroutine name is not a string/;
eval q{ use Lexical::Sub undef, "wibble"; };
like $@, qr/\Asubroutine name is not a string/;

eval q{ use Lexical::Sub '$', sub{}; };
like $@, qr/\Amalformed subroutine name/;
eval q{ use Lexical::Sub 'foo(bar', sub{}; };
like $@, qr/\Amalformed subroutine name/;
eval q{ use Lexical::Sub '1foo', sub{}; };
like $@, qr/\Amalformed subroutine name/;
eval q{ use Lexical::Sub 'foo\x{e9}bar', sub{}; };
like $@, qr/\Amalformed subroutine name/;
eval q{ use Lexical::Sub 'foo::bar', sub{}; };
like $@, qr/\Amalformed subroutine name/;
eval q{ use Lexical::Sub '!foo', sub{}; };
like $@, qr/\Amalformed subroutine name/;

eval q{ use Lexical::Sub 'foo', "wibble"; };
like $@, qr/\Asubroutine is not code reference/;

eval q{ no Lexical::Sub undef, sub{}; };
like $@, qr/\Asubroutine name is not a string/;
eval q{ no Lexical::Sub sub{}, \1; };
like $@, qr/\Asubroutine name is not a string/;
eval q{ no Lexical::Sub undef, "wibble"; };
like $@, qr/\Asubroutine name is not a string/;

eval q{ no Lexical::Sub '$', sub{}; };
like $@, qr/\Amalformed subroutine name/;
eval q{ no Lexical::Sub 'foo(bar', sub{}; };
like $@, qr/\Amalformed subroutine name/;
eval q{ no Lexical::Sub 'foo::bar', sub{}; };
like $@, qr/\Amalformed subroutine name/;
eval q{ no Lexical::Sub '!foo', sub{}; };
like $@, qr/\Amalformed subroutine name/;

1;
