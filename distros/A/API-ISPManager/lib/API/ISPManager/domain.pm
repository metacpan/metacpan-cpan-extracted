package API::ISPManager::domain;

use strict;
use warnings;

use API::ISPManager;

sub list {
    my $params = shift;

    return API::ISPManager::query_abstract(
        params => $params,
        func   => 'wwwdomain'
    );
}

# Create domain
sub create {
    my $params = shift;

    my $result = API::ISPManager::query_abstract(
        params => { %$params, sok => 'yes' }, # чтобы создание разрешить
        func   => 'wwwdomain.edit', 
        allowed_fields => [  qw( host path allow_http     domain alias sok name owner ip docroot cgi php ssi ror ssl sslport admin ) ],
    );

    $API::ISPManager::last_answer = $result;

    if ($result && $result->{ok}) {
        return 1;
    } else {
        return '';
    }
}

# Edit domain data
sub edit {

}

# Delete domain from panel
sub delete {

}

package API::ISPManager::email_domain;

use API::ISPManager;

sub list {
    my $params = shift;

    return API::ISPManager::query_abstract(
        params => $params,
        func   => 'emaildomain'
    );
}

# Create domain
sub create {

}

# Edit domain data
sub edit {

}

# Delete domain from panel
sub delete {

}

1;
