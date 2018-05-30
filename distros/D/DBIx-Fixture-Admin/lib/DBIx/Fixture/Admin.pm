package DBIx::Fixture::Admin;
use 5.008001;
use strict;
use warnings;

use DBIx::FixtureLoader;
use Teng::Schema::Loader;
use File::Basename qw/basename/;
use File::Spec;
use List::Util qw/any/;
use Set::Functional qw/difference intersection/;
use Data::Validator;
use Text::CSV_XS;
use Encode qw/encode decode/;
use Try::Tiny;

use Class::Accessor::Lite (
    new => 1,
    ro  => [ qw(conf dbh) ],
);

our $VERSION = "0.16";

sub load {
    my $v = Data::Validator->new(
        tables => +{ isa => 'ArrayRef[Str]' }
    )->with(qw/Method StrictSequenced/);
    my($self, $args) = $v->validate(@_);

    my @tables = intersection($args->{tables}, [$self->tables]);

    return unless scalar @tables;

    for my $table (@tables) {
        try {
            $self->_load_fixture(
                table        => $table,
                fixture_path => $self->conf->{fixture_path},
            );
        }
        catch {
            warn $_;
        };
    }
}

sub load_all {
    my ($self,) = @_;
    $self->load([$self->tables]);
}

sub load_external_fixture {
    my $v = Data::Validator->new(
        table                 => +{ isa => 'Str' },
        external_fixture_path => +{ isa => 'Str' },
    )->with(qw/Method/);
    my ($self, $args) = $v->validate(@_);

    $self->_load_fixture(
        table        => $args->{table},
        fixture_path => $args->{external_fixture_path},
    );
}

sub load_all_external_fixture {
    my $v = Data::Validator->new(
        external_fixture_path => +{ isa => 'Str' },
    )->with(qw/Method/);
    my ($self, $args) = $v->validate(@_);

    for my $table ($self->tables) {
        $self->_load_fixture(
            table        => $table,
            fixture_path => $args->{external_fixture_path},
        );
    }
}

sub create {
    my $v = Data::Validator->new(
        tables      => +{ isa => 'ArrayRef[Str]' },
        create_file => +{ isa => 'Bool', default => 1 },
    )->with(qw/Method  StrictSequenced/);
    my ($self, $args) = $v->validate(@_);

    my @result;
    for my $data ($self->_build_create_data($args->{tables})) {
        try {
            push @result, $self->_make_fixture_yaml(+{%$data, create_file => $args->{create_file}})
                if $self->conf->{fixture_type} eq 'yaml';

            push @result, $self->_make_fixture_csv(+{%$data, create_file => $args->{create_file}})
                if $self->conf->{fixture_type} eq 'csv';
        }
        catch {
            warn $_;
        };
    }

    return @result;
}

sub create_all {
    my $v = Data::Validator->new(
        create_file  => +{ isa => 'Bool', default => 1 },
    )->with(qw/Method/);
    my($self, $args) = $v->validate(@_);

    $self->create([$self->tables], $args->{create_file});
}

sub ignore_tables {
    my ($self,) = @_;

    return unless exists $self->conf->{ignore_tables};
    return @{$self->conf->{ignore_tables}};
}

sub fixtures {
    my ($self,) = @_;

    my @all_fixtures = $self->_all_fixtures;
    my $type = $self->conf->{fixture_type};
    my %table2fixture
        = map {
            my $tmp = basename($_);
            $tmp =~ s/\.$type$//;
            $tmp => basename($_);
        } @all_fixtures;

    my @tables = $self->_difference_ignore_tables([keys %table2fixture]);
    my @fixtures = map { $table2fixture{$_} } @tables;

    return @fixtures;
}

sub tables {
    my ($self,) = @_;
    return $self->_difference_ignore_tables([map { $_->[2] } @{$self->dbh->table_info('','','')->fetchall_arrayref}]);
}

sub _all_fixtures {
    my ($self,) = @_;

    return glob(File::Spec->catfile($self->conf->{fixture_path}, '*.' . $self->conf->{fixture_type}));
}

sub _difference_ignore_tables {
    my $v = Data::Validator->new(
        tables => 'ArrayRef[Str]'
    )->with(qw/Method StrictSequenced/);
    my($self, $args) = $v->validate(@_);

    my @tables        = @{$args->{tables}};
    my @ignore_tables = $self->ignore_tables;
    my @difference_tables;
    for my $table (@tables) {
        push @difference_tables, $table
            unless any { $table =~ m/^${_}$/ } @ignore_tables;
    }

    return @difference_tables;
}

sub _make_loader {
    my ($self,) = @_;

    $self->{__make_loader} = DBIx::FixtureLoader->new(dbh => $self->dbh)
        unless $self->{__make_loader} ;

    return $self->{__make_loader};
}

sub _build_create_data {
    my $v = Data::Validator->new(
        tables => +{ isa => 'ArrayRef[Str]' }
    )->with(qw/Method StrictSequenced/);
    my($self, $args) = $v->validate(@_);
    my @tables = $self->_difference_ignore_tables($args->{tables});
    return unless scalar @tables;

    my $schema = $self->_load_schema($self->dbh);
    my @shema_tables = keys %{$schema->{tables}};

    my $sql_maker = SQL::Maker->new(driver => $self->conf->{driver});
    my @data;
    for my $table (@tables) {
        (my $table_name = $table) =~ s/^\`\w+\`\.//;
        $table_name =~ s/\`//g;

        my $table_data = $schema->{tables}->{$table_name};

        my $columns = $table_data->columns;
        my ($sql)   = $sql_maker->select($table_name => $columns);

        push @data, +{ table => $table_name, columns => $columns, sql => $sql };
    }

    return @data;
}

sub _load_schema {
    my ($self, $dbh) = @_;

    $self->{__schema} = Teng::Schema::Loader->load(
        dbh => $dbh,
        namespace => 'Hoge',
    )->schema unless $self->{__schema};

    return $self->{__schema};
}

sub _load_fixture {
    my $v = Data::Validator->new(
        table                 => +{ isa => 'Str' },
        fixture_path => +{ isa => 'Str' },
    )->with(qw/Method/);
    my ($self, $args) = $v->validate(@_);

    my $loader   = $self->_make_loader;
    my $load_opt = exists $self->conf->{load_opt} ? $self->conf->{load_opt} : undef;

    my $fixture = File::Spec->catfile($args->{fixture_path}, $args->{table} . '.' . $self->conf->{fixture_type});
    return unless -f $fixture;

    $loader->load_fixture(
        $fixture,
        format => $self->conf->{fixture_type},
        csv_opt => +{ binary => 1 },
    ) unless $load_opt;

    $loader->load_fixture(
        $fixture,
        format => $self->conf->{fixture_type},
        csv_opt => +{ binary => 1 },
        $load_opt => 1,
    ) if $load_opt;
}

sub _make_fixture_yaml {
    my $v = Data::Validator->new(
        table     => 'Str',
        columns   => 'ArrayRef[Str]',
        sql       => 'Str',
        create_file => +{ isa => 'Bool', default => 1 },
    )->with(qw/Method/);
    my($self, $args) = $v->validate(@_);

    my %tmp_args     = %$args;
    my $fixture_path = File::Spec->catfile($self->conf->{fixture_path}, "$tmp_args{table}.yaml");

    _dump_yaml(
        $self->dbh,
        $tmp_args{table},
        $tmp_args{columns},
        $tmp_args{sql},
        $args->{create_file} ? $fixture_path : (),
    );
}

sub _dump_yaml {
    my ( $dbh, $schema, $name_column, $sql, $filename ) = @_;
    my $rows = $dbh->selectall_arrayref( $sql, +{ Slice => +{} } );

    my @data;
    for my $row (@$rows) {
        push(
            @data,
            +{
                schema => $schema,
                data   => $row,
            }
        );
    }

    if ($filename) {
        YAML::Syck::DumpFile( $filename, \@data );
    }
    else {
        return \@data;
    }
}

sub _make_fixture_csv {
    my $v = Data::Validator->new(
        table     => 'Str',
        columns   => 'ArrayRef[Str]',
        sql       => 'Str',
        create_file => +{ isa => 'Bool', default => 1 },
    )->with(qw/Method/);
    my($self, $args) = $v->validate(@_);

    my %tmp_args     = %$args;
    my @columns      = @{$args->{columns}};
    my $fixture_path = File::Spec->catfile($self->conf->{fixture_path}, "$tmp_args{table}.csv");

    my @data = @{$args->{columns}};
    my $rows = $self->dbh->selectall_arrayref( $args->{sql}, +{ Slice => +{} } );

    my $csv_builder = Text::CSV_XS->new(+{ binary => 1 });
    $csv_builder->combine(@columns);

    my $csv = $csv_builder->string . "\n";

    for my $row (@$rows) {
        my @values;
        for my $key (@data) {
            my $value = $row->{$key};
            push @values, decode('utf8', $value)
                unless utf8::is_utf8($value);

            push @values, $value
                if utf8::is_utf8($value);
        }
        $csv_builder->combine(@values);
        $csv = $csv . $csv_builder->string . "\n";
    }

    if ($args->{create_file}) {
        open my $file, '>', $fixture_path;
        print $file encode('utf8', $csv);
        close $file;
    }
    else {
        return $csv;
    }
}

1;
__END__

=encoding utf-8

=head1 NAME

DBIx::Fixture::Admin - facilitate data management by the fixtures

=head1 SYNOPSIS

    # in perl code
    use DBIx::Fixture::Admin;

    use DBI;
    my $dbh = DBI->connect("DBI:mysql:sample", "root", "");

    my $admin = DBIx::Fixture::Admin->new(
        conf => +{
            fixture_path  => "./fixture/",
            fixture_type  => "yaml",
            driver        => "mysql",
            load_opt      => "update",
            ignore_tables => ["user_.*", ".*_log"]  # ignore management
        },
        dbh => $dbh,
    );

    $admin->load_all(); # load all fixture
    $admin->create_all(); # create all fixture
    $admin->create(["sample"]); # create sample table fixture
    $admin->load(["sample"]); # load sample table fixture

    # in CLI
    # use config file .fixture in current dir
    # see also .fixture in thish repository
    create-fixture # execute create_all
    load-fixture   # execute load_all

=head1 DESCRIPTION

DBIx::Fixture::Admin is facilitate data management by the fixtures

=head1 LICENSE

Copyright (C) meru_akimbo.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

meru_akimbo E<lt>merukatoruayu0@gmail.comE<gt>

=cut

