package BoardStreams::Registry;

use Mojo::Base -base, -signatures;

use BoardStreams::Util 'belongs_to';
use BoardStreams::REs;

use List::AllUtils 'pairs';
use Hash::Util 'fieldhash';
use Carp 'croak';

no autovivification;

our $VERSION = "v0.0.34";

has _streams_to_conns => sub { +{} };                # ends in connection object
has _conns_to_streams => sub { +{} };                # ends in number of joins of that connection
has _conns => sub { +{} };                           # $int_c -> $c
has conn_subscriptions => sub { fieldhash my %foo }; # stuff to unsubscribe from on leave/finish
has pending_joins => sub { fieldhash my %foo };      # $c -> behavior subject ($num)

has _actions_requests => sub { +{} }; # actions and requests

sub register_conn ($self, $c) {
    $self->_conns->{int $c} = $c;
}

sub unregister_conn ($self, $c) {
    delete $self->_conns->{int $c};
}

sub is_conn_registered ($self, $c) {
    return exists $self->_conns->{int $c};
}

sub add_membership ($self, $c, $stream_name) {
    my $int_c = int $c;
    $self->_streams_to_conns->{$stream_name}{$int_c} //= $c;
    $self->_conns_to_streams->{$int_c}{$stream_name}++;

    return $self->_conns_to_streams->{$int_c}{$stream_name} == 1;
}

sub remove_membership ($self, $c, $stream_name) {
    my $int_c = int $c;
    my $count_ref = \($self->_conns_to_streams->{$int_c}{$stream_name});

    die "not a member of '$stream_name'\n"
        unless defined $$count_ref and $$count_ref > 0;

    if (--$$count_ref == 0) {
        delete $self->_streams_to_conns->{$stream_name}{$int_c};
        delete $self->_streams_to_conns->{$stream_name} if ! $self->_streams_to_conns->{$stream_name}->%*;
        delete $self->_conns_to_streams->{$int_c}{$stream_name};
        delete $self->_conns_to_streams->{$int_c} if ! $self->_conns_to_streams->{$int_c}->%*;
        return 1;
    }

    return 0;
}

sub is_member_of ($self, $c, $stream_name) {
    return exists $self->_streams_to_conns->{$stream_name}{int $c};
}

sub get_conns_of_stream ($self, $stream_name) {
    return [
        values $self->_streams_to_conns->{$stream_name}->%*
    ];
}

sub get_streams_and_counts_of_conn ($self, $c) {
    return $self->_conns_to_streams->{int $c};
}

sub get_all_conns ($self) {
    return [
        values $self->_conns->%*
    ];
}

sub inc_pending_joins_by ($self, $c, $n) {
    my $pj_o = $self->pending_joins->{$c};
    my $pj_value = $pj_o->get_value;
    $pj_o->next($pj_value + $n);
}

### ACTIONS AND REQUESTS

sub set_action_request ($self, $type, $stream_def, $thing_name, $sub) {
    # validate
    belongs_to($type, [qw/ action request join_leave /])
        or die "invalid type '$type'";

    # pre-process
    $stream_def = [$stream_def] if ref $stream_def ne 'ARRAY';
    @$stream_def = map {
        my $thing = $_;
        if (! length ref $thing) {
            $thing =~ $BoardStreams::REs::ANY_STREAM_NAME or croak 'invalid stream definition';
            split /\:/, $thing;
        } else {
            $thing;
        }
    } @$stream_def;

    my $start = $self->_actions_requests;
    my $cursor_ref = \$start;
    SEGMENT:
    foreach my $segment (@$stream_def) {
        if (! length ref $segment) {
            $cursor_ref = \($$cursor_ref->{strings}{$segment} //= {});
        } else {
            foreach my $pair (pairs $$cursor_ref->{regexes}->@*) {
                my ($preexisting_regex, $hashref) = @$pair;
                if ("$segment" eq "$preexisting_regex") {
                    $cursor_ref = \$hashref;
                    next SEGMENT;
                }
            }
            push $$cursor_ref->{regexes}->@*, ($segment => {});
            $cursor_ref = \$$cursor_ref->{regexes}[-1];
        }
    }
    $$cursor_ref->{$type}{$thing_name} = $sub;
}

sub get_action_request ($self, $type, $stream_name, $thing_name) {
    # validate
    belongs_to($type, [qw/ action request join_leave /])
        or die "invalid type '$type'";

    my @segments = split /\:/, $stream_name;
    my @cursors = $self->_actions_requests;
    foreach my $segment (@segments) {
        my @new_cursors = grep defined, map $_->{strings}{$segment}, @cursors;
        foreach my $cursor (@cursors) {
            if ($cursor->{regexes}) {
                foreach my $pair (pairs $cursor->{regexes}->@*) {
                    my ($regex, $new_candidate_cursor) = @$pair;
                    if ($segment =~ $regex) {
                        push @new_cursors, $new_candidate_cursor;
                    }
                }
            }
        }
        @cursors = @new_cursors;
    }
    return (grep defined, map $_->{$type}{$thing_name}, @cursors)[0];
}

sub get_action ($self, $stream_name, $action_name) {
    return $self->get_action_request(action => $stream_name, $action_name);
}

sub get_request ($self, $stream_name, $request_name) {
    return $self->get_action_request(request => $stream_name, $request_name);
}

sub get_join ($self, $stream_name) {
    return $self->get_action_request(join_leave => $stream_name, 'join');
}

sub get_leave ($self, $stream_name) {
    return $self->get_action_request(join_leave => $stream_name, 'leave');
}

sub get_repair ($self, $stream_name) {
    return $self->get_action_request(join_leave => $stream_name, 'repair');
}

1;
