use Test::More tests => 3;

BEGIN {
use_ok( 'Acme::AsciiArt2HtmlTable' );
}

my $ex = 'rg
yx';

my $res1='<style>
.default td { height:1px; width:1px; }
.default tr {  }
</style>
<table class="default" border="0" cellpadding="0" cellspacing="0">
<tr>
<td bgcolor="ff0000"></td>
<td bgcolor="00ff00"></td>
</tr>
<tr>
<td bgcolor="ffff00"></td>
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
<td bgcolor="ff0000"></td>
<td bgcolor="00ff00"></td>
</tr>
<tr>
<td bgcolor="ffff00"></td>
<td bgcolor="e30c94"></td>
</tr>
</table>
';

is( aa2ht($ex), $res1 );
srand 2;
is( aa2ht({'randomize-new-colors'=>1},$ex), $res2 );
