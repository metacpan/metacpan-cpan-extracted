use Test::More tests => 2;

BEGIN {
use_ok( 'Acme::AsciiArt2HtmlTable' );
}

my $ex = 'ggggggggrrrrrrrrrrrrrr
ggggggggrrrrrrrrrrrrrr
ggggggggrrrrrrrrrrrrrr
ggggggggrrrrrrrrrrrrrr
ggggggyyyyrrrrrrrrrrrr
ggggggyyyyrrrrrrrrrrrr
gggggyyyyyyrrrrrrrrrrr
gggggyyyyyyrrrrrrrrrrr
ggggggyyyyrrrrrrrrrrrr
ggggggyyyyrrrrrrrrrrrr
ggggggggrrrrrrrrrrrrrr
ggggggggrrrrrrrrrrrrrr
ggggggggrrrrrrrrrrrrrr
ggggggggrrrrrrrrrrrrrr';

my $res='<style>
.default td { height:1px; width:1px; }
.default tr {  }
</style>
<table class="default" border="0" cellpadding="0" cellspacing="0">
<tr>
<td bgcolor="00ff00"></td>
<td bgcolor="00ff00"></td>
<td bgcolor="00ff00"></td>
<td bgcolor="00ff00"></td>
<td bgcolor="00ff00"></td>
<td bgcolor="00ff00"></td>
<td bgcolor="00ff00"></td>
<td bgcolor="00ff00"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
</tr>
<tr>
<td bgcolor="00ff00"></td>
<td bgcolor="00ff00"></td>
<td bgcolor="00ff00"></td>
<td bgcolor="00ff00"></td>
<td bgcolor="00ff00"></td>
<td bgcolor="00ff00"></td>
<td bgcolor="00ff00"></td>
<td bgcolor="00ff00"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
</tr>
<tr>
<td bgcolor="00ff00"></td>
<td bgcolor="00ff00"></td>
<td bgcolor="00ff00"></td>
<td bgcolor="00ff00"></td>
<td bgcolor="00ff00"></td>
<td bgcolor="00ff00"></td>
<td bgcolor="00ff00"></td>
<td bgcolor="00ff00"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
</tr>
<tr>
<td bgcolor="00ff00"></td>
<td bgcolor="00ff00"></td>
<td bgcolor="00ff00"></td>
<td bgcolor="00ff00"></td>
<td bgcolor="00ff00"></td>
<td bgcolor="00ff00"></td>
<td bgcolor="00ff00"></td>
<td bgcolor="00ff00"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
</tr>
<tr>
<td bgcolor="00ff00"></td>
<td bgcolor="00ff00"></td>
<td bgcolor="00ff00"></td>
<td bgcolor="00ff00"></td>
<td bgcolor="00ff00"></td>
<td bgcolor="00ff00"></td>
<td bgcolor="ffff00"></td>
<td bgcolor="ffff00"></td>
<td bgcolor="ffff00"></td>
<td bgcolor="ffff00"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
</tr>
<tr>
<td bgcolor="00ff00"></td>
<td bgcolor="00ff00"></td>
<td bgcolor="00ff00"></td>
<td bgcolor="00ff00"></td>
<td bgcolor="00ff00"></td>
<td bgcolor="00ff00"></td>
<td bgcolor="ffff00"></td>
<td bgcolor="ffff00"></td>
<td bgcolor="ffff00"></td>
<td bgcolor="ffff00"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
</tr>
<tr>
<td bgcolor="00ff00"></td>
<td bgcolor="00ff00"></td>
<td bgcolor="00ff00"></td>
<td bgcolor="00ff00"></td>
<td bgcolor="00ff00"></td>
<td bgcolor="ffff00"></td>
<td bgcolor="ffff00"></td>
<td bgcolor="ffff00"></td>
<td bgcolor="ffff00"></td>
<td bgcolor="ffff00"></td>
<td bgcolor="ffff00"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
</tr>
<tr>
<td bgcolor="00ff00"></td>
<td bgcolor="00ff00"></td>
<td bgcolor="00ff00"></td>
<td bgcolor="00ff00"></td>
<td bgcolor="00ff00"></td>
<td bgcolor="ffff00"></td>
<td bgcolor="ffff00"></td>
<td bgcolor="ffff00"></td>
<td bgcolor="ffff00"></td>
<td bgcolor="ffff00"></td>
<td bgcolor="ffff00"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
</tr>
<tr>
<td bgcolor="00ff00"></td>
<td bgcolor="00ff00"></td>
<td bgcolor="00ff00"></td>
<td bgcolor="00ff00"></td>
<td bgcolor="00ff00"></td>
<td bgcolor="00ff00"></td>
<td bgcolor="ffff00"></td>
<td bgcolor="ffff00"></td>
<td bgcolor="ffff00"></td>
<td bgcolor="ffff00"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
</tr>
<tr>
<td bgcolor="00ff00"></td>
<td bgcolor="00ff00"></td>
<td bgcolor="00ff00"></td>
<td bgcolor="00ff00"></td>
<td bgcolor="00ff00"></td>
<td bgcolor="00ff00"></td>
<td bgcolor="ffff00"></td>
<td bgcolor="ffff00"></td>
<td bgcolor="ffff00"></td>
<td bgcolor="ffff00"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
</tr>
<tr>
<td bgcolor="00ff00"></td>
<td bgcolor="00ff00"></td>
<td bgcolor="00ff00"></td>
<td bgcolor="00ff00"></td>
<td bgcolor="00ff00"></td>
<td bgcolor="00ff00"></td>
<td bgcolor="00ff00"></td>
<td bgcolor="00ff00"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
</tr>
<tr>
<td bgcolor="00ff00"></td>
<td bgcolor="00ff00"></td>
<td bgcolor="00ff00"></td>
<td bgcolor="00ff00"></td>
<td bgcolor="00ff00"></td>
<td bgcolor="00ff00"></td>
<td bgcolor="00ff00"></td>
<td bgcolor="00ff00"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
</tr>
<tr>
<td bgcolor="00ff00"></td>
<td bgcolor="00ff00"></td>
<td bgcolor="00ff00"></td>
<td bgcolor="00ff00"></td>
<td bgcolor="00ff00"></td>
<td bgcolor="00ff00"></td>
<td bgcolor="00ff00"></td>
<td bgcolor="00ff00"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
</tr>
<tr>
<td bgcolor="00ff00"></td>
<td bgcolor="00ff00"></td>
<td bgcolor="00ff00"></td>
<td bgcolor="00ff00"></td>
<td bgcolor="00ff00"></td>
<td bgcolor="00ff00"></td>
<td bgcolor="00ff00"></td>
<td bgcolor="00ff00"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
<td bgcolor="ff0000"></td>
</tr>
</table>
';

is( aa2ht($ex), $res );
