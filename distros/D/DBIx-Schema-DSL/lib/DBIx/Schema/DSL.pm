package DBIx::Schema::DSL;
use 5.008_001;
use strict;
use warnings;

our $VERSION = '0.12';

use Carp qw/croak/;
use Array::Diff;
use DBIx::Schema::DSL::Context;
use SQL::Translator::Schema::Constants;
use SQL::Translator::Schema::Field;

sub context {
    my $pkg = shift;
    die 'something wrong when calling context method.' if $pkg eq __PACKAGE__;
    no strict 'refs';
    ${"$pkg\::CONTEXT"} ||= DBIx::Schema::DSL::Context->new;
}

# don't override CORE::int
use Pod::Functions ();
my @column_methods =
    grep {!$Pod::Functions::Type{$_}} grep { /^[a-zA-Z_][0-9a-zA-Z_]*$/ } keys(%SQL::Translator::Schema::Field::type_mapping), qw/string number enum set/;
my @column_sugars  = qw/unique auto_increment unsigned null/;
my @rev_column_sugars = qw/not_null signed/;
my @export_dsls = qw/
    create_database database    create_table    column      primary_key set_primary_key add_index   add_unique_index
    foreign_key     has_many    has_one         belongs_to  add_table_options   default_unsigned    columns pk  fk
    default_not_null
/;
my @class_methods = qw/context output no_fk_output translate_to translator/;
sub import {
    my $caller = caller;

    no strict 'refs';
    for my $func (@export_dsls, @column_methods, @column_sugars, @class_methods, @rev_column_sugars) {
        *{"$caller\::$func"} = \&$func;
    }
}

sub create_database($) { caller->context->name(shift) }
sub database($)        { caller->context->db(shift)   }

sub add_table_options {
    my $c = caller->context;
    my %opt = @_;

    $c->set_table_extra({
        %{$c->table_extra},
        %opt,
    });

    if ($opt{mysql_charset} && $opt{mysql_charset} eq 'utf8mb4') {
        $c->default_varchar_size(191);
    }
}

sub default_unsigned() {
    caller->context->default_unsigned(1);
}

sub default_not_null() {
    caller->context->default_not_null(1);
}

sub create_table($$) {
    my ($table_name, $code) = @_;

    my $kls = caller;
    my $c = $kls->context;

    $c->_creating_table({
        table_name  => $table_name,
        columns     => [],
        indices     => [],
        constraints => [],
        primary_key => undef,
    });

    $code->();

    my $data = $c->_creating_table;
    my $table = $c->schema->add_table(
        name   => $table_name,
        extra  => {%{$c->table_extra}},
    );
    for my $column (@{ $data->{columns} }) {
        $table->add_field(%{ $column } );
    }

    my @columns = map {$_->{name}} @{$data->{columns}};
    for my $index (@{ $data->{indices} }) {
        if (my @undefined_columns = _detect_undefined_columns(\@columns, $index->{fields})) {
            croak "Index error: Key column [@{[join ', ', @undefined_columns]}] doesn't exist in table]";
        }
        $table->add_index(%{ $index } );
    }
    for my $constraint (@{ $data->{constraints} }) {
        my $cols = $constraint->{fields};
        $cols = [$cols] unless ref $cols;
        if (my @undefined_columns = _detect_undefined_columns(\@columns, $cols)) {
            croak "Constraint error: Key column [@{[join ', ', @undefined_columns]}] doesn't exist in table]";
        }
        $table->add_constraint(%{ $constraint } );
    }

    if (my $pk = $data->{primary_key}) {
        $pk = [$pk] unless ref $pk;
        if (my @undefined_columns = _detect_undefined_columns(\@columns, $pk)) {
            croak "Primary key error: Key column [@{[join ', ', @undefined_columns]}] doesn't exist in table]";
        }
        $table->primary_key($data->{primary_key});
    }

    $c->_clear_creating_table;
}
sub columns(&) {shift}

sub _detect_undefined_columns {
    my ($set, $subset) = @_;

    my $diff = Array::Diff->diff([sort @$set], [sort @$subset]);
    @{$diff->added};
}

sub column($$;%) {
    my ($column_name, $data_type, @opt) = @_;
    croak '`column` function called in non void context' if defined wantarray;

    if (ref $opt[0] eq 'ARRAY') {
        # enum or set
        unshift @opt, 'list';
    }

    if (@opt % 2) {
        croak "odd number elements are assined to options. arguments: [@{[join ', ', @_]}]";
    }
    my %opt = @opt;
    $data_type = 'varchar' if $data_type eq 'string';

    my $c = caller->context;

    my $creating_data = $c->_creating_table
        or croak q{can't call `column` method outside `create_table` method};

    my %args = (
        name      => $column_name,
        data_type => uc $data_type,
    );

    my %map = (
        null           => 'is_nullable',
        limit          => 'size',
        default        => 'default_value',
        unique         => 'is_unique',
        primary_key    => 'is_primary_key',
        auto_increment => 'is_auto_increment',
    );
    for my $key (keys %map) {
        $args{$map{$key}}   = delete $opt{$key} if exists $opt{$key};
    }
    %args = (
        %args,
        %opt
    );

    if (exists $args{unsigned}) {
        $args{extra}{unsigned} = delete $args{unsigned};
    }
    elsif ($c->default_unsigned && $data_type =~ /int(?:eger)?$/) {
        $args{extra}{unsigned} = 1;
    }

    if (exists $args{on_update}) {
        $args{extra}{'on update'} = delete $args{on_update};
    }

    if (exists $args{list}) {
        $args{extra}{list} = delete $args{list};
    }


    if ( !exists $args{is_nullable} && $c->default_not_null ) {
        $args{is_nullable} = 0;
    }

    if ($args{data_type} eq 'VARCHAR' && !$args{size}) {
        $args{size} = $c->default_varchar_size;
    }

    if ($args{precision}) {
        my $precision = delete $args{precision};
        my $scale     = delete $args{scale} || 0;
        $args{size} = [$precision, $scale];
    }

    if ($args{is_primary_key}) {
        $creating_data->{primary_key} = $column_name;
    }
    elsif ($args{is_unique}) {
        push @{$creating_data->{constraints}}, {
            name   => "${column_name}_uniq",
            fields => [$column_name],
            type   => UNIQUE,
        };
    }

    # explicitly add `DEFAULT NULL` if is_nullable and not specified default_value
    if ($args{is_nullable} && !exists $args{default_value} && $args{data_type} !~ /^(?:TINY|MEDIUM|LONG)?(?:TEXT|BLOB)$/ ) {
        $args{default_value} = \'NULL';
    }

    push @{$creating_data->{columns}}, \%args;
}

sub primary_key {
    if (defined wantarray) {
        (primary_key => 1);
    }
    else { # void context
        my $column_name = shift;

        @_ = ($column_name, 'integer', primary_key(), auto_increment(), @_);
        goto \&column;
    }
}
*pk = \&primary_key;

for my $method (@column_methods) {
    no strict 'refs';
    *{__PACKAGE__."::$method"} = sub {
        use strict 'refs';
        my $column_name = shift;

        @_ = ($column_name, $method, @_);
        goto \&column;
    };
}

for my $method (@column_sugars) {
    no strict 'refs';
    *{__PACKAGE__."::$method"} = sub() {
        use strict 'refs';
        ($method => 1);
    };
}
sub not_null() { (null => 0)     }
sub signed()   { (unsigned => 0) }

sub set_primary_key(@) {
    my @keys = @_;

    my $c = caller->context;

    my $creating_data = $c->_creating_table
        or die q{can't call `set_primary_key` method outside `create_table` method};

    $creating_data->{primary_key} = \@keys;
}

sub add_index {
    my $c = caller->context;

    my $creating_data = $c->_creating_table
        or die q{can't call `add_index` method outside `create_table` method};

    my ($idx_name, $fields, $type) = @_;

    push @{$creating_data->{indices}}, {
        name   => $idx_name,
        fields => $fields,
        ($type ? (type => $type) : ()),
    };
}

sub add_unique_index {
    my $c = caller->context;

    my $creating_data = $c->_creating_table
        or die q{can't call `add_unique_index` method outside `create_table` method};

    my ($idx_name, $fields) = @_;

    push @{$creating_data->{indices}}, {
        name   => $idx_name,
        fields => $fields,
        type   => UNIQUE,
    };
}

sub foreign_key {
    my $c = caller->context;

    my $creating_data = $c->_creating_table
        or die q{can't call `foreign` method outside `create_table` method};

    my ($columns, $table, $foreign_columns, %opt) = @_;

    push @{$creating_data->{constraints}}, {
        type => FOREIGN_KEY,
        fields           => $columns,
        reference_table  => $table,
        reference_fields => $foreign_columns,
        %opt,
    };
}
*fk = \&foreign_key;

sub has_many {
    my $c = caller->context;

    my ($table, %opt) = @_;

    my $columns         = delete $opt{column}         || 'id';
    my $foreign_columns = delete $opt{foreign_column} || $c->_creating_table_name .'_id';

    @_ = ($columns, $table, $foreign_columns, %opt);
    goto \&foreign_key;
}

sub has_one {
    my $c = caller->context;

    my ($table, %opt) = @_;

    my $columns         = delete $opt{column}         || 'id';
    my $foreign_columns = delete $opt{foreign_column} || $c->_creating_table_name .'_id';

    @_ = ($columns, $table, $foreign_columns, %opt);
    goto \&foreign_key;
}

sub belongs_to {
    my ($table, %opt) = @_;

    my $columns         = delete $opt{column}         || "${table}_id";
    my $foreign_columns = delete $opt{foreign_column} || 'id';

    @_ = ($columns, $table, $foreign_columns, %opt);
    goto \&foreign_key;
}

sub output {
    shift->context->translate;
}

sub no_fk_output {
    shift->context->no_fk_translate;
}

sub translator {
    shift->context->translator;
}

sub translate_to {
    my ($kls, $db_type) = @_;

    $kls->translator->translate(to => $db_type);
}

1;
__END__

=head1 NAME

DBIx::Schema::DSL - DSL for Database schema declaration

=head1 VERSION

This document describes DBIx::Schema::DSL version 0.12.

=head1 SYNOPSIS

    # declaration
    package My::Schema;
    use DBIx::Schema::DSL;

    database 'MySQL';              # optional. default 'MySQL'
    create_database 'my_database'; # optional

    # Optional. Default values is same as follows if database is 'MySQL'.
    add_table_options
        'mysql_table_type' => 'InnoDB',
        'mysql_charset'    => 'utf8';

    create_table 'book' => columns {
        integer 'id',   primary_key, auto_increment;
        varchar 'name', null;
        integer 'author_id';
        decimal 'price', 'size' => [4,2];

        add_index 'author_id_idx' => ['author_id'];

        belongs_to 'author';
    };

    create_table 'author' => columns {
        primary_key 'id';
        varchar 'name';
        decimal 'height', 'precision' => 4, 'scale' => 1;

        add_index 'height_idx' => ['height'];

        has_many 'book';
    };

    1;

    # use your schema class like this
    # use My::Schema;
    # print My::Schema->output; # output DDL

=head1 DESCRIPTION

This module provides DSL for database schema declaration like ruby's ActiveRecord::Schema.

B<THE SOFTWARE IS IT'S IN ALPHA QUALITY. IT MAY CHANGE THE API WITHOUT NOTICE.>

=head1 INTERFACE

=head2 Export Functions

=head3 C<< database($str :Str) >>

Set database type like MySQL, Oracle and so on.
(Optional default 'MySQL')

=head3 C<< create_database($str :Str) >>

Set database name. (Optional)

=head3 C<< add_table_options(%opt :Hash) >>

Set global setting of table->extra for SQL::Translator::Schema::Table

=head3 C<< default_unsigned() >>

Automatically set unsigned when declaring integer columns.
If you want to declare singed columns, using `singed` sugar.

=head3 C<< default_not_null() >>

Automatically set not null.
If you want to declare null columns, using `null` sugar.

=head3 C<< create_table($table_name :Str, $columns :CodeRef) >>

Declare table.

=head3 C<< columns { block } :CodeRef >>

Declare columns settings of table in block. In fact C<< columns {...} >>
is mostly same as C<< sub {...} >>, so just syntax sugar.

=head2 Export Functions for declaring column

=head3 C<< column($column_name :Str, $data_type :Str(DataType), (%option :Optional)) >>

Declare column. It can be called only in create_table block.

C<< $data_type >> strings (ex. C<< integer >> ) are can be used as a function.

C<< integer($column_name, (%option)) >> is same as C<< column('integer', $column_name, (%option)) >>

DataType functions are as follows.

=over

=item C<bigint>

=item C<binary>

=item C<bit>

=item C<blob>

=item C<char>

=item C<date>

=item C<datetime>

=item C<dec>

=item C<decimal>

=item C<double>

=item C<integer>

=item C<number>

=item C<numeric>

=item C<smallint>

=item C<string>

=item C<text>

=item C<timestamp>

=item C<tinyblob>

=item C<tinyint>

=item C<varbinary>

=item C<varchar>

=item C<float>

=item C<real>

=item C<enum>

=item C<set>

=back

=head3 C<< primary_key($column_name :Str, (%option :Optional)) >>

Same as C<< column($column_name, 'integer', primary_key => 1, auto_increment => 1, (%option)) >>

=head3 C<< pk($column_name :Str, (%option :Optional)) >>

Alias of C<< primary_key >> .

=head4 C<< %option >> arguments

Specify column using C<< %option >> hash.

    integer 'id', primary_key => 1, default => 0;

Each keyword has mapping to argument for SQL::Translator::Schema::Field.

mappings are:

    null           => 'is_nullable',
    size           => 'size',
    limit          => 'size',
    default        => 'default_value',
    unique         => 'is_unique',
    primary_key    => 'is_primary_key',
    auto_increment => 'is_auto_increment',
    unsigned       => {extra => {unsigned => 1}},
    on_update      => {extra => {'on update' => 'hoge'}},
    precision      => 'size[0]',
    scale          => 'size[1]',

=head4 Syntax sugars for C<< %option >>

There are syntax sugar functions for C<< %option >>.

=over

=item C<< primary_key() >>

    ('primary_key' => 1)

=item C<< pk() >>

Alias of primary_key.

=item C<< unique() >>

    ('unique' => 1)

=item C<< auto_increment() >>

    ('auto_increment' => 1)

=item C<< unsigned() >>

    ('unsigned' => 1)

=item C<< signed() >>

    ('unsigned' => 0)

=item C<< null() >>

    ('null' => 1)

=item C<< not_null() >>

    ('null' => 0)

=back

=head2 Export Functions for declaring primary_key and indices

=head3 C<< set_primary_key(@columns) >>

Set primary key. This is useful for multi column primary key.
Do not need to call this function when primary_key column already declared.

=head3 C<< add_index($index_name :Str, $colums :ArrayRef, ($index_type :Str(default 'NORMAL')) ) >>

Add index.

=head3 C<< add_unique_index($index_name :Str, $colums :ArrayRef) >>

Same as C<< add_index($index_name, $columns, 'UNIQUE') >>

=head2 Export Functions for declaring foreign keys

=head3 C<< foreign_key($columns :(Str|ArrayRef), $foreign_table :Str, $foreign_columns :(Str|ArrayRef) ) >>

Add foreign key.

=head3 C<< fk(@_) >>

Alias of C<< foreign_key(@_) >>

=head3 Foreign key sugar functions

=over

=item C<< has_many($foreign_table) >>

=item C<< has_one($foreign_table) >>

=item C<< belongs_to($foreign_table) >>

=back

=head2 Export Class Methods

=head3 C<< output() :Str >>

Output schema DDL.

=head3 C<< no_fk_output() :Str >>

Output schema DDL without FOREIGN KEY constraints.

=head3 C<< translate_to($database_type :Str) :Any >>

Output schema DDL of C<< $database_type >>.

=head3 C<< translator() :SQL::Translator >>

Returns SQL::Translator object.

=head3 C<< context() :DBIx::Schema::DSL::Context >>

=head1 DEPENDENCIES

Perl 5.8.1 or later.

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 SEE ALSO

L<perl>

=head1 AUTHOR

Masayuki Matsuki E<lt>y.songmu@gmail.comE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2013, Masayuki Matsuki. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
