#!/usr/bin/perl

use strict;
use warnings;
use utf8;
use Test::Most;
# use Test::FailWarnings;
use Test::Output;

use Path::Tiny;

use lib 't/lib';
use TestUtils;

use_ok "App::CatalystStarter::Bloated";

my(
    $root_controller_plain,
    $root_controller_with_response_body_commented_out,
    $root_controller_with_jumbotron,
    $root_controller_with_both,
);

## Need to import these or there will be trouble when the perl module
## code doesn't load
use Catalyst::View;
use Catalyst::View::TT;

note "index changed in Root";

{
    my $f = Path::Tiny->tempfile;
    $f->spew( $root_controller_plain );
    stderr_like(
        sub { App::CatalystStarter::Bloated::_verify_Root_index($f) },
        qr/Failed fixing Root controller\. Comment out the response body line\./,
        "Detects when Root controller does not have index commented out"
    );
}

{
    my $f = Path::Tiny->tempfile;
    $f->spew( $root_controller_with_response_body_commented_out );
    stderr_is(
        sub { App::CatalystStarter::Bloated::_verify_Root_index($f) },
        "",
        "Root controller index ok"
    );
}

{
    my $f = Path::Tiny->tempfile;
    $f->spew( $root_controller_with_both );
    stderr_is(
        sub { App::CatalystStarter::Bloated::_verify_Root_index($f) },
        "",
        "Root controller index ok when both are ok"
    );
}

note "jumbotron added to Root";

{
    my $f = Path::Tiny->tempfile;
    $f->spew( $root_controller_plain );
    stderr_like(
        sub { App::CatalystStarter::Bloated::_verify_Root_jumbatron($f) },
        qr/Failed adding jumbotron example to Root controller/,
        "Detects when Root controller does not have jumbotron"
    );
}

{
    my $f = Path::Tiny->tempfile;
    $f->spew( $root_controller_with_jumbotron );
    stderr_is(
        sub { App::CatalystStarter::Bloated::_verify_Root_jumbatron($f) },
        "",
        "Detects when Root controller does have jumbotron"
    );
}

{
    my $f = Path::Tiny->tempfile;
    $f->spew( $root_controller_with_both );
    stderr_is(
        sub { App::CatalystStarter::Bloated::_verify_Root_jumbatron($f) },
        "",
        "Root controller jumbotron ok when both are ok"
    );
}


done_testing;

BEGIN {

    $root_controller_plain = <<'EOC';
sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    # Hello World
    $c->response->body( $c->welcome_message );
}
EOC

    $root_controller_with_response_body_commented_out = <<'EOC';
sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    # Hello World
    # $c->response->body( $c->welcome_message );
}
EOC

    $root_controller_with_jumbotron = <<'EOC';
sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    # Hello World
    $c->response->body( $c->welcome_message );
    $c->stash->{jumbotron} = { header => "Splashy message", body => "This is a 'jumbotron' header, view source and check Root controller for details" };
}
EOC

    $root_controller_with_both = <<'EOC';
sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    # Hello World
    # $c->response->body( $c->welcome_message );
    $c->stash->{jumbotron} = { header => "Splashy message", body => "This is a 'jumbotron' header, view source and check Root controller for details" };

}
EOC

}
