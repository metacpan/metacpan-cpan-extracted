package DBIx::ParseDSN::Default;

use v5.8.8;

use utf8::all;
use strict;
use autodie;
use warnings;
use Carp qw< carp croak confess cluck >;
use DBI; # will use parse_dsn from here
use URI;

use version; our $VERSION = qv('0.9.3');

use Moo;
use namespace::clean;
use MooX::Aliases;
use MooX::HandlesVia;

has dsn => ( is => "ro", required => 1 );

has database => ( is => "rw", alias => [qw/db dbname/] );
has host     => ( is => "rw", alias => "server" );
has port     => ( is => "rw" );
has driver   => ( is => "rw" );
has scheme   => ( is => "rw", default => "dbi" );

has attr => (
    handles_via => "Hash",
    is => "ro",
    default => sub {{}},
    handles => {
        set_attr => "set",
        get_attr => "get",
        delete_attr => "delete",
        attributes => "elements",
    }
);

around host => sub {

    my $orig = shift;
    my $self = shift;

    return $self->$orig unless my ($host) = @_;

    $host =~ s/^tcp://;

    if ( $host =~ s/:(\d+)// ) {
        $self->port($1);
    }

    return $self->$orig($host);

};

sub names_for_database {
    return (
        qw/database dbname name db/,
        "sid", ## Oracle
        "file name", "initialcatalog", ## from ADO, but generic
                                        ## enough to allow in this
                                        ## module
        );
}
sub names_for_host {
    return qw/host hostname server/;
}
sub names_for_port {
    return qw/port/;
}
sub known_attribute_hash {

    my $self = shift;
    my %h;

    my @db_names = map { lc $_ } $self->names_for_database;
    @h{@db_names} = ("database") x @db_names;

    my @h_names = map { lc $_ } $self->names_for_host;
    @h{@h_names} = ("host") x @h_names;

    my @p_names = map { lc $_ } $self->names_for_port;
    @h{@p_names} = ("port") x @p_names;

    return %h;

}

sub dsn_parts {
    my $self = shift;
    return DBI->parse_dsn( $self->dsn );
}

sub dbd_driver {
    my $self = shift;
    my $driver = "DBD::" . $self->driver;
    return $driver;
}
sub driver_attr {

    my $self = shift;
    my ( $scheme, $driver, $attr, $attr_hash, $dsn ) = $self->dsn_parts;

    return $attr_hash;

}
sub driver_dsn {
    my $self = shift;
    return ($self->dsn_parts)[4];
}

sub is_remote {
    my $self = shift;
    return not $self->is_local
}
sub is_local {
    my $self = shift;

    ## not much the default can do. if database exists as a file we
    ## guess its a file based database and hence local
    if ( defined $self->host and
                 (
                 lc $self->host eq "localhost" or
                    $self->host eq "127.0.0.1"
                 )
         ) {
        return 1;
    }
    elsif ( -f $self->database ) {
        return 1;
    }

    confess "Cannot determine if db is local";

}

sub parse {

    ## look for the following in the driver dsn:
    ## 1: database: database dbname name db
    ## 2: host:     hostname host server
    ## 3: port:     port

    ## Assumes ";"-separated parameters in driver dsn
    ## If driver dsn is one argument, its assumed to be the database

    my $self = shift;

    $self->driver( ($self->dsn_parts)[1] );

    my @pairs = split /;/, $self->driver_dsn;

    my %known_attr = $self->known_attribute_hash;

    for (@pairs) {

        my($k,$v) = split /=/, $_, 2;

        ## An Oracle special case that would otherwise mess things up
        if ( $self->driver eq "Oracle" and $k eq "SERVER" ) {
            ## example: SERVER=POOLED
            next;
        }

        ## a //foo:xyz/bar type of uri, like Oracle
        if ( $k =~ m|^//.+/.+| and not defined $v and @pairs == 1 ) {

            ## For this we offer something that works with oracle
            my $u = URI->new;
            $u->opaque($k);

            my @p = $u->path_segments;

            ## 2nd part of path is database
            if ( $p[1] ) {
                $self->database($p[1]);
            };

            ## host should be ok
            if ( my $host = $u->authority ) {

                ## might contain port
                if ( $host =~ s/:(\d+)// ) {
                    $self->port($1);
                }

                $self->host( $host );

            }

        }
        elsif (not defined $v and @pairs == 1) {
            $self->database($k);
        }

        if ( my $known_attr = $known_attr{lc $k} ) {
            $self->$known_attr( $v );
        }

        $self->set_attr($k, $v);

    }

    ## Another Oracle speciality, strip ":POOLED" from db
    if ( $self->driver eq "Oracle" and
             ( my $new_db = $self->database ) =~ s/:POOLED$// ) {
        $self->database($new_db);
    }

}

## intercept constructor to allow 1st arg DSN and 2nd arg user string,
## which may contain db name
around BUILDARGS => sub {

    my $orig = shift;
    my $class = shift;

    my @args = @_;

    ## if first arg is a hash, work with that, otherwise start a new
    ## empty hash
    my %h = %{ ref $args[0] eq "HASH" ? $args[0] : {} };

    ## 1st arg can be dsn if not a hash
    if ( defined $args[0] and ref $args[0] ne "HASH" ) {
        $h{dsn} = $args[0];
    }
    ## look for db in user string - will not override one found in dsn
    if ( defined $args[1] ) {
        if ( $args[1] =~ /@(.+)$/ ) {
            (my $db = $1) =~ s|/.*||;
            $h{database} = $db;
        }
    }

    return $class->$orig(\%h)

};

sub BUILD {};

## call parse after build
after BUILD => sub {
    my $self = shift;
    $self->parse;
};

1; # Magic true value required at end of module
__END__

=encoding utf8

=head1 NAME

DBIx::ParseDSN::Default - A default DSN parser, moose based. You can
use this as is, or subclass it. DBIx::ParseDSN uses this class unless
it finds a better parser.

It can be used directly to parse a DSN, but use instead
L<DBIx::ParseDSN/parse_dsn> which is the intended way to achieve this.

=head1 VERSION

This document describes DBIx::ParseDSN::Default version 0.9.3

=head1 SYNOPSIS

    ## Use it directly:

    use DBIx::ParseDSN::Default;

    my $dsn = DBIx::ParseDSN::Default->new( "dbi:Foo:/bar/baz" );

    ## Subclass:
    {
      package DBIx::ParseDSN::OddBall;

      use Moo;
      extends 'DBIx::ParseDSN::Default';

      sub names_for_database{ return qw/bucket/ }

    }

    package main;

    use DBIx::ParseDSN;

    my $dsn = parse_dsn( "dbi:OddBall:bucket=foo" )

    $dsn->database; ## "foo"

=head1 DESCRIPTION

This is a default DSN parser. It is not specific to any driver. It can
safely be used as a base for driver specfic parsers.

It handles the most common database drivers. See test files for
details.

=head1 DSN ATTIRIBUTES

=head2 database

=head2 dbname

=head2 db

Database attribute of the DSN. See L</names_for_database>.

=head2 host

=head2 server

Server address of the connection. If any. See L</names_for_host>.

=head2 port

Port to connect to on the server. See L</names_for_port>

=head1 OTHER METHODS

=head2 parse( $dsn )

A method used internally. Parses the DSN.

=head2 driver_attr

Any attributes to the driver, ie foo=bar in
dbi:SQLite(foo=bar):db.sqlite. See L<DBI/parse_dsn>.

=head2 driver_dsn

The 3rd part of the dsn string which is driver specific.

=head2 dsn_parts

The 5 values returned by DBI->parse_dsn

=head2 is_local

True if the dsn is local. File based db drivers are local, and network
connections to localhost or 127.0.0.1 are local.

=head2 is_remote

The oposite of is_local

=head2 names_for_database

Name variations for the database attribute. This class uses
qw/database dbname db/.

=head2 names_for_host

Name variations for the host attribute. This class uses qw/host
server/.

=head2 names_for_port

Name variations for the port attribute. This class uses C<port>. This
is included for completeness to follow the pattern used for
C<database> and C<host> but is likely never to be anything other than
just C<port>.

=head2 known_attribute_hash

Combines information for the three above methods to compose a hash
useful for translating names, eg:

    (
      database => "database",
      dbname   => "database",
      db       => "database",
      server   => "host",
      hostname => "host",
    )

This method is mainly for internal use.

=head2 dbd_driver

The perl module driver for this specific dsn. Currently the 2nd value
of the dsn string prefixed by DBD:: , ie DBD::SQLite.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-bug-dbix-parsedsn::parser::default@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 SEE ALSO

L<DBIx::ParseDSN>

=head1 AUTHOR

Torbjørn Lindahl  C<< <torbjorn.lindahl@gmail.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2014, Torbjørn Lindahl C<< <torbjorn.lindahl@gmail.com> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
