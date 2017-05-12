package App::mirai::Future;
$App::mirai::Future::VERSION = '0.003';
use strict;
use warnings;

=head1 NAME

App::mirai::Future - injects debugging code into L<Future>

=head1 VERSION

version 0.003

=head1 DESCRIPTION

On load, this will monkey-patch L<Future> to provide various precarious
hooks for Future-related events.

=cut

use Future;
use Time::HiRes ();
use Scalar::Util ();
use List::UtilsBy ();

use Carp qw(cluck);

use App::mirai::Watcher;

# Elapsed time is important to us, even though we could leave this off and
# track it ourselves
BEGIN { $Future::TIMES = 1 }

our %FUTURE_MAP;
our @WATCHERS;

=head1 create_watcher

Returns a new L<App::mirai::Watcher>.

 my $watcher = App::mirai::Future->create_watcher;
 $watcher->subscribe_to_event(
  create => sub { my ($ev, $f) = @_; warn "Created new future: $f\n" },
 );

=cut

sub create_watcher {
	my $class = shift;
	push @WATCHERS, my $w = App::mirai::Watcher->new;
	$w->subscribe_to_event(@_) if @_;
	$w
}

=head1 delete_watcher

Deletes the given watcher.

 my $watcher = App::mirai::Future->create_watcher;
 App::mirai::Future->delete_watcher($watcher);

=cut

sub delete_watcher {
	my ($class, $w) = @_;
	$w = Scalar::Util::refaddr $w;
	List::UtilsBy::extract_by { Scalar::Util::refaddr($_) eq $w } @WATCHERS;
	()
}

=head2 future

Returns information about the given L<Future> instance.

=cut

sub future { $FUTURE_MAP{$_[1]} }

=head1 futures

Returns all the Futures we know about.

=cut

sub futures {
	grep defined, map $_->{future}, sort values %FUTURE_MAP
}

=head1 MONKEY PATCHES

These reach deep into L<Future> and are likely to break any time a new version
is released.

=cut

{ no warnings 'redefine';

=head2 Future::DESTROY

Hook destruction so we know when a L<Future> is going away.

=cut

sub Future::DESTROY {
	my $f = shift;
	# my $f = $destructor->(@_);
	$_->invoke_event(destroy => $f) for grep defined, @WATCHERS;
	my $entry = delete $FUTURE_MAP{$f};
	$f
}

=head2 Future::set_label

Pick up any label changes, since L<Future>s are created without them.

=cut

sub Future::set_label {
	my $f = shift;
	( $f->{label} ) = @_;
	$_->invoke_event(label => $f) for grep defined, @WATCHERS;
	return $f;
}
}

BEGIN {
	my $prep = sub {
		my $f = shift;

		# Grab the stacktrace first, so we know who started this
		my (undef, $file, $line) = caller(1);
		my $stack = do {
			my @stack;
			my $idx = 1;
			while(my @x = caller($idx++)) {
				unshift @stack, [ @x[0, 1, 2] ];
			}
			\@stack
		};

		# I don't know why this is here.
		if(exists $FUTURE_MAP{$f}) {
			$FUTURE_MAP{$f}{type} = (exists $f->{subs} ? 'dependent' : 'leaf');
			return $f;
		}

		# We don't use this either
		$f->{constructed_at} = do {
			my $at = Carp::shortmess( "constructed" );
			chomp $at; $at =~ s/\.$//;
			$at
		};

		# This is our record, we'll update it when we're marked as ready
		my $entry = {
			future        => $f,
			deps          => [ ],
			type          => (exists $f->{subs} ? 'dependent' : 'leaf'),
			created_at    => "$file:$line",
			creator_stack => $stack,
			status        => 'pending',
		};

		# ... but we don't want to hold on to the real Future and cause cycles,
		# memory isn't free
		Scalar::Util::weaken($entry->{future});

		my $name = "$f";
		$FUTURE_MAP{$name} = $entry;

		# Yes, this means we're modifying the callback list: if we later
		# add support for debugging the callbacks as well, we'd need to
		# take this into account.
		$f->on_ready(sub {
			my $f = shift;
			my (undef, $file, $line) = caller(2);
			$FUTURE_MAP{$f}->{status} = 
				  $f->{failure}
				? "failed"
				: $f->{cancelled}
				? "cancelled"
				: "done";
			$FUTURE_MAP{$f}->{ready_at} = "$file:$line";
			$FUTURE_MAP{$f}->{ready_stack} = do {
				my @stack;
				my $idx = 1;
				while(my @x = caller($idx++)) {
					unshift @stack, [ @x[0,1,2] ];
				}
				\@stack
			};

			# who's in charge of picking names around here? do we not have
			# any interest in consistency?
			$_->invoke_event(on_ready => $f) for grep defined, @WATCHERS;
		});
	};

	my %map = (
		# Creating a leaf Future, or called via _new_dependent
		new => sub {
			my $constructor = shift;
			sub {
				my $f = $constructor->(@_);
				$prep->($f);
				# hahaha
				my ($sub) = (caller 1)[3];
				# no, seriously?
				unless($sub && ($sub eq 'Future::_new_dependent' or $sub eq 'Future::_new_convergent')) {
					$_->invoke_event(create => $f) for grep defined, @WATCHERS;
				}
				$f
			};
		},

		# ->needs_all, ->want_any, etc.
		_new_dependent => sub {
			my $constructor = shift;
			sub {
				my @subs = @{$_[1]};
				my $f = $constructor->(@_);
				$prep->($f);
				my $entry = $FUTURE_MAP{$f};
				$entry->{subs} = \@subs;
				# Inform subs that they have a new parent
				for(@subs) {
					die "missing future map entry for $_?" unless exists $FUTURE_MAP{$_};
					push @{$FUTURE_MAP{$_}{deps}}, $f;
					Scalar::Util::weaken($FUTURE_MAP{$_}{deps}[-1]);
				}
				$_->invoke_event(create => $f) for grep defined, @WATCHERS;
				$f
			};
		},
	);
	# Changed in Future 0.30, I believe
	$map{_new_convergent} = $map{_new_dependent};

	for my $k (keys %map) {
		my $orig = Future->can($k);
		my $code = $map{$k}->($orig);
		{
			no strict 'refs';
			no warnings 'redefine';
			*{'Future::' . $k} = $code;
		}
	}
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@perlsite.co.uk>

=head1 LICENSE

Copyright Tom Molesworth 2014-2015. Licensed under the same terms as Perl itself.
