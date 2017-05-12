#-----------------------------------------------------------------
# App::Cmdline::Options::DB
# Author: Martin Senger <martin.senger@gmail.com>
# For copyright and disclaimer see the POD.
#
# ABSTRACT: set of database-related options for command-line applications
# PODNAME: App::Cmdline::Options::DB
#-----------------------------------------------------------------
use warnings;
use strict;

package App::Cmdline::Options::DB;

our $VERSION = '0.1.2'; # VERSION

my @OPT_SPEC = (
    [ 'dbname=s'   => "database name"                                            ],
    [ 'dbhost=s'   => "hostname hosting database",    { default => 'localhost' } ],
    [ 'dbport=i'   => "database port number",         { default => 3306 }        ],
    [ 'dbuser=s'   => "user name to access database", { default => 'reader' }    ],
    [ 'dbpasswd=s' => "password to access database"                              ],
    [ 'dbsocket=s' => "UNIX socket accessing the database"                       ],
    );

# ----------------------------------------------------------------
# Return definition of my options
# ----------------------------------------------------------------
sub get_opt_spec {
    return @OPT_SPEC;
}

1;


=pod

=head1 NAME

App::Cmdline::Options::DB - set of database-related options for command-line applications

=head1 VERSION

version 0.1.2

=head1 SYNOPSIS

   # In your module that represents a command-line application:
   sub opt_spec {
       my $self = shift;
       return $self->check_for_duplicates (
           [ 'check|c' => "only check the configuration"  ],
           ...,
           $self->composed_of (
               'App::Cmdline::Options::DB',     # here are the database options added
               'App::Cmdline::Options::Basic',  # here may be other options
           )
       );
    }

=head1 DESCRIPTION

This is a kind of a I<role> module, defining a particular set of
command-line options and their validation. See more about how to write
a module that represents a command-line application and that uses this
set of options in L<App::Cmdline>.

=head1 OPTIONS

Particularly, this module specifies the database-related options,
allowing to define what database to access and how to authenticate the
access. It is particularly well suited for the MySQL DBI access.

    [ 'dbname=s'   => "database name"                                            ],
    [ 'dbhost=s'   => "hostname hosting database",    { default => 'localhost' } ],
    [ 'dbport=i'   => "database port number",         { default => 3306 }        ],
    [ 'dbuser=s'   => "user name to access database", { default => 'reader' }    ],
    [ 'dbpasswd=s' => "password to access database"                              ],
    [ 'dbsocket=s' => "UNIX socket accessing the database"                       ],

=head2 --dbname

It specifies the database name. No default value.

=head2 --dbhost

It specifies the computer name (or its IP address) where is the
database. Default value is C<localhost>.

=head2 --dbport

It is an integer, specifying a port number where the database is
listening. Default value is 3306 (suited for MySQL).

=head2 --dbuser

It specifies a user name to access this database. Default value is
C<reader>,

=head2 --dbpasswd

It specifies a database password for the given user. No default value.

=head2 --dbsocket

It specifies a UNIX socket file name (such as F</tmp/mysqld.sock>). No
default value.

=head1 AUTHOR

Martin Senger <martin.senger@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Martin Senger, CBRC - KAUST (Computational Biology Research Center - King Abdullah University of Science and Technology) All Rights Reserved.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

