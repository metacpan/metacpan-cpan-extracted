package BusyBird::Main;
use v5.8.0;
use strict;
use warnings;
use BusyBird::Timeline;
use BusyBird::Watcher::Aggregator;
use BusyBird::Log qw(bblog);
use BusyBird::Config;
use Tie::IxHash;
use Carp;
use Try::Tiny;

our @CARP_NOT = qw(BusyBird::Timeline BusyBird::Config);

sub new {
    my ($class) = @_;
    tie(my %timelines, 'Tie::IxHash');
    my $self = bless {
        timelines => \%timelines,
        config => BusyBird::Config->new(type => "global", with_default => 1),
    }, $class;
    return $self;
}

sub timeline {
    my ($self, $name) = @_;
    my $timeline = $self->get_timeline($name);
    if(not defined $timeline) {
        $timeline = $self->create_timeline($name);
        $self->install_timeline($timeline);
    }
    return $timeline;
}

sub create_timeline {
    my ($self, $name) = @_;
    return BusyBird::Timeline->new(name => $name, storage => $self->get_config("default_status_storage"));
}

sub get_timeline {
    my ($self, $name) = @_;
    return $self->{timelines}{$name};
}

sub get_all_timelines {
    my ($self) = @_;
    return values %{$self->{timelines}};
}

sub install_timeline {
    my ($self, $timeline) = @_;
    if($timeline->name eq "") {
        bblog("warn", "Invalid timeline name (it's empty)");
        return;
    }
    if($timeline->name =~ qr{/}) {
        bblog("warn", "Invalid timeline name (it contains /)");
        return;
    }
    $self->{timelines}{$timeline->name} = $timeline;
}

sub uninstall_timeline {
    my ($self, $name) = @_;
    my $timeline = $self->get_timeline($name);
    delete $self->{timelines}{$name};
    return $timeline;
}

sub set_config {
    shift()->{config}->set_config(@_);
}

sub get_config {
    shift()->{config}->get_config(@_);
}

sub get_timeline_config {
    my ($self, $timeline_name, $key) = @_;
    my $timeline = $self->get_timeline($timeline_name);
    my $timeline_config = defined($timeline) ? $timeline->get_config($key) : undef;
    return $timeline_config if defined $timeline_config;
    return $self->get_config($key);
}

sub watch_unacked_counts {
    my ($self, %watch_args) = @_;
    my $level = $watch_args{level};
    $level = 'total' if not defined $level;
    my $assumed = $watch_args{assumed};
    my $callback = $watch_args{callback};
    if(!defined($assumed) || ref($assumed) ne 'HASH') {
        croak 'assumed must be a hash-ref';
    }
    if(!defined($callback) || ref($callback) ne 'CODE') {
        croak "callback must be a code-ref";
    }
    my $watcher = BusyBird::Watcher::Aggregator->new;
    foreach my $tl_name (keys %$assumed) {
        my $timeline = $self->get_timeline($tl_name);
        next if not defined $timeline;
        my $tl_watcher = $timeline->watch_unacked_counts(
            assumed => {$level => $assumed->{$tl_name}},
            callback => sub {
                my ($error, $w, $unacked_counts) = @_;
                if(defined $error) {
                    $watcher->cancel();
                    $callback->("Error from timeline $tl_name: $error", $watcher);
                }else {
                    $callback->(undef, $watcher, { $tl_name => $unacked_counts });
                }
            }
        );
        if(!$tl_watcher->isa('Async::Selector::Aggregator')) {
            confess '$tl_watcher is not a Async::Selector::Aggregator. Something is terribly wrong.';
        }
        $watcher->add($tl_watcher);
        last if !$watcher->active;
    }
    if(!$watcher->watchers) {
        croak "assumed argument does not contain any installed timeline.";
    }
    return $watcher;
}


1;

__END__

=pod

=head1 NAME

BusyBird::Main - main application object of BusyBird

=head1 SYNOPSIS

    use BusyBird::Main;
    
    my $main = BusyBird::Main->new;
    
    my $foo = $main->timeline("foo");
    my $bar = $main->timeline("bar");
    
    my @all_timelines = $main->get_all_timelines;
    $all_timelines[0]->name; ## => "foo"
    $all_timelines[1]->name; ## => "bar"
    
    $main->set_config(time_zone => "UTC");
    $foo->set_config(time_zone => "+0900");
    
    $main->get_timeline_config("foo", "time_zone"); ## => "+0900"
    $main->get_timeline_config("bar", "time_zone"); ## => "UTC"


=head1 DESCRIPTION

L<BusyBird::Main> is the main application object of L<BusyBird>.
It keeps application configuration and timelines (L<BusyBird::Timeline> objects).

L<BusyBird::Main> does not depend on L<PSGI> or any other controller mechanism.
If you want to create L<PSGI> application from L<BusyBird::Main>, check out L<BusyBird::Main::PSGI> class.

This module uses L<BusyBird::Log> for logging.

=head1 CLASS METHODS

=head2 $main = BusyBird::Main->new()

Creates a L<BusyBird::Main> object.

Users usually don't have to call this method.
The singleton instance of L<BusyBird::Main> object is maintained by L<BusyBird> module.
See L<BusyBird> and L<BusyBird::Manual::Tutorial> for detail.

=head1 OBJECT METHODS

=head2 $timeline = $main->timeline($name)

Returns the C<$timeline> whose name is C<$name> from the C<$main>.
C<$timeline> is a L<BusyBird::Timeline> object.
If C<$name> includes Unicode characters, it must be a character string (decoded string), not a binary string (encoded string).

If there is no timeline named C<$name> in C<$main>, a new timeline is created, installed and returned.

In L<BusyBird::Main>, timeline names must not contain a slash "/", because it confuses Web API.
If C<$name> contains a slash, the timeline IS created and returned, but it's NOT installed in the C<$main> object.
In that case, it logs a warning message.

If a new timeline is created by this method, it uses the StatusStorage object
given by C<< $main->get_config("default_status_storage") >> for that timeline.
See L<BusyBird::Manual::Config> for defail.

=head2 $timeline = $main->create_timeline($name)

Creates and returns a C<$timeline> like C<timeline()> method does, but not install it.

This method always creates a new L<BusyBird::Timeline> object.

=head2 $timeline = $main->get_timeline($name)

Returns the C<$timeline> whose name is C<$name> from the C<$main>.

If there is no timeline named C<$name> in C<$main>, it returns C<undef>.


=head2 @timelines = $main->get_all_timelines()

Returns the list of all timelines installed in the C<$main>.

=head2 $main->install_timeline($timeline)

Installs the given C<$timeline> to the C<$main>.

If a timeline with the same name as the given C<$timeline> is already installed in the C<$main>,
the old timeline is replaced by the given C<$timeline>.

You cannot install C<$timeline> whose name contains a slash "/".
In this case, the C<$timeline> is ignored and it logs a warning message.

=head2 $timeline = $main->uninstall_timeline($name)

Uninstalls the timeline whose name is C<$name> from the C<$main>.
It returns the uninstalled C<$timeline>.

If there is no timeline named C<$name>, it returns C<undef>.


=head2 $main->set_config($key1 => $value1, $key2 => $value2, ...)

Sets config parameters to the C<$main>.

C<$key1>, C<$key2>, ... are the keys for the config parameters, and
C<$value1>, C<$value2>, ... are the values for them.

See L<BusyBird::Manual::Config> for the list of config parameters.

=head2 $value = $main->get_config($key)

Returns the value of config parameter whose key is C<$key>.

If there is no config parameter associated with C<$key>, it returns C<undef>.

=head2 $value = $main->get_timeline_config($timeline_name, $key)

Returns the value of config parameter for a timeline.

If config item C<$key> is defined in the timeline specified by C<$timeline_name>, it returns the config value from the timeline.
Otherwise, it returns the config value in the C<$main> object.
If both the timeline and the C<$main> does not have the config value for C<$key>, it returns C<undef>.


=head2 $watcher = $main->watch_unacked_counts(%args)

Watches updates in numbers of unacked statuses (i.e. unacked counts) in timelines.

Fields in C<%args> are as follows.

=over

=item C<level> => {'total', NUMBER} (optional, default: 'total')

Specifies the status level you want to watch.

=item C<assumed> => HASHREF (mandatory)

Specifies the assumed unacked counts in the status C<level> for each timeline.

=item C<callback> => CODEREF($error, $w, $tl_unacked_counts) (mandatory)

Specifies the callback function that is called when the assumed unacked counts
are different from the current unacked counts.

=back

When this method is called, the current unacked counts are compared with the unacked counts given in the arguments (C<level> and C<assumed> arguments).
If the current and assumed unacked counts are different, the C<callback> subroutine reference is called
with the current unacked counts (C<$tl_unacked_counts>).
If the current and assumed unacked counts are the same, the execution of the C<callback> is delayed until there is some difference between them.

C<level> argument is the status level you want to watch.
It is either an integer number or the string of C<'total'>.
If an integer is specified, the unacked counts in that status level are watched.
If C<'total'> is specified, the total unacked counts are watched.

C<assumed> argument is a hash-ref specifying the assumed unacked count for each timeline.
Its key is the name of the timeline you want to watch, and its value
is the assumed unacked counts for the timeline in the status level specified by C<level>.
You can watch multiple timelines by a single call of this method.

In success, the C<callback> function is called with three arguments (C<$error>, C<$w> and C<$tl_unacked_counts>).
C<$error> is C<undef>.
C<$w> is an L<BusyBird::Watcher> object representing the watch.
C<$tl_unacked_counts> is a hash-ref describing the current unacked counts for watched timelines.

In failure, the argument C<$error> is a truthy value describing the error. C<$w> is an inactive L<BusyBird::Watcher>.

For example,

    use Data::Dumper;
    
    my $watcher = $main->watch_unacked_counts(
        level => "total",
        assumed => { TL1 => 0, TL2 => 0, TL3 => 5 },
        callback => sub {
            my ($error, $w, $tl_unacked_counts) = @_;
            $w->cancel();
            print Dumper $tl_unacked_counts;
        }
    );

The C<level> and C<assumed> parameters in the above example mean that
the caller assumes there is no unacked statuses in TL1 and TL2,
and there are 5 unacked statuses in TL3.

C<$tl_unacked_counts> represents the current unacked counts.
It's something like

    $tl_unacked_counts = {
        TL1 => {
            total => 2,
            0     => 1,
            2     => 1,
        },
    };

This means the timeline named C<'TL1'> actually has 2 unacked statuses in total,
one of which is in level 0 and the other is in level 2.

Note that although you can specify multiple timelines in C<assumed>,
the returned C<$tl_unacked_counts> may not contain all the specified timelines.

The return value of this method (C<$watcher>) is the same instance as C<$w>.
You can use C<< $watcher->cancel() >> or C<< $w->cancel() >> method to cancel the watch, like we did in the above example.
Otherwise, the C<callback> is repeatedly called whenever some updates in unacked counts happen and
the current and assumed unacked counts are different.

In C<assumed> argument, the timeline names that are not in C<$main> are ignored.
If there is no existent timeline name in C<assumed>, this method croaks.

Never apply C<future_of()> function from L<BusyBird::Util> to this method.
This is because this method can execute the callback more than once.

=head1 AUTHOR

Toshio Ito C<< <toshioito [at] cpan.org> >>

=cut



