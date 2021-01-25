package BoardStreams::Registry;

use Mojo::Base -strict, -signatures;

use BoardStreams::Util 'belongs_to';

use Safe::Isa;
use List::Util 'pairs', 'first';
use Scalar::Util 'reftype';
use Storable 'dclone';

no autovivification;

use experimental 'postderef';

my %user_to_channels;
my %channel_to_users;

sub create_empty_node {
    return {
        strings  => {},
        regexes  => [],
        actions  => {},
        requests => {},
        join     => undef,
        leave    => undef,
    };
}

# registry for actions, requests and join handlers
my $channels_info = create_empty_node;

sub set_var ($class, $channel, $var, @args) {
    my @segments = ref($channel) eq 'ARRAY' ? @$channel : ($channel);
    my $sub = pop @args;
    my $name; $name = pop @args unless $var eq 'join';
    my $cursor = $channels_info;
    SEGMENT: while (@segments) {
        my $segment = shift @segments;
        if (! ref $segment) {
            # $segment is a string
            if ($segment =~ /\:/) {
                unshift @segments, split(/\:/, $segment);
                next SEGMENT;
            }
            $cursor = $cursor->{strings}{$segment} //= create_empty_node;
        } elsif (ref $segment eq 'Regexp') {
            push $cursor->{regexes}->@*, $segment, create_empty_node;
            $cursor = $cursor->{regexes}[-1];
        } else {
            die "problematic channel path segment found while adding $var";
        }
    }

    if (belongs_to($var, [qw/ join leave /])) {
        $cursor->{$var} = $sub;
    } elsif (belongs_to($var, [qw/ action request /])) {
        $cursor->{"${var}s"}{$name} = $sub;
    } else {
        die "invalid var $var";
    }
}

sub get_var ($class, $channel, $var, $name = undef) {
    my @segments = split /\:/, $channel;
    my @cursors = ($channels_info);
    foreach my $segment (@segments) {
        @cursors = map {
            my $cursor = $_;
            my @ret;
            if (my $node = $cursor->{strings}{$segment}) {
                push @ret, $node;
            }
            foreach my $pair (pairs $cursor->{regexes}->@*) {
                my ($regex, $node) = @$pair;
                if ($segment =~ $regex) {
                    push @ret, $node;
                }
            }
            @ret;
        } @cursors;
    }

    if (belongs_to($var, [qw/ join leave /])) {
        return first {defined} map $_->{$var}, @cursors;
    } elsif (belongs_to($var, [qw/ action request /])) {
        return first {defined} map $_->{"${var}s"}{$name}, @cursors;
    } else {
        die "invalid var $var";
    }
}

sub debug_dump ($class) {
    use Data::Dumper;
    my %channel_to_users_clone;
    foreach my $channel_name (keys %channel_to_users) {
        $channel_to_users_clone{$channel_name} //= {};
        foreach my $user (keys $channel_to_users{$channel_name}->%*) {
            $channel_to_users_clone{$channel_name}{$user} = $user;
        }
    }
    warn Dumper({
        user_to_channels => \%user_to_channels,
        channel_to_users => \%channel_to_users_clone,
        channels_info    => $channels_info,
    });
}

sub add_pair ($class, $c, $channel_name) {

    my $was_added = not exists $channel_to_users{$channel_name}{$c};

    # user_to_channels (NOTE: not currently used anywhere)
    $user_to_channels{$c}{$channel_name} = $channel_name;

    # channel_to_users
    $channel_to_users{$channel_name}{$c} = $c;

    # return
    return $was_added;
}

sub has_pair ($class, $c, $channel_name) {
    return exists $channel_to_users{$channel_name}{$c};
}

sub remove_pair ($class, $c, $channel_name) {

    # user_to_channels
    delete $user_to_channels{$c}{$channel_name};
    if (keys($user_to_channels{$c}->%*) == 0) {
        delete $user_to_channels{$c};
    }

    # channel_to_users
    my $was_deleted;
    delete $channel_to_users{$channel_name}{$c};
    if (keys($channel_to_users{$channel_name}->%*) == 0) {
        $was_deleted = 1;
        delete $channel_to_users{$channel_name};
    }
}

sub remove_user ($class, $c) {
    my $hashref = $user_to_channels{$c} // {};
    my @channels = keys %$hashref;
    my @deleted_channels;
    foreach my $channel (@channels) {
        delete $channel_to_users{$channel}{$c};
        if (!(keys $channel_to_users{$channel}->%*)) {
            push @deleted_channels, $channel;
            delete $channel_to_users{$channel};
        }
    }
    delete $user_to_channels{$c};
}

sub query ($class, $thing) {
    if ($thing->$_isa('Mojolicious::Controller')) {
        return [values $user_to_channels{$thing}->%*];
    } elsif (! ref $thing) {
        return [values $channel_to_users{$thing}->%*];
    } else {
        die;
    }
}

sub add_action ($class, $channel, $action_name, $action_sub) {
    $class->set_var($channel, 'action', $action_name, $action_sub);
}

sub get_action ($class, $channel, $action_name) {
    return $class->get_var($channel, 'action', $action_name);
}

sub add_request ($class, $channel, $request_name, $request_sub) {
    $class->set_var($channel, 'request', $request_name, $request_sub);
}

sub get_request ($class, $channel, $request_name) {
    return $class->get_var($channel, 'request', $request_name);
}

sub add_join ($class, $channel, $join_sub) {
    $class->set_var($channel, 'join', $join_sub);
}

sub get_join ($class, $channel) {
    return $class->get_var($channel, 'join');
}

sub add_leave ($class, $channel, $leave_sub) {
    $class->set_var($channel, 'leave', $leave_sub);
}

sub get_leave ($class, $channel) {
    return $class->get_var($channel, 'leave');
}

1;