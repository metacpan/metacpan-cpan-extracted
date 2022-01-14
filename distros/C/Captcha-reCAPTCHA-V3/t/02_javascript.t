use strict;
use Test::More 0.98 tests => 13;

use Captcha::reCAPTCHA::V3;

my %correct = (
    url => 'https://www.google.com/recaptcha/api.js?render=Dummy',
    tag => qq|<script src="https://www.google.com/recaptcha/api.js?render=Dummy" defer></script>|,
    scripts => <<EOL,
<script src="https://www.google.com/recaptcha/api.js?render=Dummy" defer></script>
<script defer>
let rf = document.getElementById("Form");
rf.onsubmit = function(event){
    grecaptcha.ready(function() {
        grecaptcha.execute('Dummy', { action: 'homepage' }).then(function(token) {
            // console.log(token);
            rf.insertAdjacentHTML('beforeend', '<input type="hidden" name="g-recaptcha-response" value="' + token + '">');
            rf.submit();
        });
    });
    event.preventDefault();
    return false;
}
</script>
EOL
);

my $rc = Captcha::reCAPTCHA::V3->new( secret => 'Dummy' );

is eval { $rc->scriptURL() }, undef, "failure with no sitekey";
is eval { $rc->scriptURL( sitekey => '' ) },      undef,         "failure with empty sitekey";
is eval { $rc->scriptURL( sitekey => 'Dummy' ) }, $correct{url}, "succeed to make an URL";

is eval { $rc->scriptTag() }, undef, "failure with no sitekey";
is eval { $rc->scriptTag( sitekey => '' ) },      undef,         "failure with empty sitekey";
is eval { $rc->scriptTag( sitekey => 'Dummy' ) }, $correct{tag}, "succeed to make a script tag";

is eval { $rc->scripts( id => 'Form' ) }, undef, "failure with no sitekey";
is eval { $rc->scripts( id => 'Form', sitekey => '' ) }, undef, "failure with empty sitekey";
is eval { $rc->scripts( id => 'Form', sitekey => 'Dummy' ) }, $correct{scripts},
    "succeed to make scripts";

$rc->sitekey('Dummy');

is eval { $rc->scriptURL() }, $correct{url}, "succeed without setting sitekey";
is eval { $rc->scriptTag() }, $correct{tag}, "succeed to make a tag without setting";
is eval { $rc->scripts( id => 'Form' ) },
    $correct{scripts}, "succeed to make scripts without setting";

( my $test = $correct{scripts} ) =~ s|[/]{2} ||g;

is $rc->scripts( id => 'Form', debug => 1 ), $test, "succeed to make test scripts";

done_testing;
