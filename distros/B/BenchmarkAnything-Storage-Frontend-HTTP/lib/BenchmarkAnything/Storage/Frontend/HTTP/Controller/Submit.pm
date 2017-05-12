package BenchmarkAnything::Storage::Frontend::HTTP::Controller::Submit;
our $AUTHORITY = 'cpan:SCHWIGON';
# ABSTRACT: BenchmarkAnything - REST API - data submit
$BenchmarkAnything::Storage::Frontend::HTTP::Controller::Submit::VERSION = '0.011';
use Mojo::Base 'Mojolicious::Controller';


sub add
{
        my ($self) = @_;

        my $data = $self->req->json;

        if ($data)
        {
                if (!$ENV{HARNESS_ACTIVE}) {
                        my $orig = $self->app->balib->{queuemode};
                        $self->app->balib->{queuemode} = 1;
                        $self->app->balib->add($data);
                        $self->app->balib->{queuemode} = $orig;
                } else {
                        $self->app->balib->add($data);
                }
        }
        # how to report error?
        $self->render;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

BenchmarkAnything::Storage::Frontend::HTTP::Controller::Submit - BenchmarkAnything - REST API - data submit

=head2 add

Parameters:

=over 4

=item * JSON request body

If a JSON request is provided it is interpreted as an array of
BenchmarkAnything data points according to
L<BenchmarkAnything::Schema|BenchmarkAnything::Schema>, inclusive the
surrounding hash key C<BenchmarkAnythingData>.

=back

=head1 AUTHOR

Steffen Schwigon <ss5@renormalist.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Steffen Schwigon.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
