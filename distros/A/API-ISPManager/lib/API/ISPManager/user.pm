package API::ISPManager::user;

use strict;
use warnings;

use API::ISPManager;
use Data::Dumper;

sub list {
    my $params = shift;

    return API::ISPManager::query_abstract(
        params => $params,
        func   => 'user',
    );
}

# Âîçâğàùàåò ÷èñëî àêòèâíûõ ïîëüçîâàòåëåé
sub active_user_count {
    my $params = shift;
    my $ans = API::ISPManager::user::list($params);
    
    my $result = 0;
    foreach my $key (keys %{$ans->{elem}}) {
        $result++ unless exists $ans->{elem}->{$key}->{disabled};
    }

    return $result;
}

# Ğ¡Ğ¾Ğ·Ğ´Ğ°Ñ‚ÑŒ ĞºĞ»Ğ¸ĞµĞ½Ñ‚Ğ° (Ğ²Ğ¾Ğ·Ğ¼Ğ¾Ğ¶Ğ½Ğ¾, Ğ²Ğ¼ĞµÑÑ‚Ğµ Ñ Ğ´Ğ¾Ğ¼ĞµĞ½Ğ¾Ğ¼)
sub create {
    my $params = shift;

    my $result = API::ISPManager::query_abstract(
        params => { %$params, sok => 'yes' }, # Ñ‡Ñ‚Ğ¾Ğ±Ñ‹ ÑĞ¾Ğ·Ğ´Ğ°Ğ½Ğ¸Ğµ Ñ€Ğ°Ğ·Ñ€ĞµÑˆĞ¸Ñ‚ÑŒ
        func   => 'user.edit', 
        allowed_fields => [  qw( host path allow_http     sok name domain email preset ip passwd ) ],
    );

    $API::ISPManager::last_answer = $result;
    #warn Dumper($API::ISPManager::last_answer);

    if ($result &&
        ref $result eq 'HASH' &&
        (
            $result->{ok} or
            ( $result->{error} && ref $result->{error} eq 'HASH' && $result->{error}->{code} eq '2' && $result->{error}->{obj} eq 'user' )  # already exists
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
        func   => 'user.edit',
        allowed_fields => [  qw( host path allow_http     sok elid name domain email preset ip passwd ftplimit disklimit ssl ssi phpmod safemode  maillimit domainlimit webdomainlimit maildomainlimit baselimit baseuserlimit bandwidthlimit phpfcgi) ],
    );

    return $result;
}

# Delete user from panel
sub delete {
    my $params = shift;

    my $result = abstract_bool_manipulate($params, 'user.delete');
 
    $API::ISPManager::last_answer = $result;

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

    my $result = abstract_bool_manipulate($params, 'user.enable');

    $API::ISPManager::last_answer = $result;

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

    my $result = abstract_bool_manipulate($params, 'user.disable');

    $API::ISPManager::last_answer = $result;

    if ($result && ref $result eq 'HASH' && $result->{ok}) {
        return 1;
    } else {
        return '';
    }
}

1;
