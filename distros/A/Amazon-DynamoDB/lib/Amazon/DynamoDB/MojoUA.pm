package Amazon::DynamoDB::MojoUA;
$Amazon::DynamoDB::MojoUA::VERSION = '0.35';
use strict;
use warnings;


use Future;
use Mojo::UserAgent;


sub new { my $class = shift; bless {@_}, $class }


sub request {
	my $self = shift;
	my $req = shift;
	my $method = lc $req->method;
	my $tx = $self->ua->$method(''.$req->uri => { map {; $_ => ''.$req->header($_) } $req->header_field_names } => $req->content);
	if(my $res = $tx->success) {
		return Future->new->done($res->body)
	}

	my $status = $tx->res->code;
	return Future->new->fail($status, $tx->res, $req)
}


sub ua { shift->{ua} ||= Mojo::UserAgent->new }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Amazon::DynamoDB::MojoUA

=head1 VERSION

version 0.35

=head1 DESCRIPTION

Provides a L</request> method which will use L<LWP::UserAgent> to make
requests and return a L<Future> containing the result. Used internally by
L<Amazon::DynamoDB>.

=head2 new

Instantiate.

=head2 request

Issues the request. Expects a single L<HTTP::Request> object,
and returns a L<Future> which will resolve to the decoded
response content on success, or the failure reason on failure.

=head2 ua

Returns the L<LWP::UserAgent> instance.

=head1 NAME

Amazon::DynamoDB::MojoUA - make requests using L<Mojo::UserAgent>

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
