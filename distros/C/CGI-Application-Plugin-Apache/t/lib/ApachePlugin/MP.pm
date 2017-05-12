package ApachePlugin::MP;
use base 'CGI::Application';
use strict;
use warnings;
use CGI::Cookie;
use CGI::Application::Plugin::Apache qw(:all);
my $MP2;
my $APACHE_COOKIE_CLASS;

BEGIN {
    $MP2 = $ENV{MOD_PERL_API_VERSION} == 2;
    if( $MP2 ) {
        require Apache2::Cookie;
        import Apache2::Cookie ();
        $APACHE_COOKIE_CLASS = 'Apache2::Cookie';
    } else {
        require Apache::Cookie;
        import Apache::Cookie ();
        $APACHE_COOKIE_CLASS = 'Apache::Cookie';
    }
};

sub setup {
    my $self = shift;
    $self->start_mode('header');
    $self->run_modes([qw(
        query_obj
        header
        no_header
        invalid_header
        redirect
        redirected_to
        redirect_cookie
        add_header
        cgi_cookie
        apache_cookie
        baking_apache_cookie
        cgi_and_apache_cookies
        cgi_and_baked_cookies
        cookies
    )]);
}

sub no_header {
    my $self = shift;
    $self->header_type('none');
    print "Content-Type: text/html\n\n";
    print "Im in runmode no_header";
    return '';
}

sub invalid_header {
    my $self = shift;
    $self->header_type('invalid');
    return "Im in runmode invalid_header";
}

sub query_obj {
    my $self = shift;
    return "Im in runmode query_obj. obj is " . ref($self->query);
}

sub header {
    my $self = shift;
    $self->header_type('header');
    return "Im in runmode header";
}

sub redirect {
    my $self = shift;
    $self->header_type('redirect');
    $self->header_props(
        -uri => '/mp?rm=redirected_to',
    );
    return "Im in runmode redirect (should never see me)";
}

sub redirected_to {
    my $self = shift;
    $self->header_type('header');
    my %cookies = $APACHE_COOKIE_CLASS->fetch();
    my $content = "";
    if($cookies{redirect_cookie}) {
        my $value = $cookies{redirect_cookie}->value;
        $content .= " cookie value = '$value'";
    }
    return "Im in runmode redirect2. $content";
}

sub redirect_cookie {
    my $self = shift;
    $self->header_type('redirect');
    $self->header_props(
        -uri => '/mp?rm=redirected_to',
    );
    my $cookie = $APACHE_COOKIE_CLASS->new(
        $self->query, 
        -name   => 'redirect_cookie', 
        -value  => 'mmmm',
    );
    $cookie->bake($self->query);
    return "Im in runmode redirect_cookie";
}

sub add_header {
    my $self = shift;
    $self->header_type('header');
    $self->header_add(
        -me => 'Myself and I', 
    );
    return "Im in runmode add_header";
}

sub cgi_cookie {
    my $self = shift;
    $self->header_type('header');
    my $cookie = CGI::Cookie->new(
        -name    => 'cgi_cookie',
        -value   => 'yum',
    );
    $self->header_add(
        -cookie => $cookie,
    );
    return "Im in runmode cgi_cookie";
}

sub apache_cookie {
    my $self = shift;
    $self->header_type('header');
    my $cookie = $APACHE_COOKIE_CLASS->new(
        $self->query,
        -name    => 'apache_cookie',
        -value   => 'yummier',
    );
    $self->header_add(
        -cookie => $cookie,
    );
    return "Im in runmode apache_cookie";
}

sub baking_apache_cookie {
    my $self = shift;
    $self->header_type('header');
    my $cookie = $APACHE_COOKIE_CLASS->new(
        $self->query,
        -name    => 'baked_cookie',
        -value   => 'yummiest',
    );
    $cookie->bake($self->query);
    return "Im in runmode baking_apache_cookie";
}

sub cgi_and_apache_cookies {
    my $self = shift;
    $self->header_type('header');
    my $cookie1 = CGI::Cookie->new(
        -name    => 'cgi_cookie',
        -value   => 'yum:both',
    );
    my $cookie2 = $APACHE_COOKIE_CLASS->new(
        $self->query,
        -name    => 'apache_cookie',
        -value   => 'yummier:both',
    );
    $self->header_props(
        -cookie => [$cookie2, $cookie1],
    );
    return "Im in runmode cgi_and_apache_cookies";
}

sub cgi_and_baked_cookies {
    my $self = shift;
    $self->header_type('header');
    my $cookie1 = CGI::Cookie->new(
        -name    => 'cgi_cookie',
        -value   => 'yum:both',
    );
    my $cookie2 = $APACHE_COOKIE_CLASS->new(
        $self->query,
        -name    => 'baked_cookie',
        -value   => 'yummiest:both',
    );
    $self->header_props(
        -cookie => $cookie1,
    );
    $cookie2->bake($self->query);
    return "Im in runmode cgi_and_baked_cookies";
}

sub cookies {
    my $self = shift;
    $self->header_type('header');
    my $cookie1 = CGI::Cookie->new(
        -name    => 'cookie1',
        -value   => 'mmmm',
    );
    my $cookie2 = CGI::Cookie->new(
        -name    => 'cookie2',
        -value   => 'tasty',
    );
    $self->header_props( -cookie => [ $cookie1, $cookie2 ]);
    return "Im in runmode cookies";
}

1;

