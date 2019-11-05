package DBIx::Class::ParseError::Parser;

use strict;
use warnings;
use Moo::Role;
use DBIx::Class::ParseError::Error;
use Regexp::Common qw(list);

requires 'type_regex';

has _schema => (
    is => 'ro', required => 1, init_arg => 'schema',
);

has _source_table_map => (
    is => 'lazy', builder => '_build_source_table_map',
);

sub _build_source_table_map {
    my $self = shift;
    my $schema = $self->_schema;
    return {
        map {
            my $source = $schema->source($_);
            ( $schema->class($_) => $source, $source->from => $source )
        } $schema->sources
    };
}

sub parse_type {
    my ($self, $error) = @_;
    my $type_regex = $self->type_regex;
    foreach (sort keys %$type_regex) {
        if ( my @data = $error =~ $type_regex->{$_} ) {
            return {
                name => $_,
                data => [ grep { defined && length } @data ],
            };
        }
    }
    return { name => 'unknown' };
}

sub _add_info_from_type {
    my ($self, $error_info, $error_type) = @_;
    my $table = $error_info->{'table'};
    my $replace_dots = sub { $_[0] =~ s{\.}{_}; $_[0] };
    my $remove_table = sub { $_[0] =~ s{^$table\.}{}i; $_[0] };
    my $source = $self->_source_table_map->{$table};
    my $action_type_map = {
        unique_key => sub {
            my $unique_keys = { $source->unique_constraints };
            my $unique_data = [
                map { $replace_dots->($_) } @{ $error_type->{'data'} }
            ];
            if ( my $unique_cols = $unique_keys->{ $unique_data->[0] } ) {
                $error_info->{'columns'} = [
                    map { $remove_table->($_) } @$unique_cols
                ];
            }
            else {
                $error_info->{'type'} = 'primary_key';
                $error_info->{'columns'} = [
                    map { $remove_table->($_) } @{ $unique_keys->{'primary'} }
                ];
            }
        },
        primary_key => sub {
            $error_info->{'columns'} = [
                map { $remove_table->($_) } $source->primary_columns
            ];
        },
        default => sub {
            if ( @{ $error_type->{'data'} } ) {
                $error_info->{'columns'} = [
                    map { $remove_table->($_) } @{ $error_type->{'data'} }
                ];
            }
        },
    };
    ( $action_type_map->{ $error_type->{'name'} }
          || $action_type_map->{'default'} )->();
    return $error_info;
}

sub _build_column_data {
    my ($self, $column_keys, $column_values) = @_;
    $column_keys =~ s{\s*=\s*\?}{}g;
    $column_keys = [split(/\,\s+/, $column_keys)];
    if ($column_values) {
        $column_values =~ s{\'}{}g;
        $column_values = [
            map { (split(/=/))[1] }
                split(/\,\s+/, $column_values)
        ];
        return {
            map {
                my $value = shift(@$column_values);
                $_ => ($value =~ m/undef/ ? undef : $value)
            } @$column_keys
        };
    }
    else {
        return { map { $_ => undef } @$column_keys };
    }
}

sub parse_general_info {
    my ($self, $error, $error_type) = @_;

    my $insert_re = qr{
        INSERT\s+INTO\s+
        (\w+)\s+
        \( \s* ($RE{list}{-pat => '\w+'}|\w+)\s* \)\s+
        VALUES\s+
        \( \s* (?:$RE{list}{-pat => '\?'}|\?)\s* \)\s*\"
        \s*\w*\s*\w*:?\s*
        ($RE{list}{-pat => '\d=\'?[\w\s]+\'?'})?
    }ix;

    my $update_re = qr{
        UPDATE\s+
        (\w+)\s+
        SET\s+
        ($RE{list}{-pat => '\w+\s*\=\s*\?'}|\w+\s*\=\s*\?)\s*
        (?:WHERE)?.*\"
        \s*\w*\s*\w*:?\s*
        ($RE{list}{-pat => '\d=\'?[\w\s]+\'?'})?
    }ix;

    my $missing_column_re = qr{
        (store_column|get_column)\(\)\:\s+
        no\s+such\s+column\s+['"](\w+)['"]\s+
        on\s+($RE{list}{-pat => '\w+'}{-sep => '::'})
    }ix;

    my $source_table_map = $self->_source_table_map;

    my $error_info;
    if ( $error =~ $insert_re ) {
        my ($table, $column_keys, $column_values) = ($1, $2, $3);
        $error_info = {
            operation => 'insert',
            table => $table,
            column_data => $self->_build_column_data(
                $column_keys, $column_values
            ),
        };
    }
    elsif ( $error =~ $update_re ) {
        my ($table, $column_keys, $column_values) = ($1, $2, $3);
        $error_info = {
            operation => 'update',
            table => $table,
            column_data => $self->_build_column_data(
                $column_keys, $column_values
            ),
        };
    }
    elsif ( $error =~ $missing_column_re ) {
        my ($op_key, $column, $source_name) = ($1, $2, $3);
        my $op_mapping = {
            'store_column' => 'insert',
            'get_column' => 'update',
        };
        my $source = $source_table_map->{ $source_name };
        $error_info = {
            operation => $op_mapping->{ lc $op_key },
            $source ? ( table => $source->name ) : (),
            columns => [$column],
        };
    }
    else {
        die 'Parsing error string failed';
    }

    if (my $source = $source_table_map->{ $error_info->{'table'} }) {
        $error_info->{'source_name'} = $source->source_name;
    }

    return $self->_add_info_from_type($error_info, $error_type);
}

sub process {
    my ($self, $error) = @_;
    my $error_type = $self->parse_type($error);
    my $err_info = {
        type => $error_type->{'name'},
        %{ $self->parse_general_info($error, $error_type) },
    };
    return DBIx::Class::ParseError::Error->new(
        message => "$error",
        %$err_info,
    );
}

1;

__END__

=pod

=head1 NAME

DBIx::Class::ParseError::Parser - Parser base role

=head1 DESCRIPTION

The core logic of parsing DB errors for different DBMS, which specific classes
could do its interface and extend functionality where appropriate.

=head1 INTERFACE

=head2 type_regex

It's the only method required to be implemented by the consumer of the parser role,
returning a hashref with error types as keys and regex as values.

=head2 parse_type

Provides default implementation for parsing type out from error strings.

=head2 parse_general_info

Provides default implementation for parsing general info (table name, operation,
column info, etc) out from error strings.

=head2 process

Main handler, base logic, invokes the other two above and returns a L<DBIx::Class::ParseError::Error>
object.

=head1 AUTHOR

wreis - Wallace reis <wreis@cpan.org>

=head1 COPYRIGHT

Copyright (c) the L</AUTHOR> and L</CONTRIBUTORS> as listed above.

=head1 LICENSE

This library is free software and may be distributed under the same terms
as perl itself.

=cut
