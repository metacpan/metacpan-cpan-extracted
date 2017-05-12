package API::ISPManager::misc;

use strict;
use warnings;

use API::ISPManager;

sub reload {
    my $params = shift;

    my $server_answer = API::ISPManager::query_abstract(
        params      => $params,
        func        => 'restart',
    );

    if ( $server_answer && $server_answer->{elem} && ref $server_answer->{elem} eq 'HASH' ) {
        return { data =>  $server_answer->{elem} };
    }

    return $server_answer;
}

sub usrparam {
    my $params = shift;
    
     my $server_answer = API::ISPManager::query_abstract(
        params      => $params,
        func        => 'usrparam',
     );

    return $server_answer;
}

# Only for BillManager
sub accountinfo {
    my $params = shift;

     my $server_answer = API::ISPManager::query_abstract(
        params      => $params,
        func        => 'accountinfo',
     );

    return $server_answer;
}

# Only for BillManager
sub discountinfo {
    my $params = shift;

     my $server_answer = API::ISPManager::query_abstract(
        params      => $params,
        func        => 'discountinfo',
     );

    if ($server_answer && ref $server_answer eq 'HASH' && $server_answer->{elem}) {
        return $server_answer->{elem};
    }   

    return $server_answer;
}

1;
