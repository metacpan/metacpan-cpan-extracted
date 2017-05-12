use Test::More tests => 4;

BEGIN {
use_ok( 'Acme::AsciiArt2HtmlTable' );
}

my $ex = '';

my $res1='<style>
.default td { height:1px; width:1px; }
.default tr {  }
</style>
<table class="default" border="0" cellpadding="0" cellspacing="0">

</table>
';

my $res2='<style>
.default td { height:1px; width:2px; }
.default tr {  }
</style>
<table class="default" border="0" cellpadding="0" cellspacing="0">

</table>
';

my $res3='<style>
.default td { height:3px; width:2px; }
.default tr {  }
</style>
<table class="default" border="0" cellpadding="0" cellspacing="0">

</table>
';

is( aa2ht({td=>{}},$ex), $res1 );
is( aa2ht({td=>{'width'=>'2px'}},$ex), $res2 );
is( aa2ht({td=>{'width'=>'2px','height'=>'3px'}},$ex), $res3 );
