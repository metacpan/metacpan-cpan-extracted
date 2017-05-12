use strict;
use warnings;
use Test::More;
use Test::LongString;
use Data::Undump qw(undump);
use Data::Dumper;
our @dump;
{
    local $/="";
    while (<DATA>) {
        chomp;
        push @dump, $_;
    }
}
plan tests => 1 + 3 * @dump;
pass();
sub dd { return Data::Dumper->new([$_[0]])->Purity(1)->Useqq(1)->Sortkeys(1)->Dump() }
sub check {
    my $dump= shift;
    my $undumped= dd(my $struct= undump($dump));
    my $show_diag= !is( $@||undef, undef, "after undump \$\@ was false");
    my $evaled= dd(eval($dump));
    $show_diag += !($dump eq "undef"
        ? pass("undumping undef")
        : isnt($struct, undef, "undump returned something"));
    $show_diag += !is_string($undumped,$evaled,"undump and eval agree");
    $show_diag and diag($dump);
}

check($_) for @dump;
BEGIN {
    @dump= (
        " 'foo' ",
        ' "foo" ',
    );
}
__DATA__
1

0

123013.139

-1234.59

0.41

-0.13

123

''

"foo"

'foo'

undef

[]

{}

{ foo => 'bar' }

{ foo => bar => baz => undef }

[ 1 ]

[ 1, [ 2 ] ]

[1,2,[3,4,{5=>6,7=>{8=>[]},9=>{}},{},[]]]

[ 1 , 2 , [ 3 , 4 , { 5 => 6 , 7 => { 8 => [ ] } , 9 => { } } , { }, [ ] ] ]

[ a => 'b' ]

{
    foo => 123,
    bar => -159.23 ,
    'baz' =>"foo",
    'bop \''=> "\10"
    ,'bop \'\\'=> "\x{100}" ,
    'bop \'x\\x'    =>"x\x{100}"   , 'bing' =>   "x\x{100}",
    x=>'y', z => 'p', i=> '1', l=>" \10", m=>"\10 ", n => " \10 ",
}

{
    foo => [123],
    "bar" => [-159.23 , { 'baz' => "foo", }, ],
    'bop \''=> { "\10" => { 'bop \'\\'=> "\x{100}", h=>{
    'bop \'x\\x'    =>"x\x{100}"   , 'bing' =>   "x\x{100}",
    x=>'y',}, z => 'p' ,   }   ,  i    =>  '1' ,}, l=>" \10", m=>"\10 ", n => " \10 ",
    o => undef ,p=>undef,
}

[ "\$", "\@", "\%" ]

{ "" => '"', "'" => "" }

\"foo"

\\"foo"

\\["foo"]

\\\{foo=>\"bar"}

bless(\[],"foo")

"123\\277ABC\\x{DF}456"

"\\012\345\267\145123\\277ABC\\x{DF}456"

"\\0123\0124"

\undef

-4123456789

4123456789

[ '#', "#", # foo ]
"foo\#", "# foo
" ]

{
    # some number
    foo => 42,
    bar => '42', # same, as a string
    bop => { # empty hash
    },
}

#leading comment
11

	# leading comment with tab
	11

22#trailing comment

22 # trailing comment with spaces

bless( { a => 1 } , # data
    "Foo::Bar" # class name
    )

bless(#data coming
[],"Foo")#end
