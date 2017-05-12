package DBIx::Class::QueryLog::Analyzer;
$DBIx::Class::QueryLog::Analyzer::VERSION = '1.005001';
# ABSTRACT: Query Analysis

use Moo;
use Types::Standard 'InstanceOf';

has querylog => (
    is => 'rw',
    isa => InstanceOf['DBIx::Class::QueryLog']
);


sub get_sorted_queries {
    my ($self) = @_;

    my @queries;

    foreach my $l (@{ $self->querylog->log }) {
        push(@queries, @{ $l->get_sorted_queries });
    }
    return [ reverse sort { $a->time_elapsed <=> $b->time_elapsed } @queries ];
}

sub get_fastest_query_executions {
    my ($self, $sql) = @_;

    my @queries;
    foreach my $l (@{ $self->querylog->log }) {
        push(@queries, @{ $l->get_sorted_queries($sql) });
    }

    return [ sort { $a->time_elapsed <=> $b->time_elapsed } @queries ];
}


sub get_slowest_query_executions {
    my ($self, $sql) = @_;

    return [ reverse @{ $self->get_fastest_query_executions($sql) } ];
}


sub get_totaled_queries {
    my ($self, $honor_buckets) = @_;

    my %totaled;
    foreach my $l (@{ $self->querylog->log }) {
        foreach my $q (@{ $l->queries }) {
            if($honor_buckets) {
                return $self->get_totaled_queries_by_bucket;
            } else {
                $totaled{$q->sql}->{count}++;
                $totaled{$q->sql}->{time_elapsed} += $q->time_elapsed;
                push(@{ $totaled{$q->sql}->{queries} }, $q);
            }
        }
    }
    return \%totaled;
}


sub get_totaled_queries_by_bucket {
    my ($self) = @_;

    my %totaled;
    foreach my $l (@{ $self->querylog->log }) {
        foreach my $q (@{ $l->queries }) {
            $totaled{$q->bucket}->{$q->sql}->{count}++;
            $totaled{$q->bucket}->{$q->sql}->{time_elapsed} += $q->time_elapsed;
            push(@{ $totaled{$q->bucket}->{$q->sql}->{queries} }, $q);
        }
    }
    return \%totaled;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::Class::QueryLog::Analyzer - Query Analysis

=head1 VERSION

version 1.005001

=head1 SYNOPSIS

Analyzes the results of a QueryLog.  Create an Analyzer and pass it the
QueryLog:

    my $schema = ... # Get your schema!
    my $ql = DBIx::Class::QueryLog->new;
    $schema->storage->debugobj($ql);
    $schema->storage->debug(1);
    ... # do some stuff!
    my $ana = DBIx::Class::QueryLog::Analyzer->new({ querylog => $ql });
    my @queries = $ana->get_sorted_queries;
    # or...
    my $totaled = $ana->get_totaled_queries;

=head1 METHODS

=head2 new

Create a new DBIx::Class::QueryLog::Analyzer

=head2 get_sorted_queries

Returns an arrayref of all Query objects, sorted by elapsed time (descending).

=head2 get_fastest_query_executions($sql_statement)

Returns an arrayref of Query objects representing in order of the fastest
executions of a given statement.  Accepts either SQL or a
DBIx::Class::QueryLog::Query object.  If given SQL, it must match the executed
SQL, including placeholders.

  $ana->get_slowest_query_executions("SELECT foo FROM bar WHERE gorch = ?");

=head2 get_slowest_query_executions($sql_statement)

Opposite of I<get_fastest_query_executions>.  Same arguments.

=head2 get_totaled_queries

Returns hashref of the queries executed, with same-SQL combined and totaled.
So if the same query is executed multiple times, it will be combined into
a single entry.  The structure is:

    $var = {
        'SQL that was EXECUTED' => {
            count           => 2,
            time_elapsed    => 1931,
            queries         => [
                DBIx::Class::QueryLog...,
                DBIx::Class::QueryLog...
            ]
        }
    }

This is useful for when you've fine-tuned individually slow queries and need
to isolate which queries are executed a lot, so that you can determine which
to focus on next.

To sort it you'll want to use something like this (sorry for the long line,
blame perl...):

    my $analyzed = $ana->get_totaled_queries;
    my @keys = reverse sort {
            $analyzed->{$a}->{'time_elapsed'} <=> $analyzed->{$b}->{'time_elapsed'}
        } keys(%{ $analyzed });

So one could sort by count or time_elapsed.

=head2 get_totaled_queries_by_bucket

Same as get_totaled_queries, but breaks the totaled queries up by bucket:

$var = {
    'bucket1' => {
        'SQL that was EXECUTED' => {
            count           => 2,
            time_elapsed    => 1931,
            queries         => [
                DBIx::Class::QueryLog...,
                DBIx::Class::QueryLog...
            ]
        }
    }
    'bucket2' => { ... }
}

It is otherwise identical to get_totaled_queries

=head1 AUTHORS

=over 4

=item *

Arthur Axel "fREW" Schmidt <frioux+cpan@gmail.com>

=item *

Cory G Watson <gphat at cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Cory G Watson <gphat at cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
