package API::ISPManager::vdspreset;

use API::ISPManager;

sub create {


}


sub edit {


}

sub get {
    my $params = shift;
   
    my $result = API::ISPManager::query_abstract(
        params => $params,
        func   => 'vdspreset.edit',  
        allowed_fields => [  qw( host path allow_http  elid) ],
    );
  
    return $result;
}


sub list {
    my $params = shift;
    my $result = API::ISPManager::query_abstract(
        params => $params,
        func   => 'vdspreset',
        allowed_fields => [  qw( host path allow_http ) ],
    );

    my $plans = $result->{elem};
    
    return $plans;
}


sub delete {


}



1;
