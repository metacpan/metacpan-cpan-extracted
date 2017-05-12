package BusyBird::Util;
use v5.8.0;
use strict;
use warnings;
use Scalar::Util qw(blessed weaken);
use Carp;
use Exporter 5.57 qw(import);
use BusyBird::DateTime::Format;
use BusyBird::Log qw(bblog);
use BusyBird::SafeData qw(safed);
use DateTime;
use Future::Q 0.040;
use File::HomeDir;
use File::Spec;

our @EXPORT_OK =
    qw(set_param expand_param config_directory config_file_path sort_statuses
       split_with_entities future_of make_tracking vivifiable_as);
our @CARP_NOT = qw(Future::Q);

sub set_param {
    my ($hashref, $params_ref, $key, $default, $is_mandatory) = @_;
    if($is_mandatory && !defined($params_ref->{$key})) {
        my $classname = blessed $hashref;
        croak "ERROR: set_param in $classname: Parameter for '$key' is mandatory, but not supplied.";
    }
    $hashref->{$key} = (defined($params_ref->{$key}) ? $params_ref->{$key} : $default);
}

sub export_ok_all_tags {
    no strict "refs";
    my ($caller_package) = caller;
    my $export_ok = \@{"${caller_package}::EXPORT_OK"};
    my $export_tags = \%{"${caller_package}::EXPORT_TAGS"};
    my @all = @$export_ok;
    foreach my $tag (keys %$export_tags) {
        my $exported = $export_tags->{$tag};
        push(@all, @$exported);
        push(@$export_ok, @$exported);
    }
    $export_tags->{all} = \@all;
}

sub expand_param {
    my ($param, @names) = @_;
    my $refparam = ref($param);
    my @result = ();
    if($refparam eq 'ARRAY') {
        @result = @$param;
    }elsif($refparam eq 'HASH') {
        @result = @{$param}{@names};
    }else {
        $result[0] = $param;
    }
    return wantarray ? @result : $result[0];
}

sub config_directory {
    return File::Spec->catfile(File::HomeDir->my_home, ".busybird");
}

sub config_file_path {
    my (@paths) = @_;
    return File::Spec->catfile(config_directory, @paths);
}

sub vivifiable_as {
    return !defined($_[0]) || ref($_[0]) eq $_[1];
}

sub _epoch_undef {
    my ($datetime_str) = @_;
    my $dt = BusyBird::DateTime::Format->parse_datetime($datetime_str);
    return defined($dt) ? $dt->epoch : undef;
}

sub _sort_compare {
    my ($a, $b) = @_;
    if(defined($a) && defined($b)) {
        return $b <=> $a;
    }elsif(!defined($a) && defined($b)) {
        return -1;
    }elsif(defined($a) && !defined($b)) {
        return 1;
    }else {
        return 0;
    }
}

sub sort_statuses {
    my ($statuses) = @_;
    use sort 'stable';
    
    my @dt_statuses = map {
        my $safe_status = safed($_);
        [
            $_,
            _epoch_undef($safe_status->val("busybird", "acked_at")),
            _epoch_undef($safe_status->val("created_at")),
        ];
    } @$statuses;
    return [ map { $_->[0] } sort {
        foreach my $sort_key (1, 2) {
            my $ret = _sort_compare($a->[$sort_key], $b->[$sort_key]);
            return $ret if $ret != 0;
        }
        return 0;
    } @dt_statuses];
}

sub _create_text_segment {
    return {
        text => substr($_[0], $_[1], $_[2] - $_[1]),
        start => $_[1],
        end => $_[2],
        type => $_[3],
        entity => $_[4],
    };
}

sub split_with_entities {
    my ($text, $entities_hashref) = @_;
    use sort 'stable';
    if(!defined($text)) {
        croak "text must not be undef";
    }
    if(ref($entities_hashref) ne "HASH") {
        return [_create_text_segment($text, 0, length($text))];
    }

    ## create entity segments
    my @entity_segments = ();
    foreach my $entity_type (keys %$entities_hashref) {
        my $entities = $entities_hashref->{$entity_type};
        next if ref($entities) ne "ARRAY";
        foreach my $entity (@$entities) {
            my $se = safed($entity);
            my $start = $se->val("indices", 0);
            my $end = $se->val("indices", 1);
            if(defined($start) && defined($end) && $start <= $end) {
                push(@entity_segments, _create_text_segment(
                    $text, $start, $end, $entity_type, $entity
                ));
            }
        }
    }
    @entity_segments = sort { $a->{start} <=> $b->{start} } @entity_segments;

    ## combine entity_segments with non-entity segments
    my $pos = 0;
    my @final_segments = ();
    foreach my $entity_segment (@entity_segments) {
        if($pos < $entity_segment->{start}) {
            push(@final_segments, _create_text_segment(
                $text, $pos, $entity_segment->{start}
            ));
        }
        push(@final_segments, $entity_segment);
        $pos = $entity_segment->{end};
    }
    if($pos < length($text)) {
        push(@final_segments, _create_text_segment(
            $text, $pos, length($text)
        ));
    }
    return \@final_segments;
}

sub future_of {
    my ($invocant, $method, %args) = @_;
    return Future::Q->try(sub {
        croak "invocant parameter is mandatory" if not defined $invocant;
        croak "method parameter is mandatory" if not defined $method;
        croak "invocant is not blessed" if not blessed $invocant;
        croak "no such method as $method" if not $invocant->can($method);
        my $f = Future::Q->new();
        $invocant->$method(%args, callback => sub {
            my ($error, @results) = @_;
            if($error) {
                $f->reject($error, 1);
            }else {
                $f->fulfill(@results);
            }
        });
        return $f;
    });
}

sub make_tracking {
    my ($tracking_timeline, $main_timeline) = @_;
    if(!blessed($tracking_timeline) || !$tracking_timeline->isa("BusyBird::Timeline")) {
        croak "tracking_timeline must be a BusyBird::Timeline.";
    }
    if(!blessed($main_timeline) || !$main_timeline->isa("BusyBird::Timeline")) {
        croak "main_timeline must be a BusyBird::Timeline.";
    }
    my $name_tracking = $tracking_timeline->name;
    my $name_main = $main_timeline->name;
    if($name_tracking eq $name_main) {
        croak "tracking_timeline and main_timeline must be different timelines.";
    }
    weaken(my $track = $tracking_timeline);
    $tracking_timeline->add_filter_async(sub {
        my ($statuses, $done) = @_;
        if(!defined($track)) {
            $done->($statuses);
            return;
        }
        $track->contains(query => $statuses, callback => sub {
            my ($error, $contained, $not_contained) = @_;
            if(defined($error)) {
                bblog("error", "tracking timeline '$name_tracking' contains() error: $error");
                $done->($statuses);
                return;
            }
            $main_timeline->add($not_contained, sub {
                my ($error, $count) = @_;
                if(defined($error)) {
                    bblog("error", "main timeline '$name_main' add() error: $error");
                }
                $done->($statuses);
            });
        });
    });
    return $tracking_timeline;
}

1;

__END__

=pod

=head1 NAME

BusyBird::Util - utility functions for BusyBird

=head1 SYNOPSIS

    use BusyBird::Util qw(sort_statuses split_with_entities future_of);
    
    future_of($timeline, "get_statuses", count => 100)->then(sub {
        my ($statuses) = @_;
        my $sorted_statuses = sort_statuses($statuses);
        my $status = $sorted_statuses->[0];
        my $segments_arrayref = split_with_entities($status->{text}, $status->{entities});
        return $segments_arrayref;
    })->catch(sub {
        my ($error, $is_normal_error) = @_;
        warn $error;
    });

=head1 DESCRIPTION

This module provides some utility functions useful in L<BusyBird>.

=head1 EXPORTABLE FUNCTIONS

The following functions are exported only by request.

=head2 $sorted = sort_statuses($statuses)

Sorts an array of status objects appropriately. Argument C<$statuses> is an array-ref of statuses.

Return value C<$sorted> is an array-ref of sorted statuses.

The sort refers to C<< $status->{created_at} >> and C<< $status->{busybird}{acked_at} >> fields.
See L<BusyBird::StatusStorage/Order_of_Statuses> section.

=head2 $segments_arrayref = split_with_entities($text, $entities_hashref)

Splits the given C<$text> with the "entities" and returns the split segments.

C<$text> is a string to be split. C<$entities_hashref> is a hash-ref which has the same stucture as
L<Twitter Entities|https://dev.twitter.com/docs/platform-objects/entities>.
Each entity object annotates a part of C<$text> with such information as linked URLs, mentioned users,
mentioned hashtags, etc.
If C<$entities_hashref> doesn't conform to the said structure, it is ignored.

The return value C<$segments_arrayref> is an array-ref of "segment" objects.
A "segment" is a hash-ref containing a part of C<$text> and the entity object (if any) attached to it.
Note that C<$segments_arrayref> has segments that no entity is attached to.
C<$segments_arrayref> is sorted, so you can assemble the complete C<$text> by concatenating all the segments.

Example:

    my $text = 'aaa --- bb ---- ccaa -- ccccc';
    my $entities = {
        a => [
            {indices => [0, 3],   url => 'http://hoge.com/a/1'},
            {indices => [18, 20], url => 'http://hoge.com/a/2'},
        ],
        b => [
            {indices => [8, 10], style => "bold"},
        ],
        c => [
            {indices => [16, 18], footnote => 'first c'},
            {indices => [24, 29], some => {complex => 'structure'}},
        ],
        d => []
    };
    my $segments = split_with_entities($text, $entities);
    
    ## $segments = [
    ##     { text => 'aaa', start => 0, end => 3, type => 'a',
    ##       entity => {indices => [0, 3], url => 'http://hoge.com/a/1'} },
    ##     { text => ' --- ', start => 3, end => 8, type => undef,
    ##       entity => undef},
    ##     { text => 'bb', start => 8, end => 10, type => 'b',
    ##       entity => {indices => [8, 10], style => "bold"} },
    ##     { text => ' ---- ', start => 10, end =>  16, type => undef,
    ##       entity => undef },
    ##     { text => 'cc', start => 16, end => 18, type => 'c',
    ##       entity => {indices => [16, 18], footnote => 'first c'} },
    ##     { text => 'aa', start => 18, end => 20, type => 'a',
    ##       entity => {indices => [18, 20], url => 'http://hoge.com/a/2'} },
    ##     { text => ' -- ', start => 20, end => 24, type => undef,
    ##       entity => undef },
    ##     { text => 'ccccc', start => 24, end => 29, type => 'c',
    ##       entity => {indices => [24, 29], some => {complex => 'structure'}} }
    ## ];

Any entity object is required to have C<indices> field, which is an array-ref
of starting and ending indices of the text part.
The ending index must be greater than or equal to the starting index.
If an entitiy object does not meet this condition, that entity object is ignored.

Except for C<indices>, all fields in entity objects are optional.

Text ranges annotated by entity objects must not overlap. In that case, the result is undefined.

A segment hash-ref has the following fields.

=over

=item C<text>

Substring of the C<$text>.

=item C<start>

Starting index of the segment in C<$text>.

=item C<end>

Ending index of the segment in C<$text>.

=item C<type>

Type of the entity. If the segment has no entity attached, it is C<undef>.

=item C<entity>

Attached entity object. If the segment has no entity attached, it is C<undef>.

=back

It croaks if C<$text> is C<undef>.


=head2 $future = future_of($invocant, $method, %args)

Wraps a callback-style method call with a L<Future::Q> object.

This function executes C<< $invocant->$method(%args) >>, which is supposed to be a callback-style method.
Before the execution, C<callback> field in C<%args> is overwritten, so that the result of the C<$method> can be
obtained from C<$future>.

To use C<future_of()>, the C<$method> must conform to the following specification.
(Most of L<BusyBird::Timeline>'s callback-style methods follow this specification)

=over

=item *

The C<$method> takes named arguments as in C<< $invocant->$method(key1 => value1, key2 => value2 ... ) >>.

=item *

When the C<$method>'s operation is done, the subroutine reference stored in C<$args{callback}> must be called exactly once.

=item *

C<$args{callback}> must be called as in

    $args{callback}->($error, @results)

=item *

In success, the C<$error> must be a falsy scalar and the rest of the arguments is the result of the operation.
The arguments other than C<$error> are used to fulfill the C<$future>.

=item *

In failure, the C<$error> must be a truthy scalar that describes the error.
The C<$error> is used to reject the C<$future>.

=back

The return value (C<$future>) is a L<Future::Q> object, which represents the result of the C<$method> call.
If C<$method> throws an exception, it is caught by C<future_of()> and C<$future> becomes rejected.

In success, C<$future> is fulfilled with the results the C<$method> returns.

    $future->then(sub {
        my @results = @_;
        ...
    });

In failure, C<$future> is rejected with the error and a flag.

    $future->catch(sub {
        my ($error, $is_normal_error) = @_;
        ...
    });

If C<$error> is the error passed to the callback, C<$is_normal_error> is true.
If C<$error> is the exception the method throws, C<$is_normal_error> does not even exist.

=head2 $tracking_timeline = make_tracking($tracking_timeline, $main_timeline)

Makes C<$tracking_timeline> a tracking timeline for a certain source of statuses,
which is then input to C<$main_timeline>.
C<$tracking_timeline> and C<$main_timeline> must be L<BusyBird::Timeline> objects.

Return value is the given C<$tracking_timeline> object.

This method uses L<BusyBird::Log> to log error messages when something goes wrong.

A "tracking timeline" is a timeline dedicated to tracking status history of a single source.
You might need it when you import statuses from various sources into a single "main" timeline.

For example,

    use BusyBird;
    use BusyBird::Input::Feed;
    
    my $input = BusyBird::Input::Feed->new();
    my $main_timeline = timeline("main");
    $main_timeline->add( $input->parse_url('http://example1.com/feed.rss') );
    $main_timeline->add( $input->parse_url('http://example2.com/feed.rss') );
    $main_timeline->add( $input->parse_url('http://example3.com/feed.rss') );

In the above example, statuses are imported from three different RSS feeds using L<BusyBird::Input::Feed>.
Because L<BusyBird::Timeline> rejects duplicate statuses,
the above code adds only new and unread statuses to C<$main_timeline>.

However, if update rates of the three feeds are different,
it's possible for old statuses to re-appear in C<$main_timeline> as new statuses.
This is because L<BusyBird::Timeline> has limited capacity for storing statuses.

Suppose the example1 and example2 update quickly whereas example3's update rate is very slow.
At first, C<$main_timeline> keeps all statuses from the three feeds.
After a while, the C<$main_timeline> will be filled with statuses from example1 and example2,
and at a certain point, statuses from example3 will be discarded because they are too old.
After that, C<< $main_timeline->add( $input->parse_url('http://example3.com/feed.rss') ) >> imports the
same statuses just discarded, but C<$main_timeline> now recognizes them as new
because they are no longer in C<$main_timeline>.
So those old statuses from example3 will re-appear as unread.

To prevent that tragedy, you should create tracking timelines.

    use BusyBird;
    use BusyBird::Input::Feed;
    use BusyBird::Util qw(make_tracking);
    
    my $input = BusyBird::Input::Feed->new();
    my $main_timeline = timeline("main");
    make_tracking(timeline("example1"), $main_timeline);
    make_tracking(timeline("example2"), $main_timeline);
    make_tracking(timeline("example3"), $main_timeline);
    
    timeline("example1")->add( $input->parse_url('http://example1.com/feed.rss') );
    timeline("example2")->add( $input->parse_url('http://example2.com/feed.rss') );
    timeline("example3")->add( $input->parse_url('http://example3.com/feed.rss') );

You should add statuses into tracking timelines instead of directly into C<$main_timeline>.
Each tracking timeline keeps statuses from its source,
and it forwards only new statuses to the C<$main_timeline>.

=head1 AUTHOR

Toshio Ito C<< <toshioito [at] cpan.org> >>

=cut
