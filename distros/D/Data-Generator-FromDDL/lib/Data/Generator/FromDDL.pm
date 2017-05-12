package Data::Generator::FromDDL;
use 5.008005;
use strict;
use warnings;
use Carp qw(croak);
use SQL::Translator;
use Class::Accessor::Lite (
    new => 1,
    rw => [qw(builder_class parser ddl include exclude)],
);

use Data::Generator::FromDDL::Director;
use Data::Generator::FromDDL::Util qw(normalize_parser_str);

our $VERSION = "0.06";

sub generate {
    my ($self, $num, $out_fh, $format, $pretty, $bytes_per_sql) = @_;

    # set default values if not specified
    my $builder_class = _load_builder_class($self->builder_class);
    my $parser = $self->parser || 'mysql';
    my $include = $self->include || [];
    my $exclude = $self->exclude || [];
    my $ddl = $self->ddl || '';
    $out_fh ||= *STDOUT;
    $format ||= 'sql';
    $bytes_per_sql ||= 1024 * 1024; # 1MB;

    my $schema = _parse_ddl($parser, $ddl);

    my $director = Data::Generator::FromDDL::Director->new(
        builder_class => $builder_class,
        schema => $schema,
        include => $include,
        exclude => $exclude,
    );

    my @recordsets = $director->generate($num);
    $director->flush(
        \@recordsets, $out_fh, $format, $pretty, $bytes_per_sql
    );
}

sub _parse_ddl {
    my ($parser, $ddl) = @_;
    my $tr = SQL::Translator->new;
    $tr->parser(normalize_parser_str($parser))->($tr, $ddl);
    croak "Parsing DDL failed. Please check a DDL syntax.\n"
        unless $tr->schema->is_valid;

    return $tr->schema;
}

sub _load_builder_class {
    my ($builder_class) = @_;
    $builder_class ||= 'Data::Generator::FromDDL::Builder::SerialOrder';

    my $builder_file = $builder_class;
    $builder_file =~ s!::!/!g;
    eval {
        require "$builder_file.pm";
    };
    if ($@) {
        croak("Can't require $builder_class \n");
    }

    return $builder_class;
}


1;
__END__

=encoding utf-8

=head1 NAME

Data::Generator::FromDDL - Dummy data generator from DDL statements

=head1 SYNOPSIS

    use Data::Generator::FromDDL;

    my $generator = Data::Generator::FromDDL->new({
        ddl => 'CREATE TABLE users (....);',
        parser => 'mysql',
    });
    $generator->generate(100); # Generated data are written to STDOUT.

=head1 DESCRIPTION

Data::Generator::FromDDL is dummy data generator intended to easily prepare dummy records for RDBMS.
This module takes care of some constraints and generates records in the right order.

Supported constraints are

    - PRIMARY KEY
    - UNIQUE KEY
    - FOREIGN KEY

Supported data types are

    - BIGINT
    - INT (INTEGER)
    - MEDIUMINT
    - SMALLINT
    - TINYINT
    - FLOAT
    - DOUBLE
    - BOOLEAN (BOOL)
    - TIMESTAMP
    - CHAR
    - VARCHAR
    - TINYTEXT
    - TEXT
    - MEDIUMTEXT
    - ENUM

=head1 METHODS

=over 4

=item B<new> - Create a new instance.

    Data::Generator::FromDDL->new(%options);

Possible options are:

=over 4

=item ddl => $ddl

Description of DDL. This option is required.

=item parser => $parser // 'MySQL'

Parser for ddl. Choices are 'MySQL', 'SQLite', 'Oracle', or 'PostgreSQL'.

=item builder_class => $builder_class // 'Data::Generator::FromDDL::Builder::SerialOrder'

Builder class.

=item include => [@tables] // []

Target tables.

=item exclude => [@tables] // []

Ignored tables.

=back

=item B<generate> - Generate dummy records.

    $generator->generate($num, $out_fh, $format, $pretty, $bytes_per_sql);

Arguments are:

=over 4

=item $num or \%num

Number of records generated.

Or you can also give number of records for each table.

    $num = {all => 20, # 20 records for all tables
            tables => {
                users => 10 # 10 records for 'users' table
                }
            };

This is useful for table that has one-to-many relationship with other table.

=item $out_fh (default: *STDOUT)

File handle object to which records are dumped.

=item $format (default: 'sql')

Output format. Choices are B<'sql'> or B<'json'>.

=item $pretty (default: false)

Boolean value whether to print output prettily.

=item $bytes_per_sql (default: 1048576(1MB))

The maximum bytes of bulk insert statement.

This argument is releated to the MySQL's B<'max_allowed_packet'> variable which stands for the maximum size of string. It's recommended to suit this argument for your MySQL settings.

cf. https://dev.mysql.com/doc/refman/5.1/en/server-system-variables.html#sysvar_max_allowed_packet

=back

=back

=head1 COMMAND LINE INTERFACE

The C<datagen_from_ddl(1)> command is provided as an interface to this module.

    $ datagen_from_ddl --num=100 --parser=mysql --pretty your_ddl.sql

For more details, please see L<datagen_from_ddl>(1).

=head1 CONTRIBUTORS

=over 4

=item Kesin11 (Kenta Kase)

=back

=head1 LICENSE

Copyright (C) Yuuki Furuyama.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Yuuki Furuyama E<lt>addsict@gmail.comE<gt>

=cut

