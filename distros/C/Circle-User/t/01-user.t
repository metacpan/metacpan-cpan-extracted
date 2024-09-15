use 5.006;
use strict;
use warnings;
use Test::More;
use Carp;
use Circle::User;

my $response = send_register_verify_code(
    {
        email => 'lidh04@qq.com'
    }
);
carp 'register verify code status: ' . $response->{status} . ' ' . $response->{message};
is( $response->{status}, 200 );

$response = register(
    {
        email          => 'lidh04@qq.com',
        passwordInput1 => 'test123456',
        passwordInput2 => 'test123456',
        verifyCode     => '111111'
    }
);
carp $response->{status} . ' ' . $response->{message};
ok( $response->{status} == 20004, "user already exists" );

$response = send_verify_code(
    {
        email => 'lidh04@qq.com'
    }
);
carp 'login verify code status: ' . $response->{status} . ' ' . $response->{message};
is( $response->{status}, 200 );

$response = login(
    {
        email      => 'lidh04@qq.com',
        verifyCode => '5393217',
        password   => 'test123456'
    }
);
carp 'login status: ' . $response->{status} . ' ' . $response->{message};
ok( $response->{status} != 200 );

$response = send_pay_verify_code(
    {
        email => 'lidh04@qq.com'
    }
);
carp 'send pay verify code status: ' . $response->{status} . ' ' . $response->{message};
is( $response->{status}, 20000 );

# receive you payVerifyCode from your email.
$response = set_pay_password(
    {
        account => {
            email => 'lidh04@qq.com'
        },
        verifyCode => '5393217',
        password   => 'test123456'
    }
);
carp 'set pay password status: ' . $response->{status} . ' ' . $response->{message};
ok( $response->{status} != 200 );

Circle::User::_save_session_data(
    {
        email => 'test@gmail.com'
    },
    {
        userId     => 'mock-user-id',
        sessionKey => 'test-session-key',
    }
);

done_testing();
