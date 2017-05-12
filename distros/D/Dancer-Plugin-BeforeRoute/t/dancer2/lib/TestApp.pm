package TestApp;

use Dancer2;
use Dancer2::Plugin::BeforeRoute;

set logger        => "console";
set log           => "error";
set show_errors   => 1;
set show_warnings => 1;
set template      => "simple";

before_route
  get => "/",
  sub {
    var before_run => "homepage";
  };

get "/" => sub {
    ## Return "homepage"
    return var "before_run";
};

before_route
  get => "/foo",
  sub {
    var before_run => "foo";
  };

get "/foo" => sub {
    ## Return "foo"
    return var "before_run";
};

before_route
  post => qr{/bar},
  sub {
    ## Retrun "bar"
    return var before_run => "bar";
  };

post "/bar" => sub {
    return var "before_run";
};

before_route
  get => "/foo/:bar",
  sub {
    ## Retrun "bar"
    return var before_run => param "bar";
  };

get "/foo/:bar" => sub {
    return var "before_run";
};

hook before_template_render => sub {
    my $stash = shift;
    $stash->{global} = "yes";
};

get "/index.html" => sub {
    return template "test1.tt", { something => "foo", };
};

get "/second.html" => sub {
    return template "test1.tt", { something => "foo", };
};

before_route(
    ["get", "post"] => qr{^/admin},
    sub {
        var admin => 1;
    }
);

any "/admin/login" => sub {
    return var "admin";
};

1;
