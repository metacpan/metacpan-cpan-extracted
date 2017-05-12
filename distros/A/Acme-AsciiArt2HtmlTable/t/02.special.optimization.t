use Test::More tests => 3;

BEGIN {
use_ok( 'Acme::AsciiArt2HtmlTable' );
}

my $ex = 'rrr
rgr
rrr
';

my $res1='<style>
.default td { height:1px; width:1px; }
.default tr {  }
</style>
<table class="default" border="0" cellpadding="0" cellspacing="0">
<tr>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
</tr>
<tr>
<td bgcolor="ff0000"></td>
<td bgcolor="00ff00"></td>
<td bgcolor="ff0000"></td>
</tr>
<tr>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
</tr>
</table>
';

my $res2 = '<style>
.default td { height:1px; width:1px; }
.default tr {  }
</style>
<table class="default" border="0" cellpadding="0" cellspacing="0">
<tr>
<td rowspan="3" bgcolor="ff0000"></td>
<td colspan="2" bgcolor="ff0000"></td>
<td></td>
</tr>
<tr>
<td bgcolor="00ff00"></td>
<td rowspan="2" bgcolor="ff0000"></td>
<td></td>
</tr>
<tr>
<td bgcolor="ff0000"></td>
<td></td>
</tr><tr><td></td><td></td></tr>
</table>
';

is( aa2ht($ex), $res1 );
is( aa2ht({'optimization' => 1},$ex), $res2 );
