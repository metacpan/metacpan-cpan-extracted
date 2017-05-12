use strict;
use warnings;
use Test::Clustericious::Log;
use Test::More tests => 23;
use Clustericious::Client::Command;
use YAML::XS qw( Dump );
use Capture::Tiny qw( capture );

package Baker;

use Clustericious::Client;

route 'roll' => '/it';
route 'bake' => '/it/please';

route_doc 'put'  => "Put the bread in the oven";
route_doc 'roll' => "Roll the bread";
route_doc 'eat'  => "Eat the bread";

route_meta 'bake' => { temperature => "hot" };
route_args 'put' => [
        { name => 'where',                  type => '=s', required => 1, doc => 'where to bake the bread' },
        { name => 'for',                    type => '=s', required => 1, doc => 'for whom to bake the bread' },
        { name => 'when',                   type => '=s', required => 0, doc => 'when to bake the bread' },
        { name => 'dry_run',    alt => 'n', type => '',   required => 0, },
        { name => 'temperature',            type => ':i', required => 0, }
    ];
route_args 'eat' => [
        { name => 'food', type => "=s", preprocess => "yamldoc", doc => "what food to eat" },
    ];
route_args 'fry' => [
    { name => 'dry_run' },
    { name => 'what', type => '=s' },
    { name => 'things', type => '=s', preprocess => 'list' },
];

route 'grant' => 'POST' => '/grant';
route_args 'grant' => [
  { name => 'user',     type => '=s', modifies_url => 'append', positional => 'one' },
  { name => 'action',   type => '=s', modifies_url => 'append', positional => 'one' },
  { name => 'resource', type => '=s', modifies_url => 'append', positional => 'one' },
];

route 'grant_pos' => 'POST' => '/grant_pos';
route_args 'grant_pos' => [
  { name => 'a', type => '=s', modifies_url => 'append', positional => 'one' },
  { name => 'b', type => '=s', modifies_url => 'append', positional => 'one' },
  { name => 'c', type => '=s', modifies_url => 'append', positional => 'one' },
  { name => 'd', type => '=s', modifies_url => 'append', positional => 'one' },
  { name => 'e', type => '=s', modifies_url => 'append', positional => 'one' },
  { name => 'f', type => '=s', modifies_url => 'append', positional => 'one' },
  { name => 'g', type => '=s', modifies_url => 'append', positional => 'one' },
];

route 'grant_named' => 'POST' => '/grant_named';
route_args 'grant_named' => [
  { name => 'user',     type => '=s', modifies_url => 'append',},
  { name => 'action',   type => '=s', modifies_url => 'append',},
  { name => 'resource', type => '=s', modifies_url => 'append',},
];

route_args 'ingest' => [
    { name => 'archiveset', type => '=i', alt => 'archive_set' },
    { name => 'url',        type => '=s'                       },
    { name => 'filename',   positional => 'many'               },
];

route_args 'one_with_args' => [
  { name => 'somearg', type => '=s'   },
  { name => 'posarg', type => '=s', positional => "one" },
];

route 'payload' => POST => '/payload';
route_args 'payload' => [
    { name => 'this', type => '=s', modifies_payload => 'hash' },
    { name => 'that', type => '=s', modifies_payload => 'array', key => "theother" }
];

# TODO ensure no { command_line => 1 } if no route_args.
our $argsWeGot;
for my $sub (qw/put eat fry ingest one_with_args/) {
       eval "sub $sub { ".<<'DONE'
    my $self = shift;
    my %args = $self->meta_for->process_args(@_);
    $argsWeGot = [ got => \%args ];
    return [ got => \%args ];
}
DONE
   }

sub legacy {
    my $self = shift;
    my @args = @_;
    $argsWeGot = [ got => \@args ];
    return [ got => \@args ];
}


package main;

my $client = Baker->new(server_url => 'http://127.0.0.1');

is($client->meta_for("roll")->doc, "Roll the bread", "Set metadata");
is($client->meta_for("bake")->get("temperature"), "hot", "Set metadata");

ok $client->can('roll'), 'can roll';
ok $client->can('bake'), 'can bake';
ok $client->can('put'),  'can put';

my $ret;

$ret = $client->put(where => "in the oven", for => "baby and me");
is_deeply($ret, [ got => {where => "in the oven", for => "baby and me"}], 'got args back' )
    or diag explain $ret;
undef $argsWeGot;

capture { Clustericious::Client::Command->run( $client, ( "put", "--where", 'in the oven', "--for=baby_and_me" ) ) };
is_deeply $argsWeGot, [got => { where => 'in the oven', for => "baby_and_me" }], "cli args with equals sign parsed"
    or diag explain $argsWeGot;
undef $argsWeGot;

capture { Clustericious::Client::Command->run( $client, ( "legacy", qw/a b c/ ) ) };
is_deeply $argsWeGot, [got => [qw/a b c/]], 'default positional params' or diag explain $argsWeGot;

{
    local $SIG{__WARN__} = sub {}; # no stderr messages
    # missing arg
    eval { capture { Clustericious::Client::Command->run($client, put => '--where' => 'there' ) } };
    ok $@, "exception for missing arg";
    like $@, qr/required/, 'message has required';

    # extra arg
    eval { capture { Clustericious::Client::Command->run($client, put => '--baby' => 'there' ) } };
    ok $@, "exception for invalid option";
    like $@, qr/missing/i, 'message has invalid';
}

my $struct = { some => [ deep => struct => { here => 12 } ] };
ok $client->eat(food => $struct);
is_deeply $argsWeGot, [ got => {food => $struct}], "struct sent as a param" or diag explain $argsWeGot;
undef $argsWeGot;

#ok $client->eat(food => Dump($struct));
#is_deeply $argsWeGot, [ got => { food => $struct}], "struct sent as yaml";
#undef $argsWeGot;

my $tmp = File::Temp->new;
print $tmp Dump($struct);
close $tmp;

#ok $client->eat(food => "$tmp");
#is_deeply $argsWeGot, [ got => { food => $struct}], "struct sent as filename";
#undef $argsWeGot;

capture { Clustericious::Client::Command->run($client, eat => "--food" => "$tmp") };
is_deeply $argsWeGot, [ got => { food => $struct}], "struct sent as filename to command";
undef $argsWeGot;

# Boolean arg
$tmp = File::Temp->new;
print $tmp join "\n", qw/a b c/;
close $tmp;
capture { Clustericious::Client::Command->run($client, fry => '--dry_run', '--what' => 'bread', '--things' => "$tmp" ) };
is_deeply $argsWeGot, [ got => { what => 'bread', dry_run => 1, things => [qw/a b c/] } ];
undef $argsWeGot;

$client->fry(things => [qw/a b c/]);
is_deeply($argsWeGot, [ got => { things => [qw/a b c/] }], "got arrayref for list");

$client->grant('foo','bar','baz');
is $client->tx->req->url->path, '/grant/foo/bar/baz';

$client->grant_pos(1,2,3,4,5,6,7);
is $client->tx->req->url->path, '/grant_pos/1/2/3/4/5/6/7';

$client->grant_named(user => 'foo',action => 'bar',resource => 'baz');
is $client->tx->req->url->path, '/grant_named/foo/bar/baz';

$ret = $client->ingest(archiveset => 100, "first_file", "second_file", "third_file");
is_deeply($ret, [got => {archiveset => 100, filename => [qw/first_file second_file third_file/]}], "named and multi-positional")
    or diag explain $ret;

$ret = $client->one_with_args(somearg => "foo", "flubber");
is_deeply($ret, [ got => {somearg => "foo", posarg => "flubber"} ], "named and positional");

$ret = $client->payload(this => 'foo', that => "bar");
is_deeply($client->tx->req->json, { this => 'foo', theother => [ 'that' => 'bar' ] } )
    or diag explain $client->tx->req->json;


