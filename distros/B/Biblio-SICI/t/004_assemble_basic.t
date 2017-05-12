
use strict;
use warnings;

use Test::More;
use Data::Dumper;

use Biblio::SICI;

# 1064-3923(199505)6:5<>1.0.TX;2-U

my $t1 = '1064-3923(199505)6:5<>1.0.TX;2-U';
my $s1 = Biblio::SICI->new();
isa_ok( $s1, 'Biblio::SICI', 'object instantiated' );

$s1->item->issn('1064-3923');
$s1->item->chronology('199505');
$s1->item->volume(6);
$s1->item->issue(5);
$s1->control->mfi('TX');

is( $s1->to_string, $t1, 'assemble simple SICI without contribution segment; using defaults for control segment' );
is_deeply( { $s1->list_problems() }, {}, "no problems for valid data" );

# Resets volume and issue
$s1->item->enumeration('6:5');

is( $s1->to_string, $t1, 'enumeration replaces volume/issue' );
is_deeply( { $s1->list_problems() }, {}, "no problems for valid data" );

$s1->contribution->location('26');
$s1->contribution->titleCode('MTW');

my $t2 = '1064-3923(199505)6:5<26:MTW>2.0.TX;2-2';
is( $s1->to_string, $t2, 'add contribution info; automatically get new csi' );
is_deeply( { $s1->list_problems() }, {}, "no problems for valid data" );

$s1->contribution->reset;
is( $s1->to_string, $t1, 'reset contribution info; automatically get previous csi again' );
is_deeply( { $s1->list_problems() }, {}, "no problems for valid data" );

$s1->control->reset;

my $t3 = '1064-3923(199505)6:5<>1.0.ZU;2-F';
is( $s1->to_string, $t3, 'reset control info and get default mfi code (i.e. "unknown")' );
is_deeply( { $s1->list_problems() }, {}, "no problems for valid data" );

# 0018-9219(1985)73*<>1.0.TX;2-6
# 0095-4403(199312/199401)20:2<>1.0.TX;2-U
# 0002-8231(199602)47:2<173:POPR:CCC-020173-04>3.0.TX;2-E
# 1070-9916(199433)1:3<>1.0.TX;2-I
# 0361-526X(199021/22)17:3/4<>1.0.TX;2-P
# 0015-6914(19950605)+<27:AMMIH>2.0.TX;2-I
# 0003-9632(198307/09)46:3+<1:LPLMSL>2.0.TX;2-I
# 0165-3806(1996)<::PII-S1065-3806(96)000403-8>3.0.TX;2-6

done_testing();
