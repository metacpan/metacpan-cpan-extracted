package API::ISPManager::stat;

use strict;
use warnings;

use API::ISPManager;

sub sysinfo {
    my $params = shift;

    my $server_answer = API::ISPManager::query_abstract(
        params      => $params,
        fake_answer => shift,
        func        => shift || 'sysinfo', # TODO: stupid hack!
    );

    if ( $server_answer && $server_answer->{elem} && ref $server_answer->{elem} eq 'HASH' ) {
        my $stat_data = { };

        for (keys %{ $server_answer->{elem} } ) {
            $stat_data->{$_} = $server_answer->{elem}->{$_}->{value};
        }
    
        return { data => $stat_data  };
    }

    return $server_answer;
}

sub usagestat {
    my $params = shift;


    return sysinfo($params, shift || '', 'usagestat');
}



1;
