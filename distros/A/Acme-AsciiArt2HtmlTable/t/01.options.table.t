use Test::More tests => 5;

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
.default tr {  }
</style>
<table class="default" border="0" cellpadding="0" cellspacing="2">

</table>
';

my $res3='<style>
.default td { height:1px; width:1px; }
.default tr {  }
</style>
<table class="default" border="0" cellpadding="3" cellspacing="2">

</table>
';

my $res4='<style>
.default td { height:1px; width:1px; }
.default tr {  }
</style>
<table class="default" border="2" cellpadding="0" cellspacing="0">

</table>
';

is( aa2ht({table=>{}},$ex), $res1 );
is( aa2ht({table=>{'cellspacing'=>'2'}},$ex), $res2 );
is( aa2ht({table=>{'cellspacing'=>'2','cellpadding'=>'3'}},$ex), $res3 );
is( aa2ht({table=>{'border'=>'2'}},$ex), $res4 );
