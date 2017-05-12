use Test::More tests => 9;

BEGIN {
use_ok( 'Acme::AsciiArt2HtmlTable' );
}

my $ex = 'rg
yu';

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
<td bgcolor="a020f0"></td>
</tr>
</table>
';

my $res2='<style>
.default td { height:1px; width:1px; }
.default tr {  }
</style>
<table class="default" border="0" cellpadding="0" cellspacing="0">
<tr>
<td bgcolor="ff00ff"></td>
<td bgcolor="00ff00"></td>
</tr>
<tr>
<td bgcolor="ffff00"></td>
<td bgcolor="a020f0"></td>
</tr>
</table>
';

my $res3='<style>
.default td { height:1px; width:1px; }
.default tr {  }
</style>
<table class="default" border="0" cellpadding="0" cellspacing="0">
<tr>
<td bgcolor="ff0000"></td>
<td bgcolor="00ff00"></td>
</tr>
<tr>
<td bgcolor="00ff00"></td>
<td bgcolor="a020f0"></td>
</tr>
</table>
';

my $res4='<style>
.default td { height:1px; width:1px; }
.default tr {  }
</style>
<table class="default" border="0" cellpadding="0" cellspacing="0">
<tr>
<td bgcolor="ff00ff"></td>
<td bgcolor="00ff00"></td>
</tr>
<tr>
<td bgcolor="00ff00"></td>
<td bgcolor="a020f0"></td>
</tr>
</table>
';

is( aa2ht($ex), $res1 );
is( aa2ht({'colors'=>{}},$ex), $res1 );
is( aa2ht({'colors'=>{'default'=>'aaaaaa'}},$ex), $res1 );
is( aa2ht({'colors'=>{'r'=>'ff00ff'}},$ex), $res2 );
is( aa2ht({'colors'=>{'r'=>'ff00ff'}},$ex), $res2 );
is( aa2ht({'colors'=>{'y'=>'00ff00'}},$ex), $res3 );
is( aa2ht({'colors'=>{'r'=>'ff00ff','y'=>'00ff00'}},$ex), $res4 );
is( aa2ht($ex), $res1 );
