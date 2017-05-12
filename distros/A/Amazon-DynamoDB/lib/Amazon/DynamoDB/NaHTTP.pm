package Amazon::DynamoDB::NaHTTP;
$Amazon::DynamoDB::NaHTTP::VERSION = '0.35';
use strict;
use warnings;


use Future;
use Net::Async::HTTP 0.30;
use IO::Async::Timer::Countdown;


sub new { 
    my $class = shift; 
    my $self = { @_ };

    defined($self->{loop}) || Carp::confess("An event loop is required");
    bless $self, $class;
}


sub request {
	my $self = shift;
	my $req = shift;
	my ($host, $port) = split /:/, ''.$req->uri->host_port;
        my $resp;
	$self->ua->do_request(
		request => $req,
		host    => $host,
		port    => $port || 80,
                on_response => sub {
                    $resp = shift;
                }
	)-> transform(
		done => sub {
                    if ($resp->is_success()) {
                        return $resp->decoded_content;
                    } else {
                        my $status = join ' ', $resp->code, $resp->message;
                        return Future->new->fail($status, $resp, $req)
                    }
		},
                fail => sub {
                    my $status = join ' ', $resp->code, $resp->message;
                    return ($status, $resp, $req);
                },
	);
}


sub ua {
	my $self = shift;
	unless($self->{ua}) {
		my $ua = Net::Async::HTTP->new(
                    max_connections_per_host => $self->{max_connections_per_host} // 0,
                    user_agent               => $self->{user_agent} // 'PerlAmazonDynamoDB/0.002',
                    pipeline                 => $self->{pipeline} // 0,
                    timeout                  => $self->{timeout} // 90,
                    max_in_flight            => $self->{max_in_flight} // 4,
                    fail_on_error            => 1,
		);
		$self->{loop}->add($ua);
		$self->{ua} = $ua;
	}
	$self->{ua};
}

sub delay {
    my $self = shift;
    my $amount = shift;

    if (!$amount) {
        return Future->new->done();
    }
    
    my $future = $self->{loop}->new_future;

    $self->{loop}->watch_time(after => $amount, 
                              code => sub {
                                  $future->done();
                              });
    return $future;
}

sub loop { 
    shift->{loop}
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Amazon::DynamoDB::NaHTTP

=head1 VERSION

version 0.35

=head1 DESCRIPTION

Provides a L</request> method which will use L<Net::Async::HTTP> to make
requests and return a L<Future> containing the result. Used internally by
L<Amazon::DynamoDB>.

=head2 new

Instantiate.

=head2 request

Issues the request. Expects a single L<HTTP::Request> object,
and returns a L<Future> which will resolve to the decoded
response content on success, or the failure reason on failure.

=head2 ua

Returns a L<Net::Async::HTTP> instance.

=head1 NAME

Amazon::DynamoDB::NaHTTP - make requests using L<Net::Async::HTTP>

=head1 AUTHORS

=over 4

=item *

Rusty Conover <rusty@luckydinosaur.com>

=item *

Tom Molesworth <cpan@entitymodel.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Tom Molesworth, copyright (c) 2014 Lucky Dinosaur LLC. L<http://www.luckydinosaur.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
