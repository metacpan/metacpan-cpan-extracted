package API::ISPManager::services;

use strict;
use warnings;

use API::ISPManager;

sub get {
    my $params = shift;

    my $server_answer = API::ISPManager::query_abstract(
        params      => $params,
        func        => 'services',
        fake_answer => shift,
    );

    if ( $server_answer && $server_answer->{elem} && ref $server_answer->{elem} eq 'HASH' ) {
        return { data =>  $server_answer->{elem} };
    }

    return $server_answer;
}

1;
