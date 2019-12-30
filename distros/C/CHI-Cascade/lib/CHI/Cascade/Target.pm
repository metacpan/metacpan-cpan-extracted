package CHI::Cascade::Target;

use strict;
use warnings;

use Time::HiRes;
use Time::Duration::Parse;

sub new {
    my ($class, %opts) = @_;

    bless { %opts }, ref($class) || $class;
}

sub lock {
    $_[0]->{locked} = $$;
}

sub locked {
    exists $_[0]->{locked}
      and $_[0]->{locked};
}

sub unlock {
    delete $_[0]->{locked};
}

sub time {
    $_[0]->{time} || 0;
}

sub touch {
    $_[0]->{time} = Time::HiRes::time;
    delete $_[0]->{finish_time};
    delete $_[0]->{expires_finish_time};
}

sub actual_stamp {
    $_[0]->{actual_stamp} = Time::HiRes::time;
}

sub is_actual {
    ( $_[0]->{actual_stamp} || $_[0]->{time} || 0 ) + $_[1] >= Time::HiRes::time;
}

sub ttl {
    my $self = shift;

    if (@_) {
        $self->{finish_time} = ( $_[1] || Time::HiRes::time ) + $_[0];
        return $self;
    }
    else {
        return exists $self->{finish_time} && $self->{finish_time} ? $self->{finish_time} - Time::HiRes::time : undef;
    }
}

sub expires {
    my $self = shift;
    my $expires = $_[0];

    if (@_) {
        return $expires
          if $expires eq 'never' || $expires eq 'now';

        $self->{expires_finish_time} = Time::HiRes::time + parse_duration( $expires );
        return $expires;
    }
    else {
        return
            exists $self->{expires_finish_time} && $self->{expires_finish_time}
            ?
                (
                    $self->{expires_finish_time} > Time::HiRes::time
                    ?
                        int( $self->{expires_finish_time} - Time::HiRes::time + 0.5 ) || 'now'
                    :
                        'now'
                )
            :
                undef;
    }
}

1;
