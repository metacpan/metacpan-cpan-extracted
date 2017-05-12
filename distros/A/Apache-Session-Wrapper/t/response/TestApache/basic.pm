package TestApache::basic;

use strict;
use warnings FATAL => 'all';

use File::Path ();

my $MOD_PERL;
my $REQ_CLASS;

BEGIN
{
    if ( $ENV{MOD_PERL} =~ /(?:1\.9|2\.\d)/ )
    {
        eval <<'EOF';
    use Apache2::Request;
    use Apache2::Cookie;
    use Apache2::Const qw(OK);
    use Apache2::RequestRec;
    use Apache2::RequestUtil;
EOF

        die $@ if $@;

        $MOD_PERL = 2;
        $REQ_CLASS = 'Apache2::Request';
    }
    else
    {
        eval <<'EOF';
    use Apache::Request;
    use Apache::Constants qw(OK);
EOF

        die $@ if $@;

        $MOD_PERL = 1;
        $REQ_CLASS = 'Apache::Request';
    }
}

use Apache::Session::Wrapper;

sub handler ($$) : method
{
    my $class = shift;

    my $r = $REQ_CLASS->new(shift);
    Apache2::RequestUtil->request($r)
        if $MOD_PERL == 2;

    my $dir = $r->dir_config('SessionDir');
    File::Path::mkpath( $dir, 0, 0755 );

    $r->content_type('text/plain');

    my $output = '';

    eval
    {
        my $w =
            Apache::Session::Wrapper->new
                ( class          => 'File',
                  directory      => $dir,
                  lock_directory => $dir,
                  use_cookie     => 1,
                  cookie_name    => 'asw_cookie',
                  cookie_expires => '10m',
                  cookie_path    => '/',
                  cookie_resend  => 1,
                  always_write   => 1,
                  header_object  => $r,
                );

        $output .= "SESSION: " . $w->session->{_session_id} . "\n";

        $w->delete_session() if $r->param('delete');
    };

    $output .= "ERROR: $@" if $@;

    $r->send_http_header
        if $MOD_PERL == 1;

    print $output;

    return OK;
}

1;
