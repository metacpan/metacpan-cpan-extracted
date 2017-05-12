use Test::More tests => 2;

BEGIN {
use_ok( 'Acme::AsciiArt2HtmlTable' );
}

my $ex = '';

my $res='<style>
.testingid td { height:1px; width:1px; }
.testingid tr {  }
</style>
<table class="testingid" border="0" cellpadding="0" cellspacing="0">

</table>
';

is( aa2ht({'id'=>'testingid'},$ex), $res );
