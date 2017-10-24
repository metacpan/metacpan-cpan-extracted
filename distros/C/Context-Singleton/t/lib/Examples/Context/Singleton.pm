
use strict;
use warnings;

package Examples::Context::Singleton;

our $VERSION = v1.0.0;

use Context::Singleton;

use Test::Spec::Util;

example it_should_know_about_rule => as {
    my ($title, %params) = @_;

    my $db = $params{db} // Context::Singleton::Frame::DB->instance;
    my $status = $db->find_builder_for ($params{rule});

    it "should know about rule $params{rule}" => as { ok $status };
};

example it_should_not_know_about_rule => as {
    my ($title, %params) = @_;

    my $db = $params{db} // Context::Singleton::Frame::DB->instance;
    my $status = $db->find_builder_for ($params{rule});

    it "should not know about rule $params{rule}" => as { ok !$status };
};

example it_should_load_rules => as {
    my ($title, %params) = @_;

    it_should_not_know_about_rule (rule => $_) for @{ $params{rules} };

    $params{loader}->();

    it_should_know_about_rule (rule => $_) for @{ $params{rules} };
};

example it_should_resolve_rule => as {
    my ($title, %params) = @_;

    my $value;
    my $lives_ok = eval { $value = deduce $params{rule}; 1 };
    my $err = $@;

    if ($lives_ok) {
        it "should deduce $params{rule}" => as { is_deeply $value, $params{expected} };
    } else {
        it "should not die while resolving $params{rule}" => as { diag "Sudden death: $err"; fail };
    }
};

example it_should_be_resolved => as {
    my ($title, %params) = @_;

    my $status = is_deduced $params{rule};

    it "should deduce $params{rule}" => as { ok $status };
};

example it_should_not_be_resolved => as {
    my ($title, %params) = @_;

    my $status = is_deduced $params{rule};

    it "should not deduce $params{rule}" => as { ok ! $status };
};

1;
