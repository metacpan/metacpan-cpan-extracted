# NAME

Data::Generator::FromDDL - Dummy data generator from DDL statements

# SYNOPSIS

    use Data::Generator::FromDDL;

    my $generator = Data::Generator::FromDDL->new({
        ddl => 'CREATE TABLE users (....);',
        parser => 'mysql',
    });
    $generator->generate(100); # Generated data are written to STDOUT.

# DESCRIPTION

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

# METHODS

- **new** - Create a new instance.

        Data::Generator::FromDDL->new(%options);

    Possible options are:

    - ddl => $ddl

        Description of DDL. This option is required.

    - parser => $parser // 'MySQL'

        Parser for ddl. Choices are 'MySQL', 'SQLite', 'Oracle', or 'PostgreSQL'.

    - builder\_class => $builder\_class // 'Data::Generator::FromDDL::Builder::SerialOrder'

        Builder class.

    - include => \[@tables\] // \[\]

        Target tables.

    - exclude => \[@tables\] // \[\]

        Ignored tables.

- **generate** - Generate dummy records.

        $generator->generate($num, $out_fh, $format, $pretty, $bytes_per_sql);

    Arguments are:

    - $num or \\%num

        Number of records generated.

        Or you can also give number of records for each table.

            $num = {all => 20, # 20 records for all tables
                    tables => {
                        users => 10 # 10 records for 'users' table
                        }
                    };

        This is useful for table that has one-to-many relationship with other table.

    - $out\_fh (default: \*STDOUT)

        File handle object to which records are dumped.

    - $format (default: 'sql')

        Output format. Choices are **'sql'** or **'json'**.

    - $pretty (default: false)

        Boolean value whether to print output prettily.

    - $bytes\_per\_sql (default: 1048576(1MB))

        The maximum bytes of bulk insert statement.

        This argument is releated to the MySQL's **'max\_allowed\_packet'** variable which stands for the maximum size of string. It's recommended to suit this argument for your MySQL settings.

        cf. https://dev.mysql.com/doc/refman/5.1/en/server-system-variables.html#sysvar\_max\_allowed\_packet

# COMMAND LINE INTERFACE

The `datagen_from_ddl(1)` command is provided as an interface to this module.

    $ datagen_from_ddl --num=100 --parser=mysql --pretty your_ddl.sql

For more details, please see [datagen\_from\_ddl](https://metacpan.org/pod/datagen_from_ddl)(1).

# CONTRIBUTORS

- Kesin11 (Kenta Kase)

# LICENSE

Copyright (C) Yuuki Furuyama.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Yuuki Furuyama <addsict@gmail.com>
