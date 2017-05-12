use Dancer ":syntax";
use Dancer::Plugin::Assets "assets";

set(
    charset      => "utf8",
    show_errors  => 1,
    startup_info => 0,
    log          => "debug",
    logger       => "console",
    plugins      => {
        Assets => {
            base_dir => "t/TestMe",
        },
    },
);

get "/js_tags" => sub {
    assets->include("/js/something1.js");
    assets->include("/js/something2.js");
    assets->include("/js/something3.js");
    assets->export;
};

get "/css_tags" => sub {
    assets->include("/css/something1.css");
    assets->include("/css/something2.css");
    assets->include("/css/something3.css");
    assets->export;
};

true;
