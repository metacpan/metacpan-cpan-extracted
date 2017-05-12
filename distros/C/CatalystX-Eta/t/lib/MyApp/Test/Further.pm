package MyApp::Test::Further;

use strict;
use warnings;
use utf8;
use URI;

use Carp;

use CatalystX::Eta::Test::REST;

use JSON::MaybeXS;
use Test::More;

use Catalyst::Test q(MyApp);

# ugly hack
sub import {

    strict->import;
    warnings->import;

    no strict 'refs';

    my $caller = caller;

    while ( my ( $name, $symbol ) = each %{ __PACKAGE__ . '::' } ) {
        next if $name eq 'BEGIN';     # don't export BEGIN blocks
        next if $name eq 'import';    # don't export this sub
        next unless *{$symbol}{CODE}; # export subs only

        my $imported = $caller . '::' . $name;
        *{$imported} = \*{$symbol};
    }
}

my $obj = CatalystX::Eta::Test::REST->new(
    do_request => sub {
        my $req = shift;

        #use DDP; p $req;
        eval 'use DDP; do{my $x = $req->as_string; p $x}' if exists $ENV{TRACE} && $ENV{TRACE};
        my ( $res, $c ) = ctx_request($req);
        eval 'use DDP; do{my $x = $res->as_string; p $x}' if exists $ENV{TRACE} && $ENV{TRACE};
        return $res;
    },
    decode_response => sub {
        my $res = shift;
        return decode_json( $res->content );
    }
);

for (qw/rest_get rest_put rest_head rest_delete rest_post rest_reload rest_reload_list/) {
    eval( 'sub ' . $_ . ' { return $obj->' . $_ . '(@_) }' );
}

sub stash_test($&) {
    $obj->stash_ctx(@_);
}

sub stash($) {
    $obj->stash->{ $_[0] };
}

sub test_instance { $obj }

sub db_transaction (&) {
    my ( $subref, $modelname ) = @_;

    my $schema = MyApp->model( $modelname || 'DB' );

    eval {
        $schema->txn_do(
            sub {
                $subref->($schema);
                die 'rollback';
            }
        );
    };

    die $@ unless $@ =~ /rollback/;

}

my $auth_user;

sub api_auth_as {
    my (%conf) = @_;

    $conf{user_id} ||= 1;

    croak 'api_auth_as: roles does not work anymoe'
      if exists $conf{roles};

    my $schema = MyApp->model( exists $conf{model} ? $conf{model} : 'DB' );

    if ( !$auth_user || $auth_user->{id} != $conf{user_id} ) {

        my $user = $schema->resultset('User')->find( $conf{user_id} );

        croak 'api_auth_as: user not found' unless $user;

        my $item = $user->sessions->create(
            {
                api_key => int( rand(time) )
            }
        );

        $auth_user = {
            id      => $conf{user_id},
            api_key => $item->api_key
        };

    }

    $obj->fixed_headers( [ 'x-api-key' => $auth_user->{api_key} ] );

}

sub api_auth_as_nobody {
    undef $auth_user;

    #$CatalystX::Eta::Test::REST::api_key = undef;
    $obj->fixed_headers( [] );
}

sub check_invalid_error ($$$) {
    my ( $stash_or_json, $key, $check_for ) = @_;

    my $obj = ref $stash_or_json eq 'HASH' ? $stash_or_json : undef;
    unless ($obj) {
        $obj = stash $stash_or_json;
        croak "missing error on stash $stash_or_json" unless $obj && exists $obj->{form_error};
        $obj = $obj->{form_error};
    }

    is( $obj->{$key}, $check_for, "$key is $check_for" );
}

sub create_default_user {

    $obj->rest_post(
        '/users',
        name  => 'add user',
        stash => 'user',
        [
            name          => 'Foo Bar',
            email         => 'foo1@email.com',
            password      => 'foobarquux1',
            role          => 'user',
            mobile_number => '1122334455'
        ]
    );
}

1;
