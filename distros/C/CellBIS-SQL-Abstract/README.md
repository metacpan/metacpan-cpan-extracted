# CellBIS::SQL::Abstract - SQL Query Generator ![linux](https://github.com/CellBIS/CellBIS-SQL-Abstract/workflows/linux/badge.svg)

The purpose of this module is to generate SQL Query. General queries has covered
`insert`, `delete`, `update`, `select`, and **select** with **join** - (`select_join`).
And the additional query has covered to create table

You can use this module for [Mojo::mysql](https://metacpan.org/pod/Mojo::mysql) 
or [DBI](https://metacpan.org/pod/DBI).

## How to Install :
From Source :
```bash
git clone -b v1.3 git@github.com:CellBIS/CellBIS-SQL-Abstract.git
perl Makefile.PL
make && make test
make install && make clean
```

with `cpan` command :

```bash
cpan -i CellBIS::SQL::Abstract
```

with `cpanm` command :

```bash
cpanm CellBIS::SQL::Abstract
```

## Synopsis Module :
```perl
use CellBIS::SQL::Abstract
my $sql_abstract = CellBIS::SQL::Abstract->new;

# For create table SQLite
my $sql_abstract = CellBIS::SQL::Abstract->new(db_type => 'sqlite');

# Create Table
my $table_name = 'my_table_name'; # Table name.
my $col_list = []; # List of column table
my $col_attr = {}; # Attribute column table.

# insert
my $table_name = 'my_table_name'; # Table name.
my $column = []; # List of column in the table (array ref data type)
my $value = []; # Value of column (array ref data type)
$sql_abstract->insert($table_name, $column, $value);

# update
my $table_name = 'my_table_name'; # Table name.
my $column = []; # List of column in the table (array ref data type)
my $value = []; # Value of column (array ref data type)
my $clause = {}; # Clause of SQL Query, like where, order by, group by, and etc.
$sql_abstract->update($table_name, $column, $value, $clause);

# delete
my $table_name = 'my_table_name'; # Table name.
my $clause = {}; # Clause of SQL Query, like where, order by, group by, and etc.
$sql_abstract->delete($table_name, $clause);

# select
my $table_name = 'my_table_name'; # Table name.
my $column = []; # List of column in the table (array ref data type)
my $clause = {}; # Clause of SQL Query, like where, order by, group by, and etc.
$sql_abstract->select($table_name, $column, $clause);

# select_join
my $table_list = []; # List of table. (array ref data type)
my $column = []; # List of column to select. (array ref data type)
my $clause = {}; # Clause of SQL Query.
$sql_abstract->select_join($table_list, $column, $clause);
```

For more information you can see on [CPAN](https://metacpan.org/pod/CellBIS::SQL::Abstract).
