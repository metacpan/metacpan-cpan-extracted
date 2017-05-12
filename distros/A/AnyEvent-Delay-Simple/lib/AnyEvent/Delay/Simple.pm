package AnyEvent::Delay::Simple;

use strict;
use warnings;

use AnyEvent ();
use Scalar::Util qw(blessed);

use parent qw(Exporter);


our $VERSION = '0.06';


our @EXPORT    = qw(delay);
our @EXPORT_OK = qw(easy_delay);


sub import {
	my ($class, @args) = @_;

	my (@ae, @up);

	foreach (@args) {
		if ($_ && /^AE::(.+)?/) {
			push(@ae, $1);
		}
		else {
			push(@up, $_);
		}
	}
	if (@ae) {
		$class->export('AE', @ae);
	}
	if (@up) {
		$class->export_to_level(1, undef, @up);
	}
}

sub delay {
	my ($obj, $fin);

	if (blessed($_[0])) {
		$obj = shift();
	}
	$fin = pop();

	return unless $fin;

	my ($subs, $err);

	if (ref($_[0]) eq 'ARRAY') {
		$subs = shift();
		$err  = pop();
	}
	else {
		$err  = pop();
		$subs = \@_;
	}

	my $cv = AE::cv;

	$cv->begin();
	$cv->cb(sub {
		_delay_step($obj, [$fin], undef, [$cv->recv()], $cv);
	});
	_delay_step($obj, $subs, $err, $cv);
	$cv->end();

	return;
}

sub _delay_step {
	my $cv = pop();
	my ($obj, $subs, $err, $args) = @_;

	my $sub = shift(@$subs);

	unless (defined($args)) {
		$args = [];
	}
	unless ($sub) {
		$cv->send(@$args);

		return;
	}

	$cv->begin();
	AE::postpone {
		my @res;
		my $xcv = AE::cv;

		$xcv->begin();
		if ($err) {
			eval {
				$sub->($obj ? $obj : (), @$args, $xcv);
			};
			if ($@) {
				_delay_err($obj, $err, $@, $cv);
				undef($xcv);
			}
			else {
				_delay_step_ex($obj, $subs, $err, $xcv, $cv);
			}
		}
		else {
			$sub->($obj ? $obj : (), @$args, $xcv);
			_delay_step_ex($obj, $subs, $err, $xcv, $cv);
		}
	};

	return;
}

sub _delay_step_ex {
	my ($obj, $subs, $err, $xcv, $cv) = @_;

	my $cb = $xcv->cb();

	$xcv->cb(sub {
		if ($cb) {
			if ($err) {
				eval {
					$cb->();
				};
				if ($@) {
					_delay_err($obj, $err, $@, $cv);

					return;
				}
			}
			else {
				$cb->();
			}
		}
		_delay_step($obj, $subs, $err, [$xcv->recv()], $cv);
		$cv->end();
	});
	$xcv->end();

	return;
}

sub _delay_err {
	my ($obj, $err, $msg, $cv) = @_;

	AE::log error => $msg;

	$cv->cb(sub {
		_delay_step($obj, [$err], undef, [$msg], $cv);
	});
	$cv->end();

	return;
}

sub easy_delay {
	my ($obj, $fin);

	if (blessed($_[0])) {
		$obj = shift();
	}
	$fin = pop();

	return unless $fin;

	my ($subs, $err);

	if (ref($_[0]) eq 'ARRAY') {
		$subs = shift();
		$err  = pop();
	}
	else {
		$err  = pop();
		$subs = \@_;
	}

	my $cv = AE::cv;

	$cv->begin();
	$cv->cb(sub {
		$fin->($obj ? $obj : (), $cv->recv());
	});
	_easy_delay_step($obj, $subs, $err, $cv);
	$cv->end();

	return;
}

sub _easy_delay_step {
	my ($cv) = pop();
	my ($obj, $subs, $err, $args) = @_;

	my $sub = shift(@$subs);

	unless (defined($args)) {
		$args = [];
	}
	unless ($sub) {
		$cv->send(@$args);

		return;
	}

	$cv->begin();
	AE::postpone {
		my @res;

		if ($err) {
			eval {
				@res = $sub->($obj ? $obj : (), @$args);
			};
			if ($@) {
				my $msg = $@;

				AE::log error => $msg;

				$cv->cb(sub {
					$err->($obj ? $obj : (), $msg);
				});
				$cv->send(@$args);
			}
			else {
				_easy_delay_step($obj, $subs, $err, \@res, $cv);
			}
		}
		else {
			@res = $sub->($obj ? $obj : (), @$args);
			_easy_delay_step($obj, $subs, $err, \@res, $cv);
		}
		$cv->end();
	};

	return;
}


1;


__END__

=head1 NAME

AnyEvent::Delay::Simple - Manage callbacks and control the flow of events by AnyEvent

=head1 SYNOPSIS

    use AnyEvent::Delay::Simple;

    my $cv = AE::cv;
    delay(
        sub {
            say('1st step');
            pop->send('1st result');   # send data to 2nd step
        },
        sub {
            say(@_);                   # receive data from 1st step
            say('2nd step');
            die();
        },
        sub {                          # never calls because 2nd step failed
            say('3rd step');
        },
        sub {                          # calls on error, at this time
            say('Fail: ' . $_[1]);
            $cv->send();
        },
        sub {                          # calls on success, not at this time
            say('Ok');
            $cv->send();
        }
    );
    $cv->recv();

=head1 DESCRIPTION

AnyEvent::Delay::Simple manages callbacks and controls the flow of events for
AnyEvent. This module inspired by L<Mojo::IOLoop::Delay>.

=head1 FUNCTIONS

Both functions runs the chain of callbacks, the first callback will run right
away, and the next one once the previous callback finishes. This chain will
continue until there are no more callbacks, or an error occurs in a callback.
If an error occurs in one of the steps, the chain will be break, and error
handler will call, if it's defined. Unless error handler defined, error is
fatal. If last callback finishes and no error occurs, finish handler will call.

You may import these functions into L<AE> namespace instead of current one.
Just prefix function name with C<AE::> when using module.

    use AnyEvent::Delay::Simple qw(AE::delay);
    AE::delay(...);

=head2 delay

    delay(\&cb_1, ..., \&cb_n, \&err, \&fin);
    delay([\&cb_1, ..., \&cb_n], \&fin);
    delay([\&cb_1, ..., \&cb_n], \&err, \&fin);

    delay($obj, \&cb_1, ..., \&cb_n, \&err, \&fin);
    delay($obj, [\&cb_1, ..., \&cb_n], \&fin);
    delay($obj, [\&cb_1, ..., \&cb_n], \&err, \&fin);

If the first argument is blessed reference then all callbacks will be calls as
the methods of this object.

Condvar and data from previous step passed as arguments to each callback or
finish handler. If an error occurs then condvar and error message passed to
the error handler. The data sends to the next step by using condvar's C<send()>
method.

    sub {
        my $cv = pop();
        $cv->send('foo', 'bar');
    },
    sub {
        my $cv   = pop();
        my @args = @_;
        # now @args is ('foo', 'bar')
    },

Condvar can be used to control the flow of events within step.

    sub {
        my $cv = pop();
        $cv->begin();
        $cv->begin();
        my $w1; $w1 = AE::timer 1.0, 0, sub { $cv->end(); undef($w1); };
        my $w2; $w2 = AE::timer 2.0, 0, sub { $cv->end(); undef($w2); };
        $cv->cb(sub { $cv->send('step finished'); });
    }

=head2 easy_delay

    easy_delay(\&cb_1, ..., \&cb_n, \&err, \&fin);
    easy_delay([\&cb_1, ..., \&cb_n], \&fin);
    easy_delay([\&cb_1, ..., \&cb_n], \&err, \&fin);

    easy_delay($obj, \&cb_1, ..., \&cb_n, \&err, \&fin);
    easy_delay($obj, [\&cb_1, ..., \&cb_n], \&fin);
    easy_delay($obj, [\&cb_1, ..., \&cb_n], \&err, \&fin);

This function is similar to the previous function. But its arguments contains
no condvar. And return values of each callbacks in chain passed as arguments to
the next one.

    sub {
        return ('foo', 'bar');
    },
    sub {
        my (@args) = @_;
        # now @args is ('foo', 'bar')
    },

=head1 SEE ALSO

L<AnyEvent>, L<AnyEvent::Delay>, L<Mojo::IOLoop::Delay>.

=head1 SUPPORT

=over 4

=item * Repository

L<http://github.com/AdCampRu/anyevent-delay-simple>

=item * Bug tracker

L<http://github.com/AdCampRu/anyevent-delay-simple/issues>

=back

=head1 AUTHOR

Denis Ibaev C<dionys@cpan.org> for AdCamp.ru.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

See L<http://dev.perl.org/licenses/> for more information.

=cut
