use Test::More skip_all => 'Role requirements not met';

use_ok( 'Bing::Search::Source::Translation' );
my $obj = new_ok( 'Bing::Search::Source::Translation' );

ok( $obj->Translation_TargetLanguage('en'), 'Setting target language' );
   is( $obj->Translation_TargetLanguage(), 'en', 'Checking target language' );

ok( $obj->Translation_SourceLanguage('en'), 'Setting source language' );
   is( $obj->Translation_SourceLanguage(), 'en', 'Checking source language' );



done_testing();
