package DBIx::Class::ParseError::Parser;

use Moo::Role;
use Carp 'croak';
use DBIx::Class::ParseError::Error;
use Regexp::Common qw(list);

requires 'type_regex';

has _schema => (
    is => 'ro', required => 1, init_arg => 'schema',
);

has custom_errors => (
    is      => 'ro',
    default => sub { {} },
);

# Feels weird putting the BUILD method in a role, but this effectively acts as
# a base class. We can't use a method modifier because BUILD isn't in the
# inheritance hierarchy of the classes and I didn't think it was appropriate
# to change too much.
sub BUILD {
    my $self           = shift;
    my $custom_errors = $self->custom_errors;
    foreach my $type ( keys %$custom_errors ) {
        unless ( $type =~ /^custom_/ ) {
            $custom_errors->{"custom_$type"} = delete $custom_errors->{$type};
            $type = "custom_$type";
        }
        unless ('Regexp' eq ref $custom_errors->{$type} ) {
            my $ref = ref $custom_errors->{$type} || 'string';
            croak("Custom errors should point to Regexp references, not '$ref': $type");
        }
    }
}

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
    my ( $self, $error ) = @_;
    my $custom_errors = $self->custom_errors;
    my $type_regex    = $self->type_regex;

    # try to match custom errors first
    foreach ( sort keys %$custom_errors ) {
        if ( my @data = $error =~ $custom_errors->{$_} ) {
            return {
                name => $_,
                data => [ grep { defined && length } @data ],
            };
        }
    }
    foreach ( sort keys %$type_regex ) {
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
        \( \s* (?:$RE{list}{-pat => '\?'}|\?)\s* \)\s*
        (?:RETURNING\s+id)?   # optional ID return from PostgreSQL
        \s*\"
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
    my $error_matched;
    if ( $error =~ $insert_re ) {
        my ($table, $column_keys, $column_values) = ($1, $2, $3);
        $error_info = {
            operation => 'insert',
            table => $table,
            column_data => $self->_build_column_data(
                $column_keys, $column_values
            ),
        };
        $error_matched = 1;
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
        $error_matched = 1;
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
        $error_matched = 1;
    }
    elsif ( $error_type->{'name'} eq 'missing_table' ) {
        my $table_name = $error_type->{'data'}[0];
        $error_info = {
            table => $table_name,
            operation => q{},
            columns => [],
            column_data => {},
            source_name => $source_table_map->{ $table_name }->source_name,
        };
        $error_matched = 1;
    }

    if (my $source = $source_table_map->{ $error_info->{'table'} || '' }) {
        $error_info->{'source_name'} = $source->source_name;
    }

    my $type = $error_type->{name};

    # some databases may support more different error types. Those should be
    # prefixed with "custom_" (such as "custom_unknown_function" or
    # something). This allows different databases to present different error
    # types.
    #
    # However, these errors come in many sizes and shapes. We can't
    # deterministically say what the columns, operation or *anything* really
    # is, so we just punt and hand it back to the developer.
    if ( $type =~ /^custom_/ ) {
        return {
            column_data => ( $error_info->{column_data} || {} ),
            columns     => ( $error_info->{columns}     || [] ),
            operation   => ( $error_info->{operation}   || '' ),
            source_name => ( $error_info->{source_name} || '' ),
            table       => ( $error_info->{table}       || '' ),
            type        => $type,
        };
    }

    unless ($error_matched) {
        die 'Parsing error string failed';
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
