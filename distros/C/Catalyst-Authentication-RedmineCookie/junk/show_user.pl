#!/usr/bin/env perl

use rlib qw(../inc ../lib);
use Modern::Perl;
use base qw(App::Cmd::Simple);

use Catalyst::Authentication::RedmineCookie::Schema;
use JSON::MaybeXS;
use MyContainer;

sub opt_spec {
    (
        [ "login=s", "SELECT * FROM users WHERE login = <specify>", { required => 1 } ],
    );
}

sub execute {
    my ($self, $opt, $args) = @_;

    binmode STDOUT, ":utf8";

    my $schema = Catalyst::Authentication::RedmineCookie::Schema->connect(
        @{ container('config')->{web}{'Model::DBIC'}{connect_info} || die }
    );

    my $cols = sub {
        my ($obj) = @_;
        state $json = JSON::MaybeXS->new( canonical => 1, pretty => 1, );
        $json->encode( { $obj->get_columns } );
    };

    say "--> user";
    my $user = $schema->resultset('Users')->find( { login => $opt->{login} } );
    unless ($user) {
        say "user not found.";
        return;
    }
    print $user->$cols;
    say "";

    for my $rel (qw(user_preference roles groups projects)) {
        say "--> $rel";
        print $_->$cols for $user->$rel;
        say "";
    }
}

__PACKAGE__->import->run;
