package Async::Selector;

use 5.006;
use strict;
use warnings;

use Carp;
use Async::Selector::Watcher;


=pod

=head1 NAME

Async::Selector - level-triggered resource observer like select(2)


=head1 VERSION

1.03

=cut

our $VERSION = "1.03";


=pod

=head1 SYNOPSIS


    use Async::Selector;
    
    my $selector = Async::Selector->new();
    
    ## Register resource
    my $resource = "some text.";  ## 10 bytes
    
    $selector->register(resource_A => sub {
        ## If length of $resource is more than or equal to $threshold bytes, provide it.
        my $threshold = shift;
        return length($resource) >= $threshold ? $resource : undef;
    });
    
    
    ## Watch the resource with a callback.
    $selector->watch(
        resource_A => 20,  ## When the resource gets more than or equal to 20 bytes...
        sub {              ## ... execute this callback.
            my ($watcher, %resource) = @_;
            print "$resource{resource_A}\n";
            $watcher->cancel();
        }
    );
    
    
    ## Append data to the resource
    $resource .= "data";  ## 14 bytes
    $selector->trigger('resource_A'); ## Nothing happens
    
    $resource .= "more data";  ## 23 bytes
    $selector->trigger('resource_A'); ## The callback prints 'some text.datamore data'


=head1 DESCRIPTION

L<Async::Selector> is an object that watches registered resources
and executes callbacks when some of the resources are available.
Thus it is an implementation of the Observer pattern like L<Event::Notify>,
but the important difference is that L<Async::Selector> is B<level-triggered> like C<select(2)> system call.

Basic usage of L<Async::Selector> is as follows:

=over

=item 1.

Register as many resources as you like by C<register()> method.

A resource has its name and resource provider.
A resource provier is a subroutine reference that returns some data (or C<undef> if it's not available).


=item 2.

Watch as many resources as you like by C<watch()> method.

When any of the watched resources gets available, a callback function is executed
with the available resource data.

Note that if some of the watched resources is already available when calling C<watch()> method,
it executes the callback function immediately.
That's because L<Async::Selector> is level-triggered.


=item 3.

Notify the L<Async::Selector> object by C<trigger()> method that some of the registered resources have changed.

The L<Async::Selector> object then checks if any of the triggered resources gets available.
If some resources become available, the callback function given by C<watch()> method is executed.


=back


=head1 CLASS METHODS


=head2 $selector = Async::Selector->new();

Creates an L<Async::Selector> object. It takes no parameters.


=cut


sub new {
   my ($class) = @_;
   my $self = bless {
       resources => {},
       watchers => {},
   }, $class;
   return $self;
}

sub _check {
   my ($self, $watcher_id_or_watcher, @triggers) = @_;
   my %results = ();
   my $fired = 0;
   my $watcher_entry = $self->{watchers}{"$watcher_id_or_watcher"};
   return 0 if not defined($watcher_entry);
   my $watcher = $watcher_entry->{object};
   my %conditions = $watcher->conditions;
   if($watcher->get_check_all) {
       @triggers = $watcher->resources;
   }
   foreach my $res_key (@triggers) {
       next if not defined $res_key;
       next if not exists($conditions{$res_key});
       next if not defined($self->{resources}{$res_key});
       my $input = $conditions{$res_key};
       my $result = $self->{resources}{$res_key}->($input);
       if(defined($result)) {
           $fired = 1;
           $results{$res_key} = $result;
       }
   }
   return 0 if !$fired;
   $watcher_entry->{callback}->($watcher, %results);
   return 1;
}

=pod

=head1 OBJECT METHODS

=head2 $selector->register($name => $provider->($condition_input), ...);

Registers resources with the object.
A resource is described as a pair of resource name and resource provider.
You can register as many resources as you like.

The resource name (C<$name>) is an arbitrary string.
It is used to select the resource in C<watch()> method.
If C<$name> is already registered with C<$selector>,
the resource provider is updated with C<$provider> and the old one is discarded.

The resource provider (C<$provider>) is a subroutine reference.
Its return value is supposed to be a scalar data of the resource if it's available,
or C<undef> if it's NOT available.

C<$provider> subroutine takes a scalar argument (C<$condition_input>),
which is given by the user in arguments of C<watch()> method.
C<$provider> can decide whether to provide the resource according to C<$condition_input>.

C<register()> method returns C<$selector> object itself.


=cut


sub register {
   my ($self, %providers) = @_;
   my @error_keys = ();
   while(my ($key, $provider) = each(%providers)) {
       if(!_isa_coderef($provider)) {
           push(@error_keys, $key);
       }
   }
   if(@error_keys) {
       croak("Providers must be coderef for keys: " . join(",", @error_keys));
       return;
   }
   @{$self->{resources}}{keys %providers} = values %providers;
   return $self;
}

=pod

=head2 $selector->unregister($name, ...);

Unregister resources from C<$selector> object.

C<$name> is the name of the resource you want to unregister.
You can unregister as many resources as you like.

C<unregister()> returns C<$selector> object itself.

=cut

sub unregister {
    my ($self, @names) = @_;
    delete @{$self->{resources}}{grep { defined($_) } @names};
    return $self;
}


=pod

=head2 $watcher = $selector->watch($name => $condition_input, ..., $callback->($watcher, %resources));

Starts to watch resources.
A watch is described as pairs of resource names and condition inputs for the resources.

C<$name> is the resource name that you want to watch. It is the name given in C<register()> method.

C<$condition_input> describes the condition the resource has to meet to be considered as "available".
C<$condition_input> is an arbitrary scalar, and its interpretation is up to the resource provider.

You can list as many C<< $name => condition_input >> pairs as you like.

C<$callback> is a subroutine reference that is executed when any of the watched resources gets available.
Its first argument C<$watcher> is an object of L<Async::Selector::Watcher> which represents the watch you just made by C<watch()> method.
This object is the same instance as the return value of C<watch()> method.
The other argument (C<%resources>) is a hash whose keys are the available resource names and values are the corresponding resource data.
Note that C<$callback> is executed before C<watch()> method returns
if some of the watched resources is already available.

The return value of C<$callback> is just ignored by L<Async::Selector>.

C<watch()> method returns an object of L<Async::Selector::Watcher> (C<$watcher>) which represents the watch you just made by C<watch()> method.
C<$watcher> gives you various information such as the list of watched resources and whether the watcher is active or not.
See L<Async::Selector::Watcher> for detail.

The watcher created by C<watch()> method is persistent in nature, i.e., it remains in the L<Async::Selector> object
and C<$callback> can be executed repeatedly. To cancel the watcher and release the C<$callback>,
call C<< $watcher->cancel() >> method.

If no resource selection (C<< $name => $condition_input >> pair) is specified,
C<watch()> method silently ignores it.
As a result, it returns a C<$watcher> object which is already canceled and inactive.


=head2 $watcher = $selector->watch_lt(...);

C<watch_lt()> method is an alias for C<watch()> method.


=head2 $watcher = $selector->watch_et(...);

This method is just like C<watch()> method but it emulates edge-triggered watch.

To emulate edge-triggered behavior, C<watch_et()> won't execute
the C<$callback> immediately even if some of the watched resources are available.
The C<$callback> is executed only when C<trigger()> method is called on
resources that are watched and available.


=cut

sub _isa_coderef {
    my ($coderef) = @_;
    return (defined($coderef) && defined(ref($coderef)) && ref($coderef) eq "CODE");
}

sub watch_et {
    my $self = shift;
    my (%conditions, $cb);
    $cb = pop;
    if(!_isa_coderef($cb)) {
        croak "the watch callback must be a coderef.";
    }
    %conditions = @_;
    if(!%conditions) {
        return Async::Selector::Watcher->new(
            undef, \%conditions
        );
    }
    my $watcher = Async::Selector::Watcher->new(
        $self, \%conditions
    );
    $self->{watchers}{"$watcher"} = {
        object => $watcher,
        callback => $cb
    };
    return $watcher;
}

sub watch_lt {
    my ($self, @args) = @_;
    my $watcher;
    $watcher = $self->watch_et(@args);
    return $watcher if !$watcher->active;
    $self->_check($watcher, $watcher->resources);
    return $watcher;
}

*watch = \&watch_lt;

sub _wrapSelect {
    my ($self, $method, $cb, %conditions) = @_;
    if(!_isa_coderef($cb)) {
        croak "the select callback must be a coderef.";
    }
    my $wrapped_cb = sub {
        my ($w, %res) = @_;
        foreach my $selected_resource ($w->resources) {
            $res{$selected_resource} = undef if not exists($res{$selected_resource});
        }
        if($cb->("$w", %res)) {
            $w->cancel();
        }
    };
    my $watcher = $self->$method(%conditions, $wrapped_cb);
    $watcher->set_check_all(1);
    return $watcher->active ? "$watcher" : undef;
}

sub select_et {
    my ($self, @args) = @_;
    return $self->_wrapSelect('watch_et', @args);
}

sub select_lt {
    my ($self, @args) = @_;
    return $self->_wrapSelect('watch_lt', @args);
}

*select = \&select_lt;

sub cancel {
    my ($self, @watchers) = @_;
    foreach my $w (grep { defined($_) } @watchers) {
        next if not exists $self->{watchers}{"$w"};
        $self->{watchers}{"$w"}{object}->detach();
        delete $self->{watchers}{"$w"};
    }
    return $self;
}

=pod

=head2 $selector->trigger($name, ...);

Notify C<$selector> that the resources specified by C<$name>s may be changed.

C<$name> is the name of the resource that might have been changed.
You can specify as many C<$name>s as you like.

Note that you may call C<trigger()> on resources that are not actually changed.
It is up to the resource provider to decide whether to provide the resource to watchers.

C<trigger()> method returns C<$selector> object itself.

=cut

sub trigger {
   my ($self, @resources) = @_;
   if(!@resources) {
       return $self;
   }
   foreach my $watcher ($self->watchers(@resources)) {
       $self->_check($watcher, @resources);
   }
   return $self;
}

=pod

=head2 @resouce_names = $selector->resources();

Returns the list of registered resource names.

=cut

sub resources {
    my ($self) = @_;
    return keys %{$self->{resources}};
}

=pod

=head2 $is_registered = $selector->registered($resource_name);

Returns true if C<$resource_name> is registered with the L<Async::Selector> object.
Returns false otherwise.

=cut

sub registered {
    my ($self, $resource_name) = @_;
    return 0 if not defined($resource_name);
    return exists $self->{resources}{$resource_name};
}


=pod


=head2 @watchers = $selector->watchers([@resource_names]);

Returns the list of active watchers (L<Async::Selector::Watcher> objects) from the L<Async::Selector> object.

If C<watchers()> method is called without argument, it returns all of the active watchers.

If C<watchers()> method is called with some arguments (C<@resource_names>),
it returns active watchers that watch ANY resource out of C<@resource_names>.

If you want watchers that watch ALL of C<@resource_names>,
try filtering the result (C<@watchers>) with L<Async::Selector::Watcher>'s C<resources()> method.

=cut

sub watchers {
    my ($self, @resources) = @_;
    my @all_watchers = map { $_->{object} } values %{$self->{watchers}};
    if(!@resources) {
        return @all_watchers;
    }
    my @affected_watchers = ();
  watcher_loop: foreach my $watcher (@all_watchers) {
        my %watch_conditions = $watcher->conditions;
        foreach my $res (@resources) {
            next if !defined($res);
            if(exists($watch_conditions{$res})) {
                push(@affected_watchers, $watcher);
                next watcher_loop;
            }
        }
    }
    return @affected_watchers;
}


sub selections {
    my ($self) = @_;
    return map { "$_" } $self->watchers;
}


=pod

=head1 EXAMPLES

=head2 Level-triggered vs. edge-triggered

Watchers created by C<watch()> and C<watch_lt()> methods are level-triggered.
This means their callbacks can be immediately executed if some of the watched resources
are already available.

Watchers created by C<watch_et()> method are edge-triggered.
This means their callbacks are never executed at the moment C<watch_et()> is called.

Both level-triggered and edge-triggered watcher callbacks are executed
when some of the watched resources are C<trigger()>-ed AND available.


    my $selector = Async::Selector->new();
    my $a = 10;
    $selector->register(a => sub { my $t = shift; return $a >= $t ? $a : undef });

    ## Level-triggered watch
    $selector->watch_lt(a => 5, sub { ## => LT: 10
        my ($watcher, %res) = @_;
        print "LT: $res{a}\n";
    });
    $selector->trigger('a');          ## => LT: 10
    $a = 12;
    $selector->trigger('a');          ## => LT: 12
    $a = 3;
    $selector->trigger('a');          ## Nothing happens because $a == 3 < 5.

    ## Edge-triggered watch
    $selector->watch_et(a => 2, sub { ## Nothing happens because it's edge-triggered
        my ($watcher, %res) = @_;
        print "ET: $res{a}\n";
    });
    $selector->trigger('a');          ## => ET: 3
    $a = 0;
    $selector->trigger('a');          ## Nothing happens.
    $a = 10;
    $selector->trigger('a');          ## => LT: 10
                                      ## => ET: 10



=head2 Multiple resources, multiple watches

You can register multiple resources with a single L<Async::Selector>
object.  You can watch multiple resources with a single call of
C<watch()> method.  If you watch multiple resources, the callback is
executed when any of the watched resources is available.


    my $selector = Async::Selector->new();
    my $a = 5;
    my $b = 6;
    my $c = 7;
    $selector->register(
        a => sub { my $t = shift; return $a >= $t ? $a : undef },
        b => sub { my $t = shift; return $b >= $t ? $b : undef },
        c => sub { my $t = shift; return $c >= $t ? $c : undef },
    );
    $selector->watch(a => 10, sub {
        my ($watcher, %res) = @_;
        print "Select 1: a is $res{a}\n";
        $watcher->cancel();
    });
    $selector->watch(
        a => 12, b => 15, c => 15,
        sub {
            my ($watcher, %res) = @_;
            foreach my $key (sort keys %res) {
                print "Select 2: $key is $res{$key}\n";
            }
            $watcher->cancel();
        }
    );

    ($a, $b, $c) = (11, 14, 14);
    $selector->trigger(qw(a b c));  ## -> Select 1: a is 11
    print "---------\n";
    ($a, $b, $c) = (12, 14, 20);
    $selector->trigger(qw(a b c));  ## -> Select 2: a is 12
                                    ## -> Select 2: c is 20


=head2 One-shot and persistent watches

The watchers are persistent by default, that is, they remain in the
L<Async::Selector> object no matter how many times their callbacks
are executed.

If you want to execute your callback just one time, call C<< $watcher->cancel() >>
in the callback.


    my $selector = Async::Selector->new();
    my $A = "";
    my $B = "";
    $selector->register(
        A => sub { my $in = shift; return length($A) >= $in ? $A : undef },
        B => sub { my $in = shift; return length($B) >= $in ? $B : undef },
    );

    my $watcher_a = $selector->watch(A => 5, sub {
        my ($watcher, %res) = @_;
        print "A: $res{A}\n";
        $watcher->cancel(); ## one-shot callback
    });
    my $watcher_b = $selector->watch(B => 5, sub {
        my ($watcher, %res) = @_;
        print "B: $res{B}\n";
        ## persistent callback
    });

    ## Trigger the resources.
    ## Execution order of watcher callbacks is not guaranteed.
    ($A, $B) = ('aaaaa', 'bbbbb');
    $selector->trigger('A', 'B');   ## -> A: aaaaa
                                    ## -> B: bbbbb
    print "--------\n";
    ## $watcher_a is already canceled.
    ($A, $B) = ('AAAAA', 'BBBBB');
    $selector->trigger('A', 'B');   ## -> B: BBBBB
    print "--------\n";

    $B = "CCCCCCC";
    $selector->trigger('A', 'B');   ## -> B: CCCCCCC
    print "--------\n";

    $watcher_b->cancel();
    $selector->trigger('A', 'B');   ## Nothing happens.

=head2 Watcher aggregator

Sometimes you might want to use multiple L<Async::Selector> objects
and watch their resources simultaneously.
In this case, you can use L<Async::Selector::Aggregator> to aggregate
watchers produced by L<Async::Selector> objects.
See L<Async::Selector::Aggregator> for details.

    my $selector_a = Async::Selector->new();
    my $selector_b = Async::Selector->new();
    my $A = "";
    my $B = "";
    $selector_a->register(resource => sub { my $in = shift; return length($A) >= $in ? $A : undef });
    $selector_b->register(resource => sub { my $in = shift; return length($B) >= $in ? $B : undef });
    
    my $watcher_a = $selector_a->watch(resource => 5, sub {
        my ($watcher, %res) = @_;
        print "A: $res{resource}\n";
    });
    my $watcher_b = $selector_b->watch(resource => 5, sub {
        my ($watcher, %res) = @_;
        print "B: $res{resource}\n";
    });
    
    ## Aggregates the two watchers into $aggregator
    my $aggregator = Async::Selector::Aggregator->new();
    $aggregator->add($watcher_a);
    $aggregator->add($watcher_b);
    
    ## This cancels both $watcher_a and $watcher_b
    $aggregator->cancel();
    
    print("watcher_a: " . ($watcher_a->active ? "active" : "inactive") . "\n"); ## -> watcher_a: inactive
    print("watcher_b: " . ($watcher_b->active ? "active" : "inactive") . "\n"); ## -> watcher_b: inactive



=head2 Real-time Web: Comet (long-polling) and WebSocket

L<Async::Selector> can be used for foundation of so-called real-time
Web.  Resource registered with an L<Async::Selector> object can be
pushed to Web browsers via Comet (long-polling) and/or WebSocket.

See L<Async::Selector::Example::Mojo> for detail.


=head1 COMPATIBILITY

The following methods that existed in L<Async::Selector> v0.02 or older are supported but not recommended
in this version.

=over

=item *

C<select()>

=item *

C<select_lt()>

=item *

C<select_et()>

=item *

C<selections()>

=item *

C<cancel()>

=back

Currently the C<watch> methods are substituted for the C<select> methods.

The differences between C<watch> and C<select> methods are as follows.

=over

=item *

C<watch> methods take the watcher callback from the last argument, while C<select> methods
take it from the first argument.


=item *

C<watch> methods return L<Async::Selector::Watcher> objects, while C<select> methods
return selection IDs, which are strings.

=item *

The callback function for C<watch> receives L<Async::Selector::Watcher> object from the
first argument, while the callback for C<select> receives the selection ID.

=item *

The second argument for the callback function is also different.
For C<watch> methods, it is a hash of resources that are watched, triggered and available.
For C<select> methods, it is a hash of all the watched resources with values
for unavailable resources being C<undef>.

=item *

Return values from the callback function for C<watch> methods are ignored,
while those for C<select> methods are used to automatically cancel the selection.


=item *

C<trigger()> method executes the callback for C<watch> methods when it triggers resources
that are watched and available.
On the other hand, C<trigger()> method executes the callback for C<select> when it triggers
resources that are watched, and some of the watched resources are available.
So if you trigger an unavailable watched resource and don't trigger any available watched resource,
the C<select> callback is executed with available resources even though they are not triggered.



=back


=head1 SEE ALSO

L<Event::Notify>, L<Notification::Center>


=head1 AUTHOR

Toshio Ito, C<< <toshioito at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-async-selector at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Async-Selector>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.



=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Async::Selector


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Async-Selector>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Async-Selector>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Async-Selector>

=item * Search CPAN

L<http://search.cpan.org/dist/Async-Selector/>

=back



=head1 LICENSE AND COPYRIGHT

Copyright 2012-2013 Toshio Ito.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Async::Selector
