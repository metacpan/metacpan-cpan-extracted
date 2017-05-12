package Basset::NotificationCenter;

#Basset::NotificationCenter, copyright and (c) 2004, 2005, 2006 James A Thomason III
#Basset::NotificationCenter is distributed under the terms of the Perl Artistic License.

=pod

=head1 NAME

Basset::NotificationCenter - used to notify other objects of interesting things

=head1 AUTHOR

Jim Thomason, jim@jimandkoka.com

=head1 DESCRIPTION

This concept is stolen lock stock and barrel from Objective-C (Apple's cocoa frameworks, specifically). Basically, the notification
center is a high level object that sits off to the side. Objects can register with it to pay attention to interesting things
that other objects do, and they can then act upon the interesting things.

For example. Let's keep track of all times we see a weasel. First, we'll set up a logger (see Basset::Logger) to write to a log file.

 my $logger = Basset::Logger->new(
 	'handle' => '/tmp/weasels.log'
 );

Now, we register it as an observer

 Basset::NotificationCenter->addObserver(
  	'observer'		=> $logger,
 	'notification'	=> 'weasels',
 	'object'		=> 'all',
 	'method'		=> 'log'
 );

And we're done! Now we've registered our observer that will watch for "weasels" notifications posted by all objects, and when it
seems them, it will call its log method.

So when a notification is posted:

 Basset::NotificationCenter->postNotification(
 	'object'		=> $henhouse,
 	'notification'	=> 'weasels',
 	'args'			=> ["Weasels in the hen house!"]
 );

That will look for all observers registered to watch for 'weasels' notifications (our logger, in this case) and call their methods.
Again, for our example, internally the notification center fires off:

 $logger->log("Weasels in the hen house!");

Which logs the line of data to our /tmp/weasels.log file.

You will B<need> to put a types entry into your conf file for

 notificationcenter=Basset::NotificationCenter

(or whatever center you're using)

=cut

$VERSION = '1.02';

use Scalar::Util qw(weaken isweak);

use Basset::Object;
our @ISA = Basset::Object->pkg_for_type('object');

use strict;
use warnings;

=pod

=head1 ATTRIBUTES

=over

=cut

=pod

=begin btest observers

$test->ok(1, "testing is implied");

=end btest

=cut

# the observers list is handled internally. It keeps track of the registered observers.
__PACKAGE__->add_attr('observers');

=pod

=item observation

This is useful for debugging purposes. Set the notification center as an observer, and the
observation will contain the most recently postend notification.


 Basset::NotificationCenter->addObserver(
  	'observer'		=> Basset::NotificationCenter->new,
 	'notification'	=> "YOUR NOTIFICATION,
 	'object'		=> 'all',
 	'method'		=> 'observation'
 );

=cut

=pod

=begin btest observation

my $center = __PACKAGE__->new();
$test->ok($center, 'got default center');

$test->is($center->addObserver('method' => 'observation', 'observer' => $center, 'notification' => 'foo'), 1, 'Added center-as-observer for foo from all');

$test->is($center->postNotification('notification' => 'foo', 'object' => $center), 1, "Center posted foo notification");
my $note = $center->observation;
$test->is($note->{'object'}, $center, 'Notification object is center');
$test->is($note->{'notification'}, 'foo', 'Notification is foo');

$test->is($center->removeAllObservers(), 1, 'cleaned up and removed observers');

=end btest

=cut

__PACKAGE__->add_attr('observation');

=pod

=item loggers

loggers should be specified in the conf file. Similar spec to the 'types' entry.

 loggers %= error=/tmp/error.log
 loggers %= warnings=/tmp/warnings.log
 loggers %= info=/tmp/info.log

etc. Those conf file entries create loggers watching all objects for error, warnings, and info notifications, and the
log files to which they write.

=cut

=pod

=begin btest loggers

=end btest

=cut

__PACKAGE__->add_default_class_attr('loggers');

=pod

=back

=cut

=pod

=begin btest init

my $o = __PACKAGE__->new();
$test->ok($o, 'got object');
$test->is(ref($o->observers), 'HASH', 'observers is hashref');

=end btest

=cut

sub init {
	return shift->SUPER::init(
		'observers' => {},
		@_
	);
}

=pod

=head1 METHODS

=over

=cut

=pod

=item new

Basset::NotificationCenter is a singleton. Calling the constructor will return the single instance that can exist. All other methods may be
called as either an object or a class method.

=cut

=pod

=begin btest center

$test->is(__PACKAGE__->center, __PACKAGE__->new, 'new returns center singleton');

=end btest

=cut

__PACKAGE__->add_class_attr('center');

=pod

=begin btest new

=end btest

=cut

sub new {
	my $class = shift;
	
	#bail out and do nothing if we can't access the singleton. That means we're trying to
	#notify very very early in the compilation process.
	#We don't generate an error, because we may end up in an infinite loop because error
	#tries to post a notification. Remember - this is -very- early in the compilation process
	#if this breaks.
	return unless $class->can('center');
	
	if (my $center = $class->center) {
		return $center;
	}
	
	$class->center($class->SUPER::new());

	my $loggers = $class->loggers;
	foreach my $note (keys %$loggers) {
		my $log = $loggers->{$note};

		my $l = Basset::Object->factory(
			'type'		=> 'logger',
			'handle'	=> $log
		);

		if (defined $l) {
			$class->center->addObserver(
				'notification'	=> $note,
				'observer'		=> $l,
				'method'		=> 'log'
			);
		}

	}
	
	return $class->center;
};

=pod

=item postNotification

 Basset::NotificationCenter->postNotification(
 	'notification'	=> 'weasels',
 	'object'		=> $henhouse,
 	'args'			=> ["Weasels in the hen house!"]
 );

postNotification (say it with me, now) posts a notification. It expects 2-3 arguments.

 object			- required. The object posting the notification. May be a class.
 notification	- required. A string containing the notification being posted.
 args			- optional. Additional arguments in an arrayref to pass through to any observers.

The observer receives a hashref containing the args passed into postNotification.

=cut

=pod

=begin btest postNotification

package Basset::Test::Testing::Basset::NotificationCenter::postNotification;
our @ISA = qw(Basset::Object);

Basset::Test::Testing::Basset::NotificationCenter::postNotification->add_attr('observation');

package __PACKAGE__;

my $center = Basset::NotificationCenter->new;

my $o = Basset::Test::Testing::Basset::NotificationCenter::postNotification->new();
$test->ok($o, "got object");

$test->is($center->addObserver('method' => 'observation', 'observer' => $o, 'notification' => 'foo'), 1, 'Added observer for foo from all');
$test->is($center->addObserver('method' => 'observation', 'observer' => $o, 'notification' => 'bar', 'object' => $o), 1, 'Added observer for bar from self');

my $args = [qw(a b c)];
$test->ok($args, "Got args");

$test->is($center->postNotification('notification' => 'foo', 'object' => $center, 'args' => $args), 1, "Center posted foo notification");
my $note = $o->observation;
$test->is($note->{'object'}, $center, 'Notification object is center');
$test->is($note->{'notification'}, 'foo', 'Notification is foo');
$test->is($note->{'args'}, $args, 'args are correct');

$test->is(__PACKAGE__->postNotification('notification' => 'foo', 'object' => $center, 'args' => $args), 1, "Center posted foo notification through package");
$note = $o->observation;
$test->is($note->{'object'}, $center, 'Notification object is center');
$test->is($note->{'notification'}, 'foo', 'Notification is foo');
$test->is($note->{'args'}, $args, 'args are correct');

$test->is($center->postNotification('notification' => 'bar', 'object' => $center, 'args' => $args), 1, "Center posted bar notification");
$note = $o->observation;
$test->is($note->{'object'}, $center, 'Notification object is center (object ignores bar from center)');
$test->is($note->{'notification'}, 'foo', 'Notification is foo (object ignores bar from center)');
$test->is($note->{'args'}, $args, 'args are correct (object ignores bar from center)');

$test->is($center->postNotification('notification' => 'bar', 'object' => $o, 'args' => $args), 1, "o posted bar notification");
$note = $o->observation;
$test->is($note->{'object'}, $o, 'Notification object is o');
$test->is($note->{'notification'}, 'bar', 'Notification is bar');
$test->is($note->{'args'}, $args, 'args are correct');

$test->is($center->postNotification('notification' => 'bar', 'object' => $o), 1, "o posted bar notification w/no args");
$note = $o->observation;
$test->is($note->{'object'}, $o, 'Notification object is o');
$test->is($note->{'notification'}, 'bar', 'Notification is bar');
$test->is(scalar(@{$note->{'args'}}), 0, 'args are empty arrayref');

$test->is($center->addObserver('method' => 'observation', 'observer' => $o, 'notification' => 'cam', 'object' => $o), 1, 'Added observer for cam from self');
$test->is($center->postNotification('notification' => 'cam', 'object' => $o), 1, "o posted cam notification w/no args");
$test->is(__PACKAGE__->postNotification('notification' => 'cam', 'object' => $o), 1, "o posted cam notification w/no args via class");

$test->is($center->removeAllObservers(), 1, 'cleaned up and removed observers');

=end btest

=cut

sub postNotification {

	my $self = shift;
	$self = ref $self ? $self : $self->new() or return;

	my %args = @_;

	return $self->error("Cannot post notification w/o object", "BN-07") unless defined $args{'object'};
	return $self->error("Cannot post notification w/o notification", "BN-08") unless defined $args{'notification'};
	
	$args{'args'} ||= [];
	
	my $observers = $self->observers();
	
	my $note = $observers->{$args{'notification'}};
	
	if (my $observableObjects = $observers->{$args{'notification'}}) {
		foreach my $object (keys %$observableObjects) {

			if (defined $object && $object eq $args{'object'} || $object eq 'all') {
				my $observers = $observableObjects->{$object};# || {};
				foreach my $observerKey (keys %$observers) {
					my $data = $observers->{$observerKey};
					my ($observer, $method) = @$data{qw(observer method)};
					$observer->$method(\%args);
				}
			}
		}
	};
	return 1;
}

=pod

=item addObserver

 Basset::NotificationCenter->addObserver(
  	'observer'		=> $logger
 	'notification'	=> 'weasels',
 	'object'		=> 'all',
 	'method'		=> 'log'
 );

addObserver (say it with me, now) adds an observer. It expects 3-4 arguments.

 observer		- required. The object observing the notification. May be a class.
 notification	- required. A string containing the notification to watch for.
 method			- required. The method to call when the notification is observed.
 object			- optional. If specified, then the observer will only watch for notifications posted by that object (or class).
 					otherwise, watches for all notifications of that type.

=cut

=pod

=begin btest addObserver

package Basset::Test::Testing::Basset::NotificationCenter::addObserver;
our @ISA = qw(Basset::Object);

Basset::Test::Testing::Basset::NotificationCenter::addObserver->add_attr('observation');

package __PACKAGE__;

my $o = Basset::Test::Testing::Basset::NotificationCenter::addObserver->new();
$test->ok($o, "got object");

my $center = __PACKAGE__->new();
$test->ok($center, 'got default center');

$test->is(scalar($center->addObserver), undef, 'Could not add observer w/o method');
$test->is($center->errcode, 'BN-01', 'proper error code');
$test->is(scalar(__PACKAGE__->addObserver), undef, 'Could not add observer w/o method through package');
$test->is($center->errcode, 'BN-01', 'proper error code');
$test->is(scalar($center->addObserver('method' => 'observation')), undef, 'Could not add observer w/o observer');
$test->is($center->errcode, 'BN-02', 'proper error code');
$test->is(scalar($center->addObserver('method' => 'observation', 'observer' => $o)), undef, 'Could not add observer w/o notification');
$test->is($center->errcode, 'BN-03', 'proper error code');
$test->is($center->addObserver('method' => 'observation', 'observer' => $o, 'notification' => 'foo'), 1, 'Added observer for foo from all');
$test->is($center->addObserver('method' => 'observation', 'observer' => $o, 'notification' => 'bar', 'object' => $o), 1, 'Added observer for bar from self');

my $args = [qw(a b c)];
$test->ok($args, "Got args");

$test->is($center->postNotification('notification' => 'foo', 'object' => $center, 'args' => $args), 1, "Center posted foo notification");
my $note = $o->observation;
$test->is($note->{'object'}, $center, 'Notification object is center');
$test->is($note->{'notification'}, 'foo', 'Notification is foo');
$test->is($note->{'args'}, $args, 'args are correct');

$test->is($center->postNotification('notification' => 'bar', 'object' => $center, 'args' => $args), 1, "Center posted bar notification");
$note = $o->observation;
$test->is($note->{'object'}, $center, 'Notification object is center (object ignores bar from center)');
$test->is($note->{'notification'}, 'foo', 'Notification is foo (object ignores bar from center)');
$test->is($note->{'args'}, $args, 'args are correct (object ignores bar from center)');

$test->is($center->postNotification('notification' => 'bar', 'object' => $o, 'args' => $args), 1, "o posted bar notification");
$note = $o->observation;
$test->is($note->{'object'}, $o, 'Notification object is o');
$test->is($note->{'notification'}, 'bar', 'Notification is bar');
$test->is($note->{'args'}, $args, 'args are correct');

$test->is($center->postNotification('notification' => 'bar', 'object' => $o), 1, "o posted bar notification w/no args");
$note = $o->observation;
$test->is($note->{'object'}, $o, 'Notification object is o');
$test->is($note->{'notification'}, 'bar', 'Notification is bar');
$test->is(scalar(@{$note->{'args'}}), 0, 'args are empty arrayref');

$test->is($center->removeAllObservers(), 1, 'cleaned up and removed observers');

=end btest

=cut

sub addObserver {
	my $self = shift;
	$self = ref $self ? $self : $self->new() or return;
	
	my %init = @_;
	
	return $self->error("Cannot add observer w/o method", "BN-01") unless defined $init{'method'};
	return $self->error("Cannot add observer w/o observer", "BN-02") unless defined $init{'observer'};
	return $self->error("Cannot add observer w/o notification", "BN-03") unless defined $init{'notification'};
	$init{'object'} ||= 'all';
	
	my $observers = $self->observers();
	
	$observers->{$init{'notification'}}->{$init{'object'}}->{$init{'observer'}} = \%init;
	
	#this is off for now, 'til I think of how to deal with the case of objects that exist
	#only in the notification center, such as loggers
	#
	#we don't want the notification center to keep observer objects around by mistake.
	#weaken($init{'observer'}) if ref $init{'observer'};
	
	return 1;
};

=pod

=item removeObserver

 Basset::NotificationCenter->removeObserver(
  	'observer'		=> $logger
 	'notification'	=> 'weasels',
 );

removeObserver (say it with me, now) removes an observer. It expects 2 arguments.

 observer		- required. The object observing the notification. May be a class.
 notification	- required. A string containing the notification to watch for.

Behave yourself and properly manage your memory. Remove observers when you're no longer using them. This is especially important
in a mod_perl environment.

=cut

=pod

=begin btest removeObserver

package Basset::Test::Testing::Basset::NotificationCenter::removeObserver;
our @ISA = qw(Basset::Object);

Basset::Test::Testing::Basset::NotificationCenter::removeObserver->add_attr('observation');

package __PACKAGE__;

my $o = Basset::Test::Testing::Basset::NotificationCenter::removeObserver->new();
$test->ok($o, "got object");

my $center = __PACKAGE__->new();
$test->ok($center, 'got default center');

$test->is($center->addObserver('method' => 'observation', 'observer' => $o, 'notification' => 'foo'), 1, 'Added observer for foo from all');
$test->is($center->addObserver('method' => 'observation', 'observer' => $o, 'notification' => 'bar', 'object' => $o), 1, 'Added observer for bar from self');

$test->is(scalar($center->removeObserver), undef, 'Could not remove observer w/o observer');
$test->is($center->errcode, 'BN-05', 'proper error code');
$test->is(scalar(__PACKAGE__->removeObserver), undef, 'Could not remove observer w/o observer through package');
$test->is($center->errcode, 'BN-05', 'proper error code');
$test->is(scalar($center->removeObserver('observer' => $o)), undef, 'Could not remove observer w/o notification');
$test->is($center->errcode, 'BN-06', 'proper error code');

$test->is($center->removeObserver('observer' => $o, 'notification' => 'foo'), 1, 'removed foo notification');
$test->is(scalar($o->observation(undef)), undef, 'wiped out any previous notifications');
$test->is($center->postNotification('notification' => 'foo', 'object' => $o), 1, "o posted foo notification");
my $note = $o->observation;
$test->is($note, undef, "No notification received");

$test->is($center->postNotification('notification' => 'bar', 'object' => $o), 1, "o posted bar notification w/no args");
$note = $o->observation;
$test->is($note->{'object'}, $o, 'Notification object is o');
$test->is($note->{'notification'}, 'bar', 'Notification is bar');
$test->is(scalar(@{$note->{'args'}}), 0, 'args are empty arrayref');

$test->is($center->addObserver('method' => 'observation', 'observer' => $o, 'notification' => 'foo'), 1, 'Re-Added observer for foo from all');

$test->is($center->removeObserver('observer' => $o, 'notification' => 'bar'), 1, 'removed bar notification for all');

$test->is(scalar($o->observation(undef)), undef, 'wiped out any previous notifications');

$test->is($center->postNotification('notification' => 'bar', 'object' => $o), 1, "o posted bar notification");
$note = $o->observation;
$test->is($note->{'object'}, $o, 'Notification object is o');
$test->is($note->{'notification'}, 'bar', 'Notification is bar');
$test->is(scalar(@{$note->{'args'}}), 0, 'args are empty arrayref');

$test->is($center->removeObserver('observer' => $o, 'notification' => 'bar', 'object' => $o), 1, 'removed bar notification for $o');

$test->is(scalar($o->observation(undef)), undef, 'wiped out any previous notifications');

$test->is($center->postNotification('notification' => 'bar', 'object' => $o), 1, "o posted bar notification");
$note = $o->observation;

$test->is($note, undef, "No notification received");

$test->is($center->postNotification('notification' => 'foo', 'object' => $center), 1, "Center posted foo notification");
$note = $o->observation;
$test->is($note->{'object'}, $center, 'Notification object is center');
$test->is($note->{'notification'}, 'foo', 'Notification is foo');

$test->is($center->removeAllObservers(), 1, 'cleaned up and removed observers');

=end btest

=cut

sub removeObserver {
	my $self = shift;
	$self = ref $self ? $self : $self->new() or return;
	
	my %init = @_;
	
	return $self->error("Cannot remove observer w/o observer", "BN-05") unless defined $init{'observer'};
	return $self->error("Cannot remove observer w/o notification", "BN-06") unless defined $init{'notification'};
	$init{'object'} ||= 'all';
	
	my $observers = $self->observers();
	
	delete $observers->{$init{'notification'}}->{$init{'object'}}->{$init{'observer'}};
	
	return 1;
	
};
	
=pod

=item removeAllObservers

Sometimes, though, it's easier to just nuke all the existing observers. The end of execution in a mod_perl process, for instance. You don't
need to care what observers are still around or what they're doing. You just want them to go away. So you can remove them all.

 Basset::NotificationCenter->removeAllObservers();

=cut

=pod

=begin btest removeAllObservers

package Basset::Test::Testing::Basset::NotificationCenter::removeAllObservers;
our @ISA = qw(Basset::Object);

Basset::Test::Testing::Basset::NotificationCenter::removeAllObservers->add_attr('observation');

package __PACKAGE__;

my $o = Basset::Test::Testing::Basset::NotificationCenter::removeAllObservers->new();
$test->ok($o, "got object");

my $center = __PACKAGE__->new();
$test->ok($center, 'got default center');

$test->is($center->addObserver('method' => 'observation', 'observer' => $o, 'notification' => 'foo'), 1, 'Added observer for foo from all');
$test->is($center->addObserver('method' => 'observation', 'observer' => $o, 'notification' => 'bar', 'object' => $o), 1, 'Added observer for bar from self');

my $observers = $center->observers;

$test->is(scalar(keys %{$center->observers}), 2, 'two observers');
$test->is($center->removeAllObservers, 1, 'removed all observers');
$test->is(scalar(keys %{$center->observers}), 0, 'no more observers');

$center->observers($observers);

=end btest

=cut

sub removeAllObservers {
	my $self = shift;
	$self = ref $self ? $self : $self->new() or return;
	
	$self->observers({});
	
	return 1;
};

1;

=pod

=back

=cut
