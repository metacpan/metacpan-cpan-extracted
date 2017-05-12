
use Test::More tests => 5;

use AuthCAS;

{
    my $cas = new AuthCAS(
        casUrl => 'https://not_there/',
        CAFile => '/usr/local/apache/conf/ssl.crt/ca-bundle.crt_notTHERE',
    );

    my $return_url = 'http://myapp/something';

    #this actually throws a warning
    my $login_url = $cas->getServerLoginURL($return_url);
    ok(
        !defined(
            $cas->validateST( $return_url, 'ST-42-SLwl77Lv5xx6QK2dmlze-cas' )
        ),
        'non-existant, but reasonable format ticket, to a non-existant server'
    );
}

{
    my $cas = new AuthCAS(
        casUrl => 'https://jasig:8443/',
        SSL_version => 'SSLv3',
#        CAFile => '/usr/local/apache/conf/ssl.crt/ca-bundle.crt_notTHERE',
    );

    my $return_url = 'http://myapp/something';

    #this actually throws a warning
    my $login_url = $cas->getServerLoginURL($return_url);
    ok(
        !defined(
            $cas->validateST( $return_url, 'ST-42-SLwl77Lv5xx6QK2dmlze-cas' )
        ),
        'non-existant, but reasonable format ticket, to a server that _might_ exist'
    );

    ok(
        !defined(
            $cas->validateST( $return_url, '' )
        ),
        'empty string ticket, to a server that _might_ exist'
    );
    ok(
        !defined(
            $cas->validateST( $return_url )
        ),
        'no ticket, to a server that _might_ exist'
    );
    ok(
        !defined(
            $cas->validateST( )
        ),
        'no ticket, no return url, to a server that _might_ exist'
    );
}
