package AnyEvent::SMTP::Client;

=head1 NAME

AnyEvent::SMTP::Client - Simple asyncronous SMTP Client

=cut

use AnyEvent;
use common::sense;
m{# trying to cheat with cpants game ;)
use strict;
use warnings;
}x;

use base 'Object::Event';

use AnyEvent::Handle;
use AnyEvent::Socket;
use AnyEvent::DNS;
use AnyEvent::Util;

use Sys::Hostname;
use Mail::Address;

use AnyEvent::SMTP::Conn;

our $VERSION = $AnyEvent::SMTP::VERSION;use AnyEvent::SMTP ();

# vvv This code was partly derived from AnyEvent::HTTP vvv
our $MAXCON = 10; # Maximum number of connections to any host
our %MAXCON;      # Maximum number of connections to concrete host
our $ACTIVE = 0;  # Currently active connections
our %ACTIVE;
my %CO_SLOT;      # number of open connections, and wait queue, per host

sub _slot_schedule;
sub _slot_schedule($) {
	my $host = shift;
	my $mc = exists $MAXCON{$host} ? $MAXCON{$host} : $MAXCON;
	while (!$mc or ( $mc > 0 and $CO_SLOT{$host}[0] < $mc )) {
		if (my $cb = shift @{ $CO_SLOT{$host}[1] }) {
			# somebody wants that slot
			++$CO_SLOT{$host}[0];
			++$ACTIVE;
			++$ACTIVE{$host};
			$cb->(AnyEvent::Util::guard {
				--$ACTIVE;
				--$ACTIVE{$host} > 0 or delete $ACTIVE{$host};
				--$CO_SLOT{$host}[0];
				#warn "Release slot (have $ACTIVE) by @{[ (caller)[1,2] ]}\n";
				_slot_schedule $host;
			});
		} else {
			# nobody wants the slot, maybe we can forget about it
			delete $CO_SLOT{$host} unless $CO_SLOT{$host}[0];
			last;
		}
	}
}

# wait for a free slot on host, call callback
sub _get_slot($$) {
	push @{ $CO_SLOT{$_[0]}[1] }, $_[1];
	_slot_schedule $_[0];
}

sub _tcp_connect($$$;$) {
	my ($host,$port,$cb,$pr) = @_;
	#warn "Need slot $host (have $ACTIVE)";
	_get_slot $host, sub {
		my $sg = shift;
		#warn "Have slot $host (have $ACTIVE)";
		tcp_connect($host,$port,sub {
			$cb->(@_,$sg);
		}, $pr);
	}
}
# ^^^ This code was partly derived from AnyEvent::HTTP ^^^



=head1 SYNOPSIS

    use AnyEvent::SMTP::Client 'sendmail';
    
    sendmail
        from => 'mons@cpan.org',
        to   => 'mons@cpan.org', # SMTP host will be detected from addres by MX record
        data => 'Test message '.time().' '.$$,
        cb   => sub {
            if (my $ok = shift) {
                warn "Successfully sent";
            }
            if (my $err = shift) {
                warn "Failed to send: $err";
            }
        }
    ;

=head1 DESCRIPTION

Asyncronously connect to SMTP server, resolve MX, if needed, then send HELO => MAIL => RCPT => DATA => QUIT and return responce

=head1 FUNCTIONS

=head2 sendmail ... , cb => $cb->(OK,ERR)

Argument names are case insensitive. So, it may be calles as

    sendmail From => ..., To => ..., ...

and as

    sendmail from => ..., to => ..., ...

Arguments description are below

=over 4

=item host => 'smtp.server'

SMTP server to use. Optional. By default will be resolved MX record

=item port => 2525

SMTP server port. Optional. By default = 25

=item server => 'some.server:25'

SMTP server. The same as pair of host:port

=item helo => 'hostname'

HELO message. Optional. By default = hostname()

=item from => 'mail@addr.ess'

=item to => 'mail@addr.ess'

=item to => [ 'mail@addr.ess', ... ]

=item data => 'Message body'

=item Message => 'Message body'

Message text. For message composing may be used, for ex: L<MIME::Lite>

=item timeout => int

Use timeout during network operations

=item debug => 0 | 1

Enable connection debugging

=item cb => $cb->(OK,ERR)

Callback.

When $args{to} is a single argument:

    OK - latest response from server
    If OK is undef, then something failed, see ERR
    ERR - error response from server

When $args{to} is an array:

    OK - hash of success responces or undef.
    keys are addresses, values are responces

    ERR - hash of error responces.
    keys are addresses, values are responces

See examples

=item cv => AnyEvent->condvar

If passed, used as group callback operand

    sendmail ... cv => $cv, cb => sub { ...; };

is the same as

    $cv->begin;
    sendmail ... cb => sub { ...; $cv->end };

=back

=head1 VARIABLES

=head2 $MAXCON [ = 10]

Maximum number of connections to any host. Default is 10

=head2 %MAXCON

Per-host configuration for maximum number of connection

Please note, host is hostname passed in argument, or resolved MX record.

So, if passed C<host => 'localhost'>, should be used C<$MAXCON{localhost}>, if passed C<host => '127.0.0.1'>, should be used C<$MAXCON{'127.0.0.1'}>

	# set default limit to 20
	$AnyEvent::SMTP::Client::MAXCON = 20;
	
	# don't limit localhost connections
	$AnyEvent::SMTP::Client::MAXCON{'localhost'} = 0;
	
	# big limit for one of gmail MX
	$AnyEvent::SMTP::Client::MAXCON{'gmail-smtp-in.l.google.com.'} = 100;

=head2 $ACTIVE

Number of currently active connections

=head2 %ACTIVE

Number of currently active connections per host

=cut

sub import {
	my $me = shift;
	my $pkg = caller;
	no strict 'refs';
	@_ or return;
	for (@_) {
		if ( $_ eq 'sendmail') {
			*{$pkg.'::'.$_} = \&$_;
		} else {
			require Carp; Carp::croak "$_ is not exported by $me";
		}
	}
}

sub sendmail(%) {
	my %args = @_;
	my @keys = keys %args;
	@args{map lc, @keys} = delete @args{ @keys };
	$args{data} ||= delete $args{message} || delete $args{body};
	$args{helo} ||= hostname();
	if ($args{server}) {
		my ($h,$p) = $args{server} =~ /^([^:]+)(?:|:(\d+))$/;
		$args{host} = $h or return $args{cb}(undef,"Bad option value for `server'");
		$args{port} = $p if defined $p;
	}
	$args{port} ||= 25;
	$args{timeout} ||= 30;

	my ($run,$cv,$res,$err);
	$args{cv}->begin if $args{cv};
	$cv = AnyEvent->condvar;
	my $end = sub{
		undef $run;
		undef $cv;
		$args{cb}( $res, defined $err ? $err : () );
		$args{cv}->end if $args{cv};
		%args = ();
	};
	$cv->begin($end);
	
	($args{from},my @rcpt) = map { $_->address } map { Mail::Address->parse($_) } $args{from},ref $args{to} ? @{$args{to}} : $args{to};
	
	$run = sub {
		my ($host,$port,@to) = @_;
		warn "connecting to $host:$port\n" if $args{debug};
		my ($exc,$con,$slot_guard);
		my $cb = sub {
			undef $exc;
			$con and $con->close;
			undef $slot_guard;
			undef $con;
			if (@rcpt > 1) {
				#warn "multi cb @to: @_";
				if ($_[0]) {
					@$res{@to} = ($_[0])x@to;
				} else {
					@$err{@to} = ($_[1])x@to;
				}
			} else {
				#warn "single cb @to: @_";
				($res,$err) = @_;
			}
			$cv->end;
		};
		$cv->begin;
		_tcp_connect $host,$port,sub {
			$slot_guard = pop;
			my $fh = shift
				or return $cb->(undef, "$!");
			$con = AnyEvent::SMTP::Conn->new( fh => $fh, debug => $args{debug}, timeout => $args{timeout} );
			$exc = $con->reg_cb(
				disconnect => sub {
					$con or return;
					$cb->(undef,$_[1]);
				},
			);
			$con->line(ok => 220, cb => sub {
				shift or return $cb->(undef, @_);
				$con->command("HELO $args{helo}", ok => 250, cb => sub {
					shift or return $cb->(undef, @_);
					$con->command("MAIL FROM:<$args{from}>", ok => 250, cb => sub {
						shift or return $cb->(undef, @_);

						my $cv1 = AnyEvent->condvar;
						$cv1->begin(sub {
							undef $cv1;
							$con->command("DATA", ok => 354, cb => sub {
								shift or return $cb->(undef, @_);
								$con->reply("$args{data}");
								$con->command(".", ok => 250, cb => sub {
									my $reply = shift or return $cb->(undef, @_);
									$cb->($reply);
								});
							});
						});

						for ( @to ) {
							$cv1->begin;
							$con->command("RCPT TO:<$_>", ok => 250, cb => sub {
								shift or return $cb->(undef, @_);
								$cv1->end;
							});
						}

						$cv1->end;
					});

				});
			});
		}, sub { $args{timeout} || 30 };
		
	};
	
	if ($args{host}) {
		$run->($args{host},$args{port}, @rcpt);
	} else {
		my %domains;
		my $dns = AnyEvent::DNS->new(
			$args{timeout} ? ( timeout => [ $args{timeout} ] ) : ()
		);
		$dns->os_config;
		for (@rcpt) {
			my ($domain) = /^.+\@(.+)$/;
			push @{ $domains{$domain} ||= [] }, $_;
		}
		for my $domain (keys %domains) {
			$cv->begin;
			$dns->resolve( $domain => mx => sub {
				if ($AnyEvent::VERSION > 6.0) {
					@_ = map $_->[5], sort { $a->[4] <=> $b->[4] } @_;
				} else {
					@_ = map $_->[4], sort { $a->[3] <=> $b->[3] } @_;
				}
				warn "MX($domain) = [ @_ ]\n" if $args{debug};
				if (@_) {
					$run->(shift, $args{port}, @{ delete $domains{$domain} });
				} else {
					if (@rcpt > 1) {
						@$err{ @{ $domains{$domain} } } = ( "No MX record for domain $domain" )x@{ $domains{$domain} };
					} else {
						$err = "No MX record for domain $domain";
					}
				}
				$cv->end;
			});
		}
		undef $dns;
	}
	$cv->end;
	defined wantarray
		? AnyEvent::Util::guard { $end->(undef, "Cancelled"); }
		: ();
}

=head1 BUGS

Bug reports are welcome in CPAN's request tracker L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=AnyEvent-SMTP>

=head1 AUTHOR

Mons Anderson, C<< <mons at cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2009 Mons Anderson, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
