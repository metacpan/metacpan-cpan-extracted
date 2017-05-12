package API::ISPManager::diskpreset;

use API::ISPManager;

sub create {


}


sub edit {

}

sub get {

}


sub list {
    my $params = shift;

    my $result = API::ISPManager::query_abstract(
        params => $params,
        func   => 'disktempl',
        allowed_fields => [ qw( host path allow_http ) ],
    );

    my $disk_templ = $result->{elem};
    
    return $disk_templ;
}


sub delete {


}



1;
