package Data::Sample::SQL::Slow;
use 5.008005;
use strict;
use warnings;
use Data::Dumper;

our $VERSION = "0.01";

sub new {
    my ($class, %opt) = @_;

    bless {
        time => $opt{time} || time,
        user => $opt{user} || "hoge",
        host => $opt{host} || "localhost",
        id   => $opt{id} || int(rand() * 100000),
        query_time => $opt{query_time} || rand() + 3,
        lock_time  => $opt{lock_time} || rand(),
        rows_sent  => $opt{rows_sent} || int(rand() * 1000000),
        rows_examined => $opt{rows_examined} || int(rand() * 1000000),
        query => $opt{query} || $class->queryBuild(%opt),
    }, $class;
};

sub toStr {
    my $self = shift;

    "# Time: $self->{time}\n".
    "# User\@Host: $self->{user}\[$self->{user}\] @ $self->{host} []  Id: $self->{id}\n".
    "# Query_time: $self->{query_time}  Lock_time: $self->{lock_time} Rows_sent: $self->{rows_sent}  Rows_examined: $self->{rows_examined}\n".
    "SET timestamp=$self->{time}\n".
    "$self->{query}";
};

sub queryBuild {
    my ($self, %opt) = @_;

    my @tables = qw/users posts comments blogs/;
    my @queries = qw/select/;

    my $table = $opt{table} || $tables[int(rand() * scalar @tables)];
    my $query = $opt{query} || $queries[int(rand() * scalar @queries)];

    if($query eq "select"){
        "SELECT * FROM $table WHERE name LIKE \"\%hoge\%\" AND updatedAt > ".time;
    }
}

1;
__END__

=encoding utf-8

=head1 NAME

Data::Sample::SQL::Slow - It's new $module

=head1 SYNOPSIS

    use Data::Sample::SQL::Slow;

=head1 DESCRIPTION

Data::Sample::SQL::Slow is ...

=head1 LICENSE

Copyright (C) muddydixon.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

muddydixon E<lt>muddydixon@gmail.comE<gt>

=cut

