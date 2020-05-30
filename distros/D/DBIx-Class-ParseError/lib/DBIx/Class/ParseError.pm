package DBIx::Class::ParseError;

use strict;
use warnings;
use Moo;
use Try::Tiny;
use Module::Runtime 'use_module';
use DBIx::Class::Exception;

our $VERSION = '0.02';
$VERSION = eval $VERSION;

has _schema => (
    is => 'ro', required => 1, init_arg => 'schema',
    handles => { _storage => 'storage' }
);

has db_driver => (
    is => 'lazy', init_arg => undef,
);

sub _build_db_driver { shift->_storage->sqlt_type }

has _parser_class => (
    is => 'lazy', builder => '_build_parser_class',
);

sub _build_parser_class {
    return join q{::}, 'DBIx::Class::ParseError::Parser', shift->db_driver;
}

has _parser => (
    is => 'lazy', builder => '_build_parser',
);

sub _build_parser {
    my $self = shift;
    return try {
        use_module( $self->_parser_class )->new(
            schema        => $self->_schema,
            custom_errors => $self->custom_errors,
          )
    } catch { die 'No parser found for ' . $self->_db_driver };
}

has custom_errors => (
    is      => 'ro',
    default => sub { {} },
);

sub process {
    my ($self, $error) = @_;
    return try { $self->_parser->process($error) }
        catch { warn $_; DBIx::Class::Exception->throw($error) };
}

1;

__END__

=pod

=head1 NAME

DBIx::Class::ParseError - Extensible database error handler

=head1 SYNOPSIS

From:

    DBIx::Class::Storage::DBI::_dbh_execute(): DBI Exception: DBD::mysql::st execute failed: Duplicate entry \'1\' for key \'PRIMARY\' [for Statement "INSERT INTO foo ( bar_id, id, is_foo, name) VALUES ( ?, ?, ?, ? )" with ParamValues: 0=1, 1=1, 2=1, 3=\'Foo1571434801\'] at ...

To:

    use Data::Dumper;
    my $parser = DBIx::Class::ParseError->new(schema => $dbic_schema);
    print Dumper( $parser->process($error) );

    # bless({
    #    'table' => 'foo',
    #    'columns' => [
    #        'id'
    #    ],
    #    'message' => 'DBIx::Class::Storage::DBI::_dbh_execute(): DBI Exception: DBD::mysql::st execute failed: Duplicate entry \'1\' for key \'PRIMARY\' [for Statement "INSERT INTO foo ( bar_id, id, is_foo, name) VALUES ( ?, ?, ?, ? )" with ParamValues: 0=1, 1=1, 2=1, 3=\'Foo1571434801\'] at ...',
    #    'operation' => 'insert',
    #    'column_data' => {
    #        'name' => 'Foo1571434801',
    #        'bar_id' => '1',
    #        'id' => '1',
    #        'is_foo' => '1'
    #    },
    #    'source_name' => 'Foo',
    #    'type' => 'primary_key'
    # }, 'DBIx::Class::ParseError::Error' );

=head1 DESCRIPTION

This a tool to extend DB errors from L<DBIx::Class> (basically, database error
strings wrapped into a L<DBIx::Class::Exception> obj) into an API to provide
useful details of the error, allowing app's business layer or helper scripts
interfacing with database models to instrospect and better handle errors from
multiple DBMS.

=head2 ERROR CASES

This is a non-exausted list of common errors which should be handled by this
tool:

=over

=item primary key

=item foreign key(s)

=item unique key(s)

=item not null column(s)

=item data type

=item missing column

=item missing table

=back

=head1 CUSTOM ERRORS

You may find your code throwing exceptions that you would like to generate custom
errors for. You can specify them in the constructor:

    my $parser = DBIx::Class::ParseError->new(
        schema => $dbic_schema,
        custom_errors => {
            locking_failed => qr/Could not update due to version mismatch/i
        }
    );

The C<custom_errors> key must point to a hash references whose values are
regular expressions to match against the error. Due to the unpredictable
nature of these errors, the exception will like not have additional
information beyond the error message and the error message.

The parser will attempt to match custom errors before standard errors. Any
error will have the string C<custom_> prepended, so the above error will be
reported as C<custom_locking_failed>.

=head1 DRIVERS

Initial fully support for errors from the following DBMS:

=over

=item SQLite

See L<DBIx::Class::ParseError::Parser::SQLite>.

=item MySQL

See L<DBIx::Class::ParseError::Parser::MySQL>.

=item PostgreSQL

See L<DBIx::Class::ParseError::Parser::PostgreSQL>.

=back

=head1 AUTHOR

wreis - Wallace reis <wreis@cpan.org>

=head1 CONTRIBUTORS

Ovid - Curtis "Ovid" Poe <ovid@cpan.org>

=head1 COPYRIGHT

Copyright (c) the L</AUTHOR>.

=head1 LICENSE

This library is free software and may be distributed under the same terms
as perl itself.

=cut
