package DBIx::FixtureLoader;
use 5.008001;
use strict;
use warnings;

our $VERSION = "0.21";

use Carp qw/croak/;
use DBIx::TransactionManager;
use File::Basename qw/basename/;

use SQL::Maker;
SQL::Maker->load_plugin('InsertMulti');
SQL::Maker->load_plugin('InsertOnDuplicate');

use Moo;

has dbh => (
    is       => 'ro',
    isa      => sub { shift->isa('DBI::db') },
    required => 1,
);

has transaction_manager => (
    is => 'lazy',
    default => sub {
        DBIx::TransactionManager->new(shift->dbh);
    },
);

has bulk_insert => (
    is      => 'lazy',
    default => sub {
        my $self = shift;
        return undef if $self->skip_null_column;

        my $driver_name = $self->_driver_name;
        my $dbh         = $self->dbh;
        $driver_name eq 'mysql'                                      ? 1 :
        $driver_name eq 'Pg' && $dbh->{ pg_server_version } >= 82000 ? 1 :
                                                                       0 ;
    },
);

has update => (
    is      => 'ro',
    default => sub { undef },
);

has ignore => (
    is      => 'ro',
    default => sub { undef },
);

has delete => (
    is      => 'ro',
    default => sub { undef },
);

has skip_null_column => (
    is      => 'ro',
    default => sub { undef },
);

has csv_option => (
    is      => 'ro',
    isa     => sub { ref $_[0] eq 'HASH' },
    default => sub { {} },
);

has _driver_name => (
    is      => 'lazy',
    default => sub {
        shift->dbh->{Driver}{Name};
    },
);

has _sql_builder => (
    is      => 'lazy',
    default => sub {
        SQL::Maker->new(
            driver => shift->_driver_name,
        );
    }
);

no Moo;

sub load_fixture {
    my $self = shift;
    my $file = shift;
    my %opts = ref $_[0] ? %{$_[0]} : @_;

    my $update = $opts{update};
    my $ignore = $opts{ignore};
    croak '`update` and `ignore` are exclusive argument' if $update && $ignore;

    if (ref($file) =~ /^(?:ARRAY|HASH)$/) {
        return $self->_load_fixture_from_data(data => $file, %opts);
    }

    my $table  = $opts{table};
    my $format = lc($opts{format} || '');

    unless ($table) {
        my $basename = basename($file);
        ($table) = $basename =~ /^([_A-Za-z0-9]+)/;
    }

    unless ($format) {
        ($format) = $file =~ /\.([^.]*$)/;
    }

    my $rows;
    if ($format eq 'csv' || $format eq 'tsv') {
        $rows = $self->_get_data_from_csv($file, $format);
    }
    else {
        if ($format eq 'json') {
            require JSON;
            my $content = do {
                local $/;
                open my $fh, '<', $file or die $!;
                <$fh>;
            };
            $rows = JSON::decode_json($content);
        }
        elsif ($format =~ /ya?ml/) {
            require YAML::Tiny;
            $rows = YAML::Tiny->read($file) or croak( YAML::Tiny->errstr );
            $rows = $rows->[0];
        }
    }

    $self->load_fixture($rows,
        table  => $table,
        %opts,
    );
}

sub _get_data_from_csv {
    my ($self, $file, $format) = @_;
    require Text::CSV;

    my $csv = Text::CSV->new({
        binary         => 1,
        blank_is_undef => 1,
        sep_char => $format eq 'tsv' ? "\t" : ',',
        %{ $self->csv_option },
    }) or croak( Text::CSV->error_diag );

    open my $fh, '<', $file or die "$!";
    my $columns = $csv->getline($fh);
    my @records;
    while ( my $row = $csv->getline($fh) ){
        my %cols = map { $columns->[$_] => $row->[$_] } 0..$#$columns;
        push @records, \%cols;
    }
    \@records;
}

sub _load_fixture_from_data {
    my ($self, %args) = @_;
    my ($table, $data) = @args{qw/table data/};

    croak '`update` and `ignore` are exclusive option' if $args{update} && $args{ignore};

    my $update = $self->update;
    my $ignore = $self->ignore;
    croak '`update` and `ignore` are exclusive option' if $update && $ignore;

    my $bulk_insert      = $self->bulk_insert;
    my $skip_null_column = $self->skip_null_column;
    croak '`bulk_insert` and `skip_null_column` are exclusive option' if $bulk_insert && $skip_null_column;

    # The $args has priority. So default object property is ignored.
    if (exists $args{update}) {
        $update = $args{update};
        $ignore = undef if $update;
    }
    if (exists $args{ignore}) {
        $ignore = $args{ignore};
        $update = undef if $ignore;
    }

    if ($update && $self->_driver_name ne 'mysql') {
        croak '`update` option only support mysql'
    }
    my $delete = $self->delete || $args{delete};

    $data = $self->_normalize_data($data);

    my $dbh = $self->dbh;
    # needs limit ?
    my $txn = $self->transaction_manager->txn_scope or croak $dbh->errstr;

    if ($delete) {
        my ($sql, @binds) = $self->_sql_builder->delete($table);
        $dbh->do($sql, undef, @binds);
    }

    unless (scalar @$data) {
        my $ret = $txn->commit or croak $dbh->errstr;
        return $ret;
    }

    my $opt; $opt->{prefix} = 'INSERT IGNORE INTO' if $ignore;
    if ($bulk_insert) {
        $opt->{update} = _build_on_duplicate(keys %{$data->[0]}) if $update;

        my ($sql, @binds) = $self->_sql_builder->insert_multi($table, $data, $opt ? $opt : ());

        $dbh->do( $sql, undef, @binds ) or croak $dbh->errstr;
    }
    else {
        my $method = $update ? 'insert_on_duplicate' : 'insert';
        for my $row_orig (@$data) {
            my $row = !$skip_null_column ? $row_orig : {map {
                defined $row_orig->{$_} ? ($_ => $row_orig->{$_}) : ()
            } keys %$row_orig};
            $opt = _build_on_duplicate(keys %$row) if $update;
            my ($sql, @binds) = $self->_sql_builder->$method($table, $row, $opt ? $opt : ());

            $dbh->do( $sql, undef, @binds ) or croak $dbh->errstr;
        }
    }
    $txn->commit or croak $dbh->errstr;
}

sub _build_on_duplicate {
    +{ map {($_ => \"VALUES(`$_`)")} @_ };
}

sub _normalize_data {
    my ($self, $data) = @_;
    my @ret;
    if (ref $data eq 'HASH') {
        push @ret, $data->{$_} for keys %$data;
    }
    elsif (ref $data eq 'ARRAY') {
        if ($data->[0] && $data->[0]{data} && ref $data->[0]{data} eq 'HASH') {
            @ret = map { $_->{data} } @$data;
        }
        else {
            @ret = @$data;
        }
    }
    \@ret;
}

1;
__END__

=encoding utf-8

=head1 NAME

DBIx::FixtureLoader - Loading fixtures and inserting to your database

=head1 SYNOPSIS

    use DBI;
    use DBIx::FixtureLoader;

    my $dbh = DBI->connect(...);
    my $loader = DBIx::FixtureLoader->new(dbh => $dbh);
    $loader->load_fixture('item.csv');

=head1 DESCRIPTION

DBIx::FixtureLoader is to load fixture data and insert to your database.

=head1 INTEFACE

=head2 Constructor

    $loader = DBIx::FixtureLoader->new(%option)

C<new> is Constructor method. Various options may be set in C<%option>, which affect
the behaviour of the object (Type and defaults in parentheses):

=head3 C<< dbh (DBI::db) >>

Required. Database handler.

=head3 C<< bulk_insert (Bool) >>

Using bulk_insert or not. Default value depends on your database.

=head3 C<< update (Bool, Default: false) >>

Using C<< INSERT ON DUPLICATE >> or not. It only works on MySQL.

=head3 C<< ignore (Bool, Default: false) >>

Using C<< INSERT IGNORE >> or not. This option is exclusive with C<update>.

=head3 C<< delete (Bool, Default: false) >>

DELETE all data from table before inserting or not.

=head3 C<< csv_option (HashRef, Default: +{}) >>

Specifying L<Text::CSV>'s option. C<binary> and C<blank_is_undef>
are automatically set.

=head3 C<< skip_null_column (Bool, Default: false) >>

If true, null data is not to be inserted or updated explicitly. It it for using default value.

NOTE: If this option is true, data can't be overwritten by null value.

=head2 Methods

=head3 C<< $loader->load_fixture($file_or_data:(Str|HashRef|ArrayRef), [%option]) >>

Loading fixture and inserting to your database. Table name and file format is guessed from
file name. For example, "item.csv" contains data of "item" table and format is "CSV".

In most cases C<%option> is not needed. Available keys of C<%option> are as follows.

=over

=item C<table:Str>

table name of database.

=item C<format:Str>

data format. "CSV", "YAML" and "JSON" are available.

=item C<update:Bool>

Using C<< ON DUPLICATE KEY UPDATE >> or not. Default value depends on object setting.

=item C<< ignore:Bool >>

Using C<< INSERT IGNORE >> or not.

=item C<< delete:Bool >>

DELETE all data from table before inserting or not.

=back

=head2 File Name and Data Format

=head3 file name

Data format is guessed from extension. Table name is guessed from basename. Leading alphabets,
underscores and numbers are considered table name. So, C<"user_item-2.csv"> is considered CSV format
and containing data of "user_item" table.

=head3 data format

"CSV", "YAML" and "JSON" are parsable. CSV file must have header line for determining column names.

Datas in "YAML" or "JSON" must be ArrayRef or HashRef containing HashRefs. Each HashRef is the data
of database record and keys of HashRef is matching to column names of the table.

=head1 LICENSE

Copyright (C) Masayuki Matsuki.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Masayuki Matsuki E<lt>y.songmu@gmail.comE<gt>

=cut
