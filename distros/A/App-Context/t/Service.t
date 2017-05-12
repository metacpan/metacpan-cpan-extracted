#!/usr/local/bin/perl -w

use Test::More qw(no_plan);
use lib "lib";
use lib "../lib";

BEGIN {
   use_ok("App");
}

my ($context);

$context = App->context(
    conf_file => "",
    conf => {
        Service => {
            default => {
                class => "App::Service",
            },
        },
    },
);
$service = $context->service("Service");

ok(defined $service, "constructor ok");
isa_ok($service, "App::Service", "right class");
is($service->service_type(), "Service", "right service type");
$dump = $service->dump();
ok($dump =~ /^\$Service__default = /, "dump");

exit 0;

