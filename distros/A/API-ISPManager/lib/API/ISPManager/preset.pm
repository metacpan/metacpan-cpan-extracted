package API::ISPManager::preset;

use API::ISPManager;

sub create {


}


sub edit {


}

sub get {
    my $params = shift;
   
    my $result = API::ISPManager::query_abstract(
        params => $params,
        func   => 'preset.edit',  
        allowed_fields => [  qw( host path allow_http  elid) ],
    );
  
    if (ref $result->{php} eq 'HASH' ) {
        $result->{php} = 'on';
    }
 
    if (ref $result->{phpmod} eq 'HASH' ) {
        $result->{phpmod} = 'on';
    }

    return '' if $result->{error};

    return $result;
}


sub list {
    my $params = shift;
    my $result = API::ISPManager::query_abstract(
        params => $params,
        func   => 'preset',
        allowed_fields => [  qw( host path allow_http ) ],
    );

    my $plans = $result->{elem};
    
    for (keys %$plans) {
        for my $param ( 'ssl', 'ssi', 'php' ) {
            my $val = $plans->{$_}->{$param};

            if ( $val && ref $val eq 'HASH' ) {
                $plans->{$_}->{$param} = 'on';
            }
        } 
    }

    return $plans;
}


sub delete {


}



1;
