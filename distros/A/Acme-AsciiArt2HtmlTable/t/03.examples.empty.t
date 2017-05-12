use Test::More tests => 2;

BEGIN {
use_ok( 'Acme::AsciiArt2HtmlTable' );
}

my $ex = '';

my $res='<style>
.default td { height:1px; width:1px; }
.default tr {  }
</style>
<table class="default" border="0" cellpadding="0" cellspacing="0">

</table>
';

is( aa2ht($ex), $res );
