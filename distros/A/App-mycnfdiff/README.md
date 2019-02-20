# NAME

App::mycnfdiff

# VERSION

version 1.00

# SYNOPSIS

    $ mycnfdiff -d /foo/bar -l my.cnf.1,my.cnf.bak
    $ mycnfdiff -l server1/my.cnf,server2/my.cnf
    $ mycnfdiff -l 'exec:docker run -it percona mysqld --verbose --help,my.ini' 
    $ mycnfdiff -s s2.ini,s3,ini  # read all cnf and ini files in current dir except s2.ini

Files must have .cnf or .ini extension otherwise they will not be parsed by default

To specify particular source without format restriction use -l option. 

If one of source is compiled defaults you can only use -l option

to-do: 

diff in csv format

# DESCRIPTION

By default, it produce two output files

1) common.mycnfdiff with common options

2) diff.mycnfdiff with different options (hash style)

If utility can not write files it will print result to STDOUT and warn user about permissions

# NAME

App::mycnfdiff - compare MySQL server configs. 

Can also compare with compiled defaults (values after reading options)

# OPTIONS

For more info please check mycnfdiff --help

# AUTHOR

Pavel Serikov <pavelsr@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Pavel Serikov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
