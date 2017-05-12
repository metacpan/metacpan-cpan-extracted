package CGI::Session::Serialize::sql_abstract;
require CGI::Session::ErrorHandler;
use vars qw(@ISA $VERSION);

@ISA = qw( CGI::Session::ErrorHandler );

use strict;

$VERSION = 0.70;

# here's the kind of Perl -> SQL that's happening here

#  _SESSION_ID =>                           session_id
#  _SESSION_CTIME (seconds since epoch) =>  creation_time (as timestamp)
#  _SESSION_ATIME (seconds since epoch) =>  last_access_time (as timestamp)
#  _SESSION_ETIME (seconds)             =>  duration (as interval)
#  _SESSION_REMOTE_ADDR                 =>  remote_addr
#  _SESSION_EXPIRE_LIST => {
#       field_name   => $seconds        =>  field_name_exp_secs
#       ...
# },


sub freeze {
    my ($self,$data) = @_;
    return undef unless ref $data;

    my %sql = (
        session_id          => $data->{_SESSION_ID},
        creation_time       => _time_to_iso8601($data->{_SESSION_CTIME}),
        last_access_time    => _time_to_iso8601($data->{_SESSION_ATIME}),
        # 'ETIME' was such a bad name, we rename it to 'duration'
        # I mean, ATIME and CTIMES are *times*, wouldn't you expect ETIME to be a time, too?
        # Instead, it's a duration until expiration, it seconds
        duration            => ($data->{_SESSION_ETIME} && "$data->{_SESSION_ETIME} seconds"),
        remote_addr         => $data->{_SESSION_REMOTE_ADDR},
    );

    for my $field (keys %{ $data->{_SESSION_EXPIRE_LIST} }) {
        $sql{$field.'_exp_secs'} = $data->{_SESSION_EXPIRE_LIST}->{$field};
    }

    # pass the rest through unchanged
    for (grep {!/^_SESSION/} keys %$data) {
        $sql{$_} = $data->{$_};
    }

    return \%sql;

}

# convert from seconds-from-epoch to ISO 8601 standard time format
sub _time_to_iso8601 {
    my $time = shift || return undef;
    require Date::Calc;
    import  Date::Calc (qw/Localtime/);
#   import  Date::Calc (qw/Time_to_Date/);

    my ($y,$M,$d,$h,$m,$s) = Localtime($time);
#   my ($y,$M,$d,$h,$m,$s) = Time_to_Date($time);

    # Sometimes bad dates return answers near the Epoch.
    # Since this is a session handling module, sessions
    # should never have dates over 30 years in the past...
    if ($y <= 1970 ) {
        return undef;
    }
    else {
        # 'YYYY-MM-DD HH:mm:SS'
        return sprintf ('%04d-%02d-%02d %02d:%02d:%02d', $y,$M,$d,$h,$m,$s );
    }



}


# convert from the database format back to CGI::Session format
sub thaw {
    my ($self,$data) = @_;
    return undef unless ref $data;

    my %out = (
        _SESSION_ID             => $data->{session_id},
        _SESSION_CTIME          => $data->{creation_time},    # Times from DB should be in Epoch fmt already
        _SESSION_ATIME          => $data->{last_access_time},
        _SESSION_ETIME          => $data->{end_time},
        _SESSION_REMOTE_ADDR    => $data->{remote_addr},
    );
    for (keys %$data) {
        if (/(.*)_exp_secs$/) {
            $out{_SESSION_EXPIRE_LIST}->{$1} = $data->{$_};
        }
    }

    # pass the rest through unchanged
    for (grep {!/^(session_id|creation_time|last_access_time|end_time|remote_addr)$|_exp_secs$/} keys %$data) {
        $out{$_} = $data->{$_};
    }

    return \%out;
}

1;
