use strict;
use warnings;
use FindBin '$Bin';
use lib "$Bin/lib";
use Test::More;
use Catalyst::Test 'TestApp';

my ($content) = get('/sm');

my $data = q|<meta name="twitter:card" content="summary_large_image"/>
<meta name="twitter:site" content="Lnation.org"/>
<meta name="twitter:title" content="Social Meta Tag Generator"/>
<meta name="twitter:description" content="Demo UI for HTML::SocialMeta"/>
<meta name="twitter:image" content="https://lnation.org/static/images/social.png"/>
<meta name="twitter:image:alt" content=""/>
<meta property="og:type" content="article"/>
<meta property="og:title" content="Social Meta Tag Generator"/>
<meta property="og:description" content="Demo UI for HTML::SocialMeta"/>
<meta property="og:url" content="https://lnation.org/socialmeta/demo"/>
<meta property="og:image" content="https://lnation.org/static/images/social.png"/>
<meta property="og:image:alt" content=""/>
<meta property="og:site_name" content="Lnation"/>
<meta property="fb:app_id" content="lnationorgnofb"/>|;
is($content, $data, $data);

($content) = get('/smm');
$data = q|<meta name="twitter:card" content="summary_large_image"/>
<meta name="twitter:site" content="Lnation.org"/>
<meta name="twitter:title" content="Changed Title"/>
<meta name="twitter:description" content="Demo UI for Changed::Title"/>
<meta name="twitter:image" content="https://lnation.org/static/images/social.png"/>
<meta name="twitter:image:alt" content=""/>
<meta property="og:type" content="article"/>
<meta property="og:title" content="Changed Title"/>
<meta property="og:description" content="Demo UI for Changed::Title"/>
<meta property="og:url" content="https://lnation.org/socialmeta/demo"/>
<meta property="og:image" content="https://lnation.org/static/images/social.png"/>
<meta property="og:image:alt" content=""/>
<meta property="og:site_name" content="Lnation"/>
<meta property="fb:app_id" content="lnationorgnofb"/>|;
is($content, $data, $data);

done_testing();
