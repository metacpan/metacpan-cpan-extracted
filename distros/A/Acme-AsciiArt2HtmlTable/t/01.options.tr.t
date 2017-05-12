use Test::More tests => 6;

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
.default td { height:1px; width:1px; }
.default tr { width:2px; }
</style>
<table class="default" border="0" cellpadding="0" cellspacing="0">

</table>
';

my $res3='<style>
.default td { height:1px; width:1px; }
.default tr { height:3px; }
</style>
<table class="default" border="0" cellpadding="0" cellspacing="0">

</table>
';

my $res4='<style>
.default td { height:1px; width:1px; }
.default tr { height:3px; width:2px; }
</style>
<table class="default" border="0" cellpadding="0" cellspacing="0">

</table>
';

is( aa2ht({tr=>{}},$ex), $res1 );
is( aa2ht({tr=>{'width'=>'2px'}},$ex), $res2 );
is( aa2ht({tr=>{'height'=>'3px'}},$ex), $res3 );
is( aa2ht({tr=>{'width'=>'2px','height'=>'3px'}},$ex), $res4 );
is( aa2ht({tr=>{}},$ex), $res1 );
