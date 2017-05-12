package API::ISPManager::software;

use strict;
use warnings;

use API::ISPManager;
use Data::Dumper;

sub list {
    my $params = shift;

    my $result = API::ISPManager::query_abstract(
        params => $params,
        func   => 'software',
    );

    if ($result && ref $result eq 'HASH' && $result->{elem}) { 
       return $result->{elem};
    }

    return $result;
}

sub get {
    my $params = shift;

    my $result = API::ISPManager::query_abstract(
        params => $params, # чтобы создание разрешить
        func   => 'software.edit',
        allowed_fields => [  qw( host path allow_http    elid ) ],
    );

    return $result;
}

sub renew {
    my $params = shift;

    my $result = API::ISPManager::query_abstract(
        params => $params, # чтобы создание разрешить
        func   => 'software.period',
        allowed_fields => [  qw( host path allow_http    elid ) ],
    );

=head

cost	7.7000
elid	361604
expiredate	2009-10-08
func	software.period
ip	83.222.14.204
licname	testserver1.hosting.reg.ru
payfrom	neworder
period	16
pricename	ISPmanager Pro (without support)
sok	ok

=cut

    return $result;
}

# Создать клиента (возможно, вместе с доменом)
sub create {
    my $params = shift;

    my $result = API::ISPManager::query_abstract(
        params => { %$params, sok => 'yes' }, # чтобы создание разрешить
        func   => 'user.edit', 
        allowed_fields => [  qw( host path allow_http     sok name domain email preset ip passwd ) ],
    );

    $API::ISPManager::last_answer = $result;

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

1;
