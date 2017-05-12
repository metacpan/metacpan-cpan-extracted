# NAME

DBIx::Schema::DSL - DSL for Database schema declaration

# VERSION

This document describes DBIx::Schema::DSL version 0.12.

# SYNOPSIS

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

# DESCRIPTION

This module provides DSL for database schema declaration like ruby's ActiveRecord::Schema.

**THE SOFTWARE IS IT'S IN ALPHA QUALITY. IT MAY CHANGE THE API WITHOUT NOTICE.**

# INTERFACE

## Export Functions

### `database($str :Str)`

Set database type like MySQL, Oracle and so on.
(Optional default 'MySQL')

### `create_database($str :Str)`

Set database name. (Optional)

### `add_table_options(%opt :Hash)`

Set global setting of table->extra for SQL::Translator::Schema::Table

### `default_unsigned()`

Automatically set unsigned when declaring integer columns.
If you want to declare singed columns, using \`singed\` sugar.

### `default_not_null()`

Automatically set not null.
If you want to declare null columns, using \`null\` sugar.

### `create_table($table_name :Str, $columns :CodeRef)`

Declare table.

### `columns { block } :CodeRef`

Declare columns settings of table in block. In fact `columns {...}`
is mostly same as `sub {...}`, so just syntax sugar.

## Export Functions for declaring column

### `column($column_name :Str, $data_type :Str(DataType), (%option :Optional))`

Declare column. It can be called only in create\_table block.

`$data_type` strings (ex. `integer` ) are can be used as a function.

`integer($column_name, (%option))` is same as `column('integer', $column_name, (%option))`

DataType functions are as follows.

- `bigint`
- `binary`
- `bit`
- `blob`
- `char`
- `date`
- `datetime`
- `dec`
- `decimal`
- `double`
- `integer`
- `number`
- `numeric`
- `smallint`
- `string`
- `text`
- `timestamp`
- `tinyblob`
- `tinyint`
- `varbinary`
- `varchar`
- `float`
- `real`
- `enum`
- `set`

### `primary_key($column_name :Str, (%option :Optional))`

Same as `column($column_name, 'integer', primary_key => 1, auto_increment => 1, (%option))`

### `pk($column_name :Str, (%option :Optional))`

Alias of `primary_key` .

#### `%option` arguments

Specify column using `%option` hash.

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

#### Syntax sugars for `%option`

There are syntax sugar functions for `%option`.

- `primary_key()`

        ('primary_key' => 1)

- `pk()`

    Alias of primary\_key.

- `unique()`

        ('unique' => 1)

- `auto_increment()`

        ('auto_increment' => 1)

- `unsigned()`

        ('unsigned' => 1)

- `signed()`

        ('unsigned' => 0)

- `null()`

        ('null' => 1)

- `not_null()`

        ('null' => 0)

## Export Functions for declaring primary\_key and indices

### `set_primary_key(@columns)`

Set primary key. This is useful for multi column primary key.
Do not need to call this function when primary\_key column already declared.

### `add_index($index_name :Str, $colums :ArrayRef, ($index_type :Str(default 'NORMAL')) )`

Add index.

### `add_unique_index($index_name :Str, $colums :ArrayRef)`

Same as `add_index($index_name, $columns, 'UNIQUE')`

## Export Functions for declaring foreign keys

### `foreign_key($columns :(Str|ArrayRef), $foreign_table :Str, $foreign_columns :(Str|ArrayRef) )`

Add foreign key.

### `fk(@_)`

Alias of `foreign_key(@_)`

### Foreign key sugar functions

- `has_many($foreign_table)`
- `has_one($foreign_table)`
- `belongs_to($foreign_table)`

## Export Class Methods

### `output() :Str`

Output schema DDL.

### `no_fk_output() :Str`

Output schema DDL without FOREIGN KEY constraints.

### `translate_to($database_type :Str) :Any`

Output schema DDL of `$database_type`.

### `translator() :SQL::Translator`

Returns SQL::Translator object.

### `context() :DBIx::Schema::DSL::Context`

# DEPENDENCIES

Perl 5.8.1 or later.

# BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

# SEE ALSO

[perl](https://metacpan.org/pod/perl)

# AUTHOR

Masayuki Matsuki <y.songmu@gmail.com>

# LICENSE AND COPYRIGHT

Copyright (c) 2013, Masayuki Matsuki. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
