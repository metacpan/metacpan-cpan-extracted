# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 86 };
use C::Sharp;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

eval "use C::Sharp::Tokener";

ok(!$@);

$_='
public override int parse ()
{
    StringBuilder value = new StringBuilder ();
    // Some test 
    global_errors = 0;
    try { /* Foo! */
        if (yacc_verbose_flag)
            yyparse (lexer, new yydebug.yyDebugSimple ());
        else
            yyparse (lexer);
    } catch (Exception e){
        Console.WriteLine ("Fatal error: "+name);
        Console.WriteLine (e);
        Console.WriteLine (lexer.location);
        global_errors++;
    }

    return global_errors;
}

';

undef $/;

@expected = split /\n/, <DATA>;
while ($_) {
    ($token, $ttype, $_) = C::Sharp::Tokener::tokener($_);
    my ($etoken, $etype) = splice(@expected,0,2);
    ok($token eq $etoken and $ttype eq $etype);
}

__DATA__
public
PUBLIC
override
OVERRIDE
int
INT
parse
IDENTIFIER
(
(
)
)
{
{
StringBuilder
IDENTIFIER
value
IDENTIFIER
=
=
new
NEW
StringBuilder
IDENTIFIER
(
(
)
)
;
;
global_errors
IDENTIFIER
=
=
0
LITERAL_INTEGER
;
;
try
TRY
{
{
if
IF
(
(
yacc_verbose_flag
IDENTIFIER
)
)
yyparse
IDENTIFIER
(
(
lexer
IDENTIFIER
,
,
new
NEW
yydebug
IDENTIFIER
.
DOT
yyDebugSimple
IDENTIFIER
(
(
)
)
)
)
;
;
else
ELSE
yyparse
IDENTIFIER
(
(
lexer
IDENTIFIER
)
)
;
;
}
}
catch
CATCH
(
(
Exception
IDENTIFIER
e
IDENTIFIER
)
)
{
{
Console
IDENTIFIER
.
DOT
WriteLine
IDENTIFIER
(
(
Fatal error: 
LITERAL_STRING
+
+
name
IDENTIFIER
)
)
;
;
Console
IDENTIFIER
.
DOT
WriteLine
IDENTIFIER
(
(
e
IDENTIFIER
)
)
;
;
Console
IDENTIFIER
.
DOT
WriteLine
IDENTIFIER
(
(
lexer
IDENTIFIER
.
DOT
location
IDENTIFIER
)
)
;
;
global_errors
IDENTIFIER
++
++
;
;
}
}
return
RETURN
global_errors
IDENTIFIER
;
;
}
}


