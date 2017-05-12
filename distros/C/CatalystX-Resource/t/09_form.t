#!/usr/bin/env perl
use FindBin qw/$Bin/;
use lib "$Bin/lib";
use CatalystX::Resource::TestKit;
use Test::Exception;
use HTTP::Request::Common;

use Catalyst::Test qw/TestApp/;

my ($res, $c) = ctx_request('/');
my $schema = $c->model('DB')->schema;

ok(defined $schema, 'got a schema');
lives_ok(sub { $schema->deploy }, 'deploy schema');

# CREATE
{
    my $path ='/artists/create';
    my $res = request($path);
    ok($res->is_success, "$path returns HTTP 200");
    like($res->decoded_content, '/my_custom_field_label/s', q/added field with label 'my_custom_field_label' via $c->stash->{form_attrs_process}/);
    like($res->decoded_content, '/my_custom_name_label/s', q/label of field 'name' changed via $c->stash->{form_attrs_process}/);
}

done_testing;
