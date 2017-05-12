use Test::More tests => 6;

BEGIN {
use_ok( 'Acme::AsciiArt2HtmlTable' );
}

my $ex = '#';

my $res1='<style>
.default td { height:1px; width:1px; }
.default tr {  }
</style>
<table class="default" border="0" cellpadding="0" cellspacing="0">
<tr>
<td bgcolor="000000"></td>
</tr>
</table>
';

my $res2='<style>
.default td { height:1px; width:1px; }
.default tr {  }
</style>
<table class="default" border="0" cellpadding="0" cellspacing="0">
<tr>
<td bgcolor="gggggg"></td>
</tr>
</table>
';

my $res3='<style>
.default td { height:1px; width:1px; }
.default tr {  }
</style>
<table class="default" border="0" cellpadding="0" cellspacing="0">
<tr>
<td bgcolor="aaaaaa"></td>
</tr>
</table>
';

is( aa2ht($ex), $res1 );
is( aa2ht({'colors'=>{'default'=>'gggggg'}},$ex), $res2 );
is( aa2ht($ex), $res1 );
is( aa2ht({'colors'=>{'default'=>'aaaaaa'}},$ex), $res3 );
is( aa2ht($ex), $res1 );
