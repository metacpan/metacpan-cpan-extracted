use strict;
use Test::More 0.98 tests => 1;

use Captcha::reCAPTCHA::V3;
my $rc = Captcha::reCAPTCHA::V3->new( secret => 'Dummy', sitekey => 'Dummy' );

my $script = $rc->scripts( id => 'Form' );

is $script, <<EOL, "the generated script is correct";
<script src="https://www.google.com/recaptcha/api.js?render=Dummy" defer></script>
<script defer>
let f = document.getElementById("Form");
f.onsubmit = function(event){
    grecaptcha.ready(function() {
        grecaptcha.execute('Dummy', { action: 'homepage' }).then(function(token) {
            //console.log(token);
            f.insertAdjacentHTML('beforeend', '<input type="hidden" name="g-recaptcha-response" value="' + token + '">');
            f.submit();
        });
    });
    event.preventDefault();
    return false;
}
</script>
EOL

done_testing;

