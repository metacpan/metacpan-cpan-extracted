package API::ISPManager::ip;

use strict;
use warnings;

use API::ISPManager;
use Data::Dumper;

sub list {
    my $params = shift;

    my $server_answer = API::ISPManager::query_abstract(
        params => $params,
        func   => 'iplist',
        parser_params =>  { ForceArray => qr/^elem$/ } 
    );

    ###warn Dumper($server_answer);

    if ( $server_answer && $server_answer->{elem} && ref $server_answer->{elem} eq 'HASH' ) {
        my $ip_list = [ ];

        for (keys %{ $server_answer->{elem} }) {
            push @$ip_list, $_;
        }

        $server_answer = $ip_list;
    }

    return $server_answer;
}

1;
