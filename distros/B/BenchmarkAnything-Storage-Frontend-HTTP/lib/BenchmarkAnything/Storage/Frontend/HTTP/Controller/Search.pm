package BenchmarkAnything::Storage::Frontend::HTTP::Controller::Search;
our $AUTHORITY = 'cpan:SCHWIGON';
# ABSTRACT: BenchmarkAnything - REST API - data query
$BenchmarkAnything::Storage::Frontend::HTTP::Controller::Search::VERSION = '0.012';
use Mojo::Base 'Mojolicious::Controller';


sub hello
{
        my ($self) = @_;

        $self->render;
}


sub search
{
        my ($self) = @_;

        my $value_id = $self->param('value_id');
        my $query    = $self->req->json;

        if ($value_id) {
                $self->render(json => $self->app->backend->get_single_benchmark_point($value_id));
        }
        elsif ($query)
        {
                $self->render(json => $self->app->backend->search_array($query));
        }
        else
        {
                $self->render(json => []);
        }
}


sub listnames
{
        my ($self) = @_;

        my $pattern = $self->param('pattern');

        my @pattern = $pattern ? ($pattern) : ();
        my $answer = $self->app->backend->list_benchmark_names(@pattern);

        $self->render(json => $answer);
}


sub listkeys
{
        my ($self) = @_;

        my $pattern = $self->param('pattern');

        my @pattern = $pattern ? ($pattern) : ();
        my $answer = $self->app->backend->list_additional_keys(@pattern);

        $self->render(json => $answer);
}


sub stats
{
        my ($self) = @_;

        my $answer = $self->app->backend->get_stats;

        $self->render(json => $answer);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

BenchmarkAnything::Storage::Frontend::HTTP::Controller::Search - BenchmarkAnything - REST API - data query

=head2 hello

Returns a hello answer. Mostly for self and unit testing.

=head2 search

Parameters:

=over 4

=item * value_id (INTEGER)

If a single integer value is provided the complete data point for that
ID is returned.

=item * JSON request body

If a JSON request is provided it is interpreted as query according to
L<BenchmarkAnything::Storage::Backend::SQL::search()|BenchmarkAnything::Storage::Backend::SQL/search>.

=back

=head2 listnames

Returns a list of available benchmark metric NAMEs.

Parameters:

=over 4

=item * pattern (STRING)

If a pattern is provided it restricts the results. The pattern is used
as SQL LIKE pattern, i.e., it allows to use C<%> as wildcards.

=back

=head2 listkeys

Returns a list of additional key names.

Parameters:

=over 4

=item * pattern (STRING)

If a pattern is provided it restricts the results. The pattern is used
as SQL LIKE pattern, i.e., it allows to use C<%> as wildcards.

=back

=head2 stats

Returns a hash with info about the storage, like how many data points,
how many metrics, how many additional keys, are stored.

Parameters: none

=head1 AUTHOR

Steffen Schwigon <ss5@renormalist.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Steffen Schwigon.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
