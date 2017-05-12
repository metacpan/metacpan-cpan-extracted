package DBIx::Class::QueryLog::Query;
$DBIx::Class::QueryLog::Query::VERSION = '1.005001';
# ABSTRACT: A Query

use Moo;
use Types::Standard qw( Str Num ArrayRef );

has bucket => (
    is => 'rw',
    isa => Str
);

has end_time => (
    is => 'rw',
    isa => Num
);

has params => (
    is => 'rw',
    isa => ArrayRef
);

has sql => (
    is => 'rw',
    isa => Str
);

has start_time => (
    is => 'rw',
    isa => Num
);


sub time_elapsed {
    my $self = shift;

    return $self->end_time - $self->start_time;
}

sub count {

    return 1;
}

sub queries {
    my $self = shift;

    return [ $self ];
}

sub get_sorted_queries {
    my ($self, $sql) = @_;

    if(defined($sql)) {
        if($self->sql eq $sql) {
            return [ $self ];
        } else {
            return [  ];
        }
    }

    return [ $self ];
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::Class::QueryLog::Query - A Query

=head1 VERSION

version 1.005001

=head1 SYNOPSIS

Represents a query.  The sql, parameters, start time and end time are stored.

=head1 METHODS

=head2 bucket

The bucket this query is in.

=head2 start_time

Time this query started.

=head2 end_time

Time this query ended.

=head2 sql

SQL for this query.

=head2 params

Parameters used with this query.

=head2 time_elapsed

Time this query took to execute.  start - end.

=head2 count

Returns 1.  Exists to make it easier for QueryLog to get a count of
queries executed.

=head2 queries

Returns this query, here to make QueryLog's job easier.

=head2 get_sorted_queries

Returns this query.  Here to make QueryLog's job easier.

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
