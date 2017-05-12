package TestApp;

use strict;
use warnings;

use Dancer;
use Dancer::Plugin::Legacy::Routing;

# VERSION
# ABSTRACT: Dancer App used for Testing of Dancer::PLugin::Legacy::Routing

get "/good/get"          => \&test_get;
legacy_get "/legacy/get" => \&test_get;

get "/good/get/:var"          => \&test_get_with_var;
legacy_get "/legacy/get/:var" => \&test_get_with_var;

get "/good/get/:var/params"          => \&test_get_with_params;
legacy_get "/legacy/get/:var/params" => \&test_get_with_params;

sub test_get {
    status 200;
    return "Testing Get";
}

sub test_get_with_var {
    my $var = params->{'var'};

    status 200;
    return "Testing Get, Var Value is = " . $var;
}

sub test_get_with_params {
    my $var1 = params->{'var1'};
    my $var2 = params->{'var2'};

    status 200;
    return
        "Testing Get, Var1 Value is = "
      . $var1
      . " Var2 Value is = "
      . $var2;
}

post "/good/post"          => \&test_post;
legacy_post "/legacy/post" => \&test_post;

post "/good/post/:var"          => \&test_post_with_var;
legacy_post "/legacy/post/:var" => \&test_post_with_var;

post "/good/post/:var/params"          => \&test_post_with_params;
legacy_post "/legacy/post/:var/params" => \&test_post_with_params;

sub test_post {
    status 200;
    return "Testing Post";
}

sub test_post_with_var {
    my $var = params->{'var'};

    status 200;
    return "Testing Post, Var Value is = " . $var;
}

sub test_post_with_params {
    my $var1 = params->{'var1'};
    my $var2 = params->{'var2'};

    status 200;
    return
        "Testing Post, Var1 Value is = "
      . $var1
      . " Var2 Value is = "
      . $var2;
}

put "/good/put"          => \&test_put;
legacy_put "/legacy/put" => \&test_put;

put "/good/put/:var"          => \&test_put_with_var;
legacy_put "/legacy/put/:var" => \&test_put_with_var;

put "/good/put/:var/params"          => \&test_put_with_params;
legacy_put "/legacy/put/:var/params" => \&test_put_with_params;

sub test_put {
    status 200;
    return "Testing Put";
}

sub test_put_with_var {
    my $var = params->{'var'};

    status 200;
    return "Testing Put, Var Value is = " . $var;
}

sub test_put_with_params {
    my $var1 = params->{'var1'};
    my $var2 = params->{'var2'};

    status 200;
    return
        "Testing Put, Var1 Value is = "
      . $var1
      . " Var2 Value is = "
      . $var2;
}

del "/good/delete"          => \&test_del;
legacy_del "/legacy/delete" => \&test_del;

del "/good/delete/:var"          => \&test_del_with_var;
legacy_del "/legacy/delete/:var" => \&test_del_with_var;

del "/good/delete/:var/params"          => \&test_del_with_params;
legacy_del "/legacy/delete/:var/params" => \&test_del_with_params;

sub test_del {
    status 200;
    return "Testing Delete";
}

sub test_del_with_var {
    my $var = params->{'var'};

    status 200;
    return "Testing Delete, Var Value is = " . $var;
}

sub test_del_with_params {
    my $var1 = params->{'var1'};
    my $var2 = params->{'var2'};

    status 200;
    return
        "Testing Delete, Var1 Value is = "
      . $var1
      . " Var2 Value is = "
      . $var2;
}

legacy_any "/legacy/any/get"    => \&test_any;
legacy_any "/legacy/any/post"   => \&test_any;
legacy_any "/legacy/any/put"    => \&test_any;
legacy_any "/legacy/any/delete" => \&test_any;

sub test_any {
    status 200;
    return "Testing Any";
}

1;
