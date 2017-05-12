package API::ISPManager::order;

use strict;
use warnings;

use API::ISPManager;
use Data::Dumper;

sub list {
    my $params = shift;

    my $result = API::ISPManager::query_abstract(
        params => $params,
        func   => 'order',
    );

    if ($result && ref $result eq 'HASH' && $result->{elem}) {
        return $result->{elem};
    } 

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
