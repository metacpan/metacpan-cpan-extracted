package API::ISPManager::dns;

use strict;
use warnings;

use API::ISPManager;

sub list {
    my $params = shift;

    my $server_answer = API::ISPManager::query_abstract(
        params      => $params,
        func        => 'domain',
        fake_answer => shift,
    );

    #if ( $server_answer && $server_answer->{elem} && ref $server_answer->{elem} eq 'HASH' ) {
    #    return { data =>  $server_answer->{elem} };
    #}

    return $server_answer;
}

sub get {
    my $params = shift;

     my $server_answer = API::ISPManager::query_abstract(
        params      => $params,
        func        => 'domain.edit',
        fake_answer => shift,
    );
    return $server_answer;
   
}

sub edit {
    my $params = shift;

     my $server_answer = API::ISPManager::query_abstract(
        params      => { %$params, sok => 'yes' },
        func        => 'domain.edit',
        allowed_fields => [qw(host path allow_http sok   owner elid mx ns ip)], 
        fake_answer => shift,
    );
    return $server_answer;
   
}

sub sublist {
    my $params = shift;

     my $server_answer = API::ISPManager::query_abstract(
        params      => $params,
        func        => 'domain.sublist',
        fake_answer => shift,
    );
    return $server_answer;
   
}

sub sublist_get {
    my $params = shift;

     my $server_answer = API::ISPManager::query_abstract(
        params      => $params,
        func        => 'domain.sublist.edit',
        fake_answer => shift,
    );
    return $server_answer;
   
}

sub sublist_edit {
    my $params = shift;

     my $server_answer = API::ISPManager::query_abstract(
        params      => { %$params, sok => 'yes' },
        func        => 'domain.sublist.edit',
        fake_answer => shift,
    );
    return $server_answer;
   
}

1;
