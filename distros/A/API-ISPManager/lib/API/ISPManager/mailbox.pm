package API::ISPManager::mailbox;

use strict;
use warnings;

use API::ISPManager;

sub list {
    my $params = shift;

    return API::ISPManager::query_abstract(
        params => $params,
        func   => 'email'
    );
}

# Create domain
sub create {
    my $params = shift;

    my $result = API::ISPManager::query_abstract(
        params => { %$params, sok => 'yes' }, # чтобы создание разрешить
        func   => 'email.edit', 
        allowed_fields => [  qw( host path allow_http  sok name domain aliases passwd confirm quota forward rmlocal greylist spamassassin note ) ],
    );

    $API::ISPManager::last_answer = $result;

    if ($result && $result->{ok}) {
        return 1;
    } else {
        return '';
    }
}

# Edit email data
sub edit {

}

# Delete email from panel
sub delete {

}

1;
