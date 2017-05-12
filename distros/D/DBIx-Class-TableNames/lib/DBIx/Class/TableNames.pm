package DBIx::Class::TableNames;
use strict;
use warnings;
use base 'DBIx::Class';
use Carp::Clan qw/^DBIx::Class/;

our $VERSION = '0.01';

sub table_names {
    my ($self, $key) = @_;
    my @tables = $self->storage->dbh->tables(undef, undef, $key, 'TABLE');
    s/\Q`\E//g for @tables; s/\Q"\E//g for @tables;s/.+\.(.+)/$1/g for @tables;
    return @tables;
}

1;

__END__

=head1 NAME

DBIx::Class::TableNames - get table name list from database

=head1 SYNOPSIS

    package Your::Schema;
    use base 'DBIx::Class::Schema';
    __PACKAGE__->load_classes;
    __PACKAGE__->load_components(qw/
        TableNames
    /);

    # in your script:
    my @tables = $schema->table_names;
    # or
    my @tables = $schema->table_names('user');
    # or
    my @tables = $schema->table_names('log_%');

=head1 DESCRIPTION

Get table name list from database.

=head1 METHOD

=head2 table_names

Get table name list from database.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

=head1 AUTHOR

Atsushi Kobayashi  C<< <nekokak __at__ gmail.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007, Atsushi Kobayashi C<< <nekokak __at__ gmail.com> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

