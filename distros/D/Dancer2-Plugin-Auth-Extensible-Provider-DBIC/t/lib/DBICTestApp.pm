package DBICTestApp;
use strict;
use warnings;
use Dancer2 appname => 'TestApp';
use Dancer2::Plugin::Auth::Extensible;
use Scalar::Util qw(blessed);

get '/dbic_update_user_role/:realm' => sub {
    my $realm = param 'realm';
    my $user = update_user 'mark',
      realm => $realm,
      role  => { CiderDrinker => 1 };

    if ( blessed($user) ) {
        $user = +{ $user->get_columns };
    }
    send_as YAML => $user;
};

get '/dbic_cider' => require_role CiderDrinker => sub {
    "You can have a cider";
};


1;
