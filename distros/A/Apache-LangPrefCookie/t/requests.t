# -*-perl-*-

use Apache::Test;
use Apache::TestRequest qw( GET );
use Apache::TestUtil;
use Apache::Constants;

my @testdata;

while (<DATA>) {
    chomp; push @testdata, [split/!/];
}

plan tests => scalar(@testdata), have_lwp;

foreach (@testdata) {
    my @test = @$_;
    ok( do_test(@test), $test[3], "GET " . $test[0]
        . ", Accept-Language was \"" . $test[1]
        ."\", cookie was \"". $test[2] . "\"\n");
}

sub do_test {
    my ($url, $accept_language,  $cookie, $expect_resp, $resp, $resp_content) = @_;

    if (length $cookie) {
        Apache::TestRequest::user_agent(cookie_jar => {});
    }

    if ($accept_language) {
        $resp = GET $url, 'Accept-Language' => $accept_language, 'Cookie' => $cookie;
    } else {
        $resp = GET $url;
    }
    $resp_content = $resp->content;
    $resp_content =~ s!^.*<h1>(.+)</h1>.*$!$1!si;
    return $resp_content;
}

__DATA__
/langprefcookie/!!!English
/langprefcookie/index.html!!!English
/langprefcookie/index.html.html!!!English
/langprefcookie/index.html.en!!!English
/langprefcookie/index.html.it!!!Italiano
/langprefcookie/index.html.de!!!Deutsch
/langprefcookie/!*!!English
/langprefcookie/index.html!*!!English
/langprefcookie/index.html.html!*!!English
/langprefcookie/index.html.en!*!!English
/langprefcookie/index.html.it!*!!Italiano
/langprefcookie/index.html.de!*!!Deutsch
/langprefcookie/!de-at!!English
/langprefcookie/index.html!de-at!!English
/langprefcookie/index.html.html!de-at!!English
/langprefcookie/index.html.en!de-at!!English
/langprefcookie/index.html.it!de-at!!Italiano
/langprefcookie/index.html.de!de-at!!Deutsch
/langprefcookie/!de!!Deutsch
/langprefcookie/index.html!de!!Deutsch
/langprefcookie/index.html.html!de!!English
/langprefcookie/index.html.en!de!!English
/langprefcookie/index.html.it!de!!Italiano
/langprefcookie/index.html.de!de!!Deutsch
/langprefcookie/!de!prefer-language=x-klingon;path=/!Deutsch
/langprefcookie/index.html!de!prefer-language=x-klingon;path=/!Deutsch
/langprefcookie/index.html.html!de!prefer-language=x-klingon;path=/!English
/langprefcookie/index.html.en!de!prefer-language=x-klingon;path=/!English
/langprefcookie/index.html.it!de!prefer-language=x-klingon;path=/!Italiano
/langprefcookie/index.html.de!de!prefer-language=x-klingon;path=/!Deutsch
/langprefcookie/!de!prefer-language=it;path=/!Italiano
/langprefcookie/index.html!de!prefer-language=it;path=/!Italiano
/langprefcookie/index.html.html!de!prefer-language=it;path=/!English
/langprefcookie/index.html.en!de!prefer-language=it;path=/!English
/langprefcookie/index.html.it!de!prefer-language=it;path=/!Italiano
/langprefcookie/index.html.de!de!prefer-language=it;path=/!Deutsch
/langprefcookie/!de-at!prefer-language=it;path=/!Italiano
/langprefcookie/index.html!de-at!prefer-language=it;path=/!Italiano
/langprefcookie/index.html.html!de-at!prefer-language=it;path=/!English
/langprefcookie/index.html.en!de-at!prefer-language=it;path=/!English
/langprefcookie/index.html.it!de-at!prefer-language=it;path=/!Italiano
/langprefcookie/index.html.de!de-at!prefer-language=it;path=/!Deutsch
/langprefcookie/!*!prefer-language=it;path=/!Italiano
/langprefcookie/index.html!*!prefer-language=it;path=/!Italiano
/langprefcookie/index.html.html!*!prefer-language=it;path=/!English
/langprefcookie/index.html.en!*!prefer-language=it;path=/!English
/langprefcookie/index.html.it!*!prefer-language=it;path=/!Italiano
/langprefcookie/index.html.de!*!prefer-language=it;path=/!Deutsch
/langprefcookie/!de!prefer-baggage=it;path=/!Deutsch
/langprefcookie/index.html!de!prefer-baggage=it;path=/!Deutsch
/langprefcookie/index.html.html!de!prefer-baggage=it;path=/!English
/langprefcookie/index.html.en!de!prefer-baggage=it;path=/!English
/langprefcookie/index.html.it!de!prefer-baggage=it;path=/!Italiano
/langprefcookie/index.html.de!de!prefer-baggage=it;path=/!Deutsch
/langprefcookie/!*!prefer-baggage=it;path=/!English
/langprefcookie/index.html!*!prefer-baggage=it;path=/!English
/langprefcookie/index.html.html!de!prefer-baggage=it;path=/!English
/langprefcookie/index.html.en!de!prefer-baggage=it;path=/!English
/langprefcookie/index.html.it!de!prefer-baggage=it;path=/!Italiano
/langprefcookie/index.html.de!de!prefer-baggage=it;path=/!Deutsch
/langprefcookie/foo/!!!English
/langprefcookie/foo/index.html!!!English
/langprefcookie/foo/index.html.html!!!English
/langprefcookie/foo/index.html.en!!!English
/langprefcookie/foo/index.html.it!!!Italiano
/langprefcookie/foo/index.html.de!!!Deutsch
/langprefcookie/foo/!*!!English
/langprefcookie/foo/index.html!*!!English
/langprefcookie/foo/index.html.html!*!!English
/langprefcookie/foo/index.html.en!*!!English
/langprefcookie/foo/index.html.it!*!!Italiano
/langprefcookie/foo/index.html.de!*!!Deutsch
/langprefcookie/foo/!de-at!!English
/langprefcookie/foo/index.html!de-at!!English
/langprefcookie/foo/index.html.html!de-at!!English
/langprefcookie/foo/index.html.en!de-at!!English
/langprefcookie/foo/index.html.it!de-at!!Italiano
/langprefcookie/foo/index.html.de!de-at!!Deutsch
/langprefcookie/foo/!de!!Deutsch
/langprefcookie/foo/index.html!de!!Deutsch
/langprefcookie/foo/index.html.html!de!!English
/langprefcookie/foo/index.html.en!de!!English
/langprefcookie/foo/index.html.it!de!!Italiano
/langprefcookie/foo/index.html.de!de!!Deutsch
/langprefcookie/foo/!de!foo-pref=x-klingon;path=/!Deutsch
/langprefcookie/foo/index.html!de!foo-pref=x-klingon;path=/!Deutsch
/langprefcookie/foo/index.html.html!de!foo-pref=x-klingon;path=/!English
/langprefcookie/foo/index.html.en!de!foo-pref=x-klingon;path=/!English
/langprefcookie/foo/index.html.it!de!foo-pref=x-klingon;path=/!Italiano
/langprefcookie/foo/index.html.de!de!foo-pref=x-klingon;path=/!Deutsch
/langprefcookie/foo/!de!foo-pref=it;path=/!Italiano
/langprefcookie/foo/index.html!de!foo-pref=it;path=/!Italiano
/langprefcookie/foo/index.html.html!de!foo-pref=it;path=/!English
/langprefcookie/foo/index.html.en!de!foo-pref=it;path=/!English
/langprefcookie/foo/index.html.it!de!foo-pref=it;path=/!Italiano
/langprefcookie/foo/index.html.de!de!foo-pref=it;path=/!Deutsch
/langprefcookie/foo/!de-at!foo-pref=it;path=/!Italiano
/langprefcookie/foo/index.html!de-at!foo-pref=it;path=/!Italiano
/langprefcookie/foo/index.html.html!de-at!foo-pref=it;path=/!English
/langprefcookie/foo/index.html.en!de-at!foo-pref=it;path=/!English
/langprefcookie/foo/index.html.it!de-at!foo-pref=it;path=/!Italiano
/langprefcookie/foo/index.html.de!de-at!foo-pref=it;path=/!Deutsch
/langprefcookie/foo/!*!foo-pref=it;path=/!Italiano
/langprefcookie/foo/index.html!*!foo-pref=it;path=/!Italiano
/langprefcookie/foo/index.html.html!*!foo-pref=it;path=/!English
/langprefcookie/foo/index.html.en!*!foo-pref=it;path=/!English
/langprefcookie/foo/index.html.it!*!foo-pref=it;path=/!Italiano
/langprefcookie/foo/index.html.de!*!foo-pref=it;path=/!Deutsch
/langprefcookie/foo/!de!prefer-language=it;path=/!Deutsch
/langprefcookie/foo/index.html!de!prefer-language=it;path=/!Deutsch
/langprefcookie/foo/index.html.html!de!prefer-language=it;path=/!English
/langprefcookie/foo/index.html.en!de!prefer-language=it;path=/!English
/langprefcookie/foo/index.html.it!de!prefer-language=it;path=/!Italiano
/langprefcookie/foo/index.html.de!de!prefer-language=it;path=/!Deutsch
/langprefcookie/foo/!*!prefer-language=it;path=/!English
/langprefcookie/foo/index.html!*!prefer-language=it;path=/!English
/langprefcookie/foo/index.html.html!de!prefer-language=it;path=/!English
/langprefcookie/foo/index.html.en!de!prefer-language=it;path=/!English
/langprefcookie/foo/index.html.it!de!prefer-language=it;path=/!Italiano
/langprefcookie/foo/index.html.de!de!prefer-language=it;path=/!Deutsch
/langprefcookie/foo/!de!foo-pref=it;path=/!Italiano
/langprefcookie/foo/!de, en!foo-pref=it;path=/!Italiano
/langprefcookie/foo/!de,en;q=0.8,fr;q=0.6,it;q=0.4,es;q=0.2!foo-pref=it;path=/!Italiano
/langprefcookie/foo/!de-at!foo-pref=it;path=/!Italiano
/langprefcookie/foo/!de-at,de-de;q=0.8,de;q=0.5,en;q=0.3!foo-pref=it;path=/!Italiano
/langprefcookie/foo/!de_DE,de;q=0.9,en;q=0.8!foo-pref=it;path=/!Italiano
/langprefcookie/foo/!fr,fr-fr;q=0.8,en-us;q=0.5,en;q=0.3!foo-pref=it;path=/!Italiano
/langprefcookie/foo/!fr-lu,de;q=0.5!foo-pref=it;path=/!Italiano
/langprefcookie/foo/!it!foo-pref=de;path=/!Deutsch
/langprefcookie/foo/!de!foo-pref=de;path=/!Deutsch
/langprefcookie/foo/!de, en!foo-pref=de;path=/!Deutsch
/langprefcookie/foo/!de,en;q=0.8,fr;q=0.6,it;q=0.4,es;q=0.2!foo-pref=de;path=/!Deutsch
/langprefcookie/foo/!de-at!foo-pref=de;path=/!Deutsch
/langprefcookie/foo/!de-at,de-de;q=0.8,de;q=0.5,en;q=0.3!foo-pref=de;path=/!Deutsch
/langprefcookie/foo/!de_DE,de;q=0.9,en;q=0.8!foo-pref=de;path=/!Deutsch
/langprefcookie/foo/!fr,fr-fr;q=0.8,en-us;q=0.5,en;q=0.3!foo-pref=de;path=/!Deutsch
/langprefcookie/foo/!fr-lu,de;q=0.5!foo-pref=de;path=/!Deutsch
/langprefcookie/foo/!it!foo-pref=de;path=/!Deutsch
