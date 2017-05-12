package API::ISPManager::db;

use strict;
use warnings;

use API::ISPManager;

sub list {
    my $params = shift;

    my $server_answer = API::ISPManager::query_abstract(
        params      => $params,
        func        => 'db',
        fake_answer => shift,
    );

    if ( $server_answer         &&
         $server_answer->{elem} &&
         ref $server_answer->{elem} eq 'HASH' ) {

        return { data =>  $server_answer->{elem} };

    }

    return $server_answer;
}


sub create {
   my $params = shift;
    
    my $result = API::ISPManager::query_abstract(
        params          => { %$params, sok => 'yes' },
        func            => 'db.edit',
        allowed_fields  => [ qw( host path allow_http  sok name dbtype owner dbencoding dbuser dbusername dbpassword dbconfirm dbuserhost ) ],
    );

    $API::ISPManager::last_answer = $result;     

    if ($result && $result->{ok}) {
        return 1;
    } else {
        return '';
    }
}


package API::ISPManager::db_user;

use API::ISPManager;

sub list {
    my $params = shift;

    my $server_answer = API::ISPManager::query_abstract(
        params      => $params,
        func        => 'db.users',
        allowed_fields => [ 'host', 'path', 'allow_http', 'elid' ],
        fake_answer => shift,
    );

    if ( $server_answer         &&
         $server_answer->{elem} &&
         ref $server_answer->{elem} eq 'HASH' ) {

        return { data =>  $server_answer->{elem} };

    }

    return $server_answer;
}


1;
