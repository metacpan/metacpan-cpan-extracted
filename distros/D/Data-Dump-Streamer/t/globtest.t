use Test::More tests=>19;

#$Id: globtest.t 26 2006-04-16 15:18:52Z demerphq $#

BEGIN { use_ok( 'Data::Dump::Streamer', qw(regex Dump alias_av alias_hv) ); }
use strict;
use warnings;
use Data::Dumper;

# imports same()
require "./t/test_helper.pl";
# use this one for simple, non evalable tests. (GLOB)
#   same ( $got,$expected,$name,$obj )
#
# use this one for eval checks and dumper checks but NOT for GLOB's
# same ( $name,$obj,$expected,@args )


my $o = Data::Dump::Streamer->new();

isa_ok( $o, 'Data::Dump::Streamer' );

{
	no strict;
	# no. 3 - a glob
	{
		local *g;
		same( scalar $o->Data(*g)->Out, <<'EXPECT', "a glob", $o );
$VAR1 = *::g;
EXPECT
	}

	# no. 4 - scalar slot
	{
		local *g = \"a string";
		## XXX: the empty globs are an icky 5.8.0 bug
		$^V lt v5.8 ?
		same( scalar $o->Data(*g)->Out, <<'EXPECT', "scalar slot", $o )
$VAR1 = *::g;
*::g = \'a string';
EXPECT
		:
		same( scalar $o->Data(*g)->Out, <<'EXPECT', "scalar slot", $o )
$VAR1 = *::g;
*::g = \'a string';
*::g = {};
*::g = [];
EXPECT
		;
	}

	# no. 5 - data slots
	{
		local *g;
		$g = 'a string';
		@g = qw/a list/;
		%g = qw/a hash/;
		our ($off,$width,$bits,$val,$res);
		($off,$width,$bits,$val,$res)=($off,$width,$bits,$val,$res);
		eval'
		format g =
vec($_,@#,@#) = @<< == @######### @>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
$off, $width, $bits, $val, $res
vec($_,@#,@#) = @<< == @######### @>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
$off, $width, $bits, $val, $res
.
';
                if ( 5.021009 <= $] ) {
		    same( scalar $o->Data(*g)->Out, <<'EXPECT', "data slots (glob/FORMAT)", $o );
$VAR1 = *::g;
*::g = \do { my $v = 'a string' };
*::g = { a => 'hash' };
*::g = [
         'a',
         'list'
       ];
format g =
vec($_,@#,@#) = @<< == @######### @>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
use warnings;
; $off, $width, $bits, $val, $res
vec($_,@#,@#) = @<< == @######### @>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
$off, $width, $bits, $val, $res
.
EXPECT
                } else {
		    same( scalar $o->Data(*g)->Out, <<'EXPECT', "data slots (glob/FORMAT)", $o );
$VAR1 = *::g;
*::g = \do { my $v = 'a string' };
*::g = { a => 'hash' };
*::g = [
         'a',
         'list'
       ];
format g =
vec($_,@#,@#) = @<< == @######### @>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
$off, $width, $bits, $val, $res
vec($_,@#,@#) = @<< == @######### @>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
$off, $width, $bits, $val, $res
.
EXPECT

                }
                SKIP: {
                    skip "no FORMAT refs before ".vstr(5,7)." and this is ".vstr(),
                         my $NUM=3
                       unless  5.008 <= $];
                    if ( 5.021009 <= $] ) {

		        same( scalar $o->Data(*g{FORMAT})->Out, <<'EXPECT', "data slots (ref/FORMAT)", $o );
$FORMAT1 = do{ local *F; my $F=<<'_EOF_FORMAT_'; $F=~s/^\s+# //mg; eval $F; die $F.$@ if $@; *F{FORMAT};
           # format F =
           # vec($_,@#,@#) = @<< == @######### @>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
           # use warnings;
           # ; $off, $width, $bits, $val, $res
           # vec($_,@#,@#) = @<< == @######### @>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
           # $off, $width, $bits, $val, $res
           # .
_EOF_FORMAT_
           };
EXPECT
                    } else {
		        same( scalar $o->Data(*g{FORMAT})->Out, <<'EXPECT', "data slots (ref/FORMAT)", $o );
$FORMAT1 = do{ local *F; my $F=<<'_EOF_FORMAT_'; $F=~s/^\s+# //mg; eval $F; die $F.$@ if $@; *F{FORMAT};
           # format F =
           # vec($_,@#,@#) = @<< == @######### @>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
           # $off, $width, $bits, $val, $res
           # vec($_,@#,@#) = @<< == @######### @>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
           # $off, $width, $bits, $val, $res
           # .
_EOF_FORMAT_
           };
EXPECT
                    }
                    my $y=bless *g{FORMAT},"Thank::YSTH";
                    if ( 5.021009 <= $] ) {
                        #same ( scalar $o->Data(*g{FORMAT})->Out, <<'EXPECT', "data slots (blessed FORMAT)", $o );
		        test_dump( {name=>"data slots (blessed FORMAT)",
		                    verbose=>1,
		                    pre_eval=>'our ($off,$width,$bits,$val,$res);',
		                    no_dumper=>1,
                                    no_redump=>1,
		                    },
		                    $o, *g{FORMAT}, <<'EXPECT'  );
$Thank_YSTH1 = bless( do{ local *F; my $F=<<'_EOF_FORMAT_'; $F=~s/^\s+# //mg; eval $F; die $F.$@ if $@; *F{FORMAT};
               # format F =
               # vec($_,@#,@#) = @<< == @######### @>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
               # use warnings;
               # ; $off, $width, $bits, $val, $res
               # vec($_,@#,@#) = @<< == @######### @>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
               # $off, $width, $bits, $val, $res
               # .
_EOF_FORMAT_
               }, 'Thank::YSTH' );
EXPECT
                    } else {
		        test_dump( {name=>"data slots (blessed FORMAT)",
		                    verbose=>1,
		                    pre_eval=>'our ($off,$width,$bits,$val,$res);',
		                    no_dumper=>1,
		                    },
		                    $o, *g{FORMAT}, <<'EXPECT'  );
$Thank_YSTH1 = bless( do{ local *F; my $F=<<'_EOF_FORMAT_'; $F=~s/^\s+# //mg; eval $F; die $F.$@ if $@; *F{FORMAT};
               # format F =
               # vec($_,@#,@#) = @<< == @######### @>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
               # $off, $width, $bits, $val, $res
               # vec($_,@#,@#) = @<< == @######### @>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
               # $off, $width, $bits, $val, $res
               # .
_EOF_FORMAT_
               }, 'Thank::YSTH' );
EXPECT

                    }
                    our $gg=1; #silence a warning;
		    same( scalar $o->Data(*gg{FORMAT})->Out, <<'EXPECT', "data slots (empty FORMAT)", $o );
$VAR1 = undef;
EXPECT
                };
	}

	# no. 6 - self glob
	{
		local *g;
		$g = *g{SCALAR};
		same( scalar $o->Data(*g)->Out, <<'EXPECT', "self glob", $o );
$VAR1 = *::g;
*::g = \do { my $v = 'V: *::g{SCALAR}' };
${*::g} = *::g{SCALAR};
EXPECT
	}

	# no. 7 - icky readonly scalars
	{
		local(*g, $s);
		*g = \"cannae be modified";
		$s = "do as you please";

		same( scalar $o->Data($g,$s)->Out, <<'EXPECT', "icky SCALAR slot", $o );
$RO1 = 'cannae be modified';
make_ro($RO1);
$VAR1 = 'do as you please';
EXPECT
	}
}
{
    #local $Data::Dump::Streamer::DEBUG=1;
    our $foo = 5;
    our @foo = (-10,\*foo);
    our %foo = (a=>1,b=>\$foo,c=>\@foo);
    $foo{d} = \%foo;
    $foo[2] = \%foo;
    same( "Named Globs", $o->Declare(0)->Names('*foo', '*bar', '*baz'), <<'EXPECT', ( \\*foo, \\@foo, \\%foo ) );
$foo = \\*::foo;
*::foo = \do { my $v = 5 };
$bar = \[
         -10,
         $$foo,
         'V: $$baz'
       ];
*::foo = $$bar;
$baz = \{
         a => 1,
         b => *::foo{SCALAR},
         c => $$bar,
         d => 'V: $$baz'
       };
*::foo = $$baz;
${$bar}->[2] = $$baz;
${$baz}->{d} = $$baz;
EXPECT
    same( "Named Globs Two", $o->Names('foo', 'bar', 'baz'), <<'EXPECT', ( \\*foo, \\@foo, \\%foo ) );
$foo = \\*::foo;
*::foo = \do { my $v = 5 };
$bar = \[
         -10,
         $$foo,
         'V: $$baz'
       ];
*::foo = $$bar;
$baz = \{
         a => 1,
         b => *::foo{SCALAR},
         c => $$bar,
         d => 'V: $$baz'
       };
*::foo = $$baz;
${$bar}->[2] = $$baz;
${$baz}->{d} = $$baz;
EXPECT
    same( "Named Globs Declare", $o->Declare(1)->Names('*foo', '*bar', '*baz'), <<'EXPECT', ( \\*foo, \\@foo, \\%foo ) );
my $foo = \\*::foo;
*::foo = \do { my $v = 5 };
my $bar = \[
            -10,
            $$foo,
            'V: $$baz'
          ];
*::foo = $$bar;
my $baz = \{
            a => 1,
            b => *::foo{SCALAR},
            c => $$bar,
            d => 'V: $$baz'
          };
*::foo = $$baz;
${$bar}->[2] = $$baz;
${$baz}->{d} = $$baz;
EXPECT
    same( "Named Globs Two Declare", $o->Names('foo', 'bar', 'baz'), <<'EXPECT', ( \\*foo, \\@foo, \\%foo ) );
my $foo = \\*::foo;
*::foo = \do { my $v = 5 };
my $bar = \[
            -10,
            $$foo,
            'V: $$baz'
          ];
*::foo = $$bar;
my $baz = \{
            a => 1,
            b => *::foo{SCALAR},
            c => $$bar,
            d => 'V: $$baz'
          };
*::foo = $$baz;
${$bar}->[2] = $$baz;
${$baz}->{d} = $$baz;
EXPECT
}
# with eval testing
{

    use Symbol;
    my $x=gensym;
    my $names=$o->Names(); # scalar context
    same( scalar $o->Data($x)->Out(),<<'EXPECT', "Symbol 1", $o );
my $foo = do{ require Symbol; Symbol::gensym };
EXPECT
    my @names=$o->Names(); # scalar context
    same( scalar $o->Data($x)->Out(),<<'EXPECT', "Symbol 2", $o );
my $foo = do{ require Symbol; Symbol::gensym };
EXPECT
    $o->Names();
    same( scalar $o->Data($x)->Out(),<<'EXPECT', "Symbol 3", $o );
my $GLOB1 = do{ require Symbol; Symbol::gensym };
EXPECT

    #local $Data::Dump::Streamer::DEBUG=1;

    $x=\gensym; #
    *$$x = $x;
    *$$x = $names;
    *$$x = { Thank => '[ysth]', Grr => bless \gensym,'Foo' };
    #Devel::Peek::Dump $x

    same( scalar $o->Data( $x )->Out(),<<'EXPECT', "Symbol 4", $o );
my $REF1 = \do{ require Symbol; Symbol::gensym };
*$$REF1 = {
            Grr   => bless( \Symbol::gensym, 'Foo' ),
            Thank => '[ysth]'
          };
*$$REF1 = [
            'foo',
            'bar',
            'baz'
          ];
*$$REF1 = $REF1;
EXPECT

}
{
    same( my $dump=$o->Data(*{gensym()})->Out, <<'EXPECT', "Symbol 5", $o );
my $VAR1 = *{ do{ require Symbol; Symbol::gensym } };
EXPECT
}
__END__
# with eval testing
{
    same( "", $o, <<'EXPECT', (  ) );
EXPECT
}
# without eval testing
{
    same( $dump = $o->Data()->Out, <<'EXPECT', "", $o );
EXPECT
}
