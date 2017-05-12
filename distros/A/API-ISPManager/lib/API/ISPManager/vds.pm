package API::ISPManager::vds;

use strict;
use warnings;

use API::ISPManager;
use Data::Dumper;

sub list {
    my $params = shift;

    my $result = API::ISPManager::query_abstract(
        params => $params,
        func   => 'vds',
    );

    return $result->{elem};
}

# Создать клиента (возможно, вместе с доменом)
sub create {
    my $params = shift;

    my $result = API::ISPManager::query_abstract(
        params => { %$params, sok => 'yes' }, # чтобы создание разрешить
        func   => 'vds.edit', 
        allowed_fields => [  qw( host path allow_http     
            sok name id ip passwd confirm owner vdspreset disktempl pvtdisk extns ispmgr
            disk mem  cpu proc desc traf note 
        ) ],
    );

    $API::ISPManager::last_answer = $result;

    return $result;

    if ($result &&
        ref $result eq 'HASH' &&
        (
            $result->{ok} or
            ( $result->{error} && ref $result->{error} eq 'HASH' && $result->{error}->{code} eq '2' )  # already exists
        )
    ) {
        return 1;  # { success => 1 };
    } else {
        return ''; # { success => '', error => Dumper ($result->{error}) };
    }
#https://ultrasam.ru/ispmanager/ispmgr?out=xml&auth=232143511
#&sok=yes&func=user.edit&name=nrgxxx&ip=78.47.76.69&passwd=qwerty&ftplimit=100&disklimit=200
}

# Edit user data
sub edit {
    my $params = shift;
    
    my $result = API::ISPManager::query_abstract(
        params => $params,
        func   => 'vds.edit',
        allowed_fields => [  qw( host path allow_http     sok elid name domain email preset ip passwd ftplimit disklimit ssl ssi phpmod safemode  maillimit domainlimit webdomainlimit maildomainlimit baselimit baseuserlimit bandwidthlimit) ],
    );

    return $result;
}

# Delete user from panel
sub delete {
    my $params = shift;

    my $result = abstract_bool_manipulate($params, 'user.delete');

    if ($result && ref $result eq 'HASH' && $result->{ok}) {
        return 1;
    } else {
        return '';
    }
}

# Abstract sub for bool ( on | off ) methods
sub abstract_bool_manipulate {
    my ($params, $type) = @_;

    return '' unless $params && $type;

    my $result = API::ISPManager::query_abstract(
        params => $params,
        func   => $type, 
        allowed_fields => [  qw( host path allow_http    elid) ],
    );

    return $result;
}

# Switch-on user account
# elid -- user name =)
sub enable {
    my $params = shift;

    my $result = abstract_bool_manipulate($params, 'vds.enable');

    if ($result && ref $result eq 'HASH' && $result->{ok}) {
        return 1;
    } else {
        return '';
    }
}

# Switch off user account
# elid -- user name =)
sub disable {
    my $params = shift;

    my $result = abstract_bool_manipulate($params, 'vds.disable');

    if ($result && ref $result eq 'HASH' && $result->{ok}) {
        return 1;
    } else {
        return '';
    }
}

1;
