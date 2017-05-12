package EmailTest;
use Scalar::Util qw/blessed/;
use Dancer2;

set plugins => {
    Email => {
        transport => {
            Test => {
            }
        }}};

use Dancer2::Plugin::Email;

get '/contact' => sub {
    my $result;

    $result = email {
        from    => 'bob@foo.com',
        to      => 'sue@foo.com',
        subject => 'allo',
        body    => 'Dear Sue, ...',
    };

    my $result_class = blessed $result;

    if ($result_class eq 'Email::Sender::Success') {
        return "Email sent.";
    }

    status 417;
};

1;
