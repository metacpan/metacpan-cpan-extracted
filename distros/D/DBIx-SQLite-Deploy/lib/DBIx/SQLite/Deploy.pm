package DBIx::SQLite::Deploy;

use warnings;
use strict;

=head1 NAME

DBIx::SQLite::Deploy - Easy SQLite deployment

=head1 VERSION

Version 0.011

=cut

our $VERSION = '0.011';

=head1 SYNOPSIS

    # ::Deploy will create the 'path/to' for you if it does not already exist
    my $deploy = DBIx::SQLite::Deploy->deploy( path/to/database.sqlite => <<_END_ )
    [% PRIMARY_KEY = "INTEGER PRIMARY KEY AUTOINCREMENT" %]
    [% KEY = "INTEGER" %]
    [% CLEAR %]
    ---
    CREATE TABLE artist (

        id                  [% PRIMARY_KEY %],
        uuid                TEXT NOT NULL,

        name                TEXT,
        description         TEXT,

        UNIQUE (uuid)
    );
    ---
    CREATE TABLE cd (

        id                  [% PRIMARY_KEY %],

        title               TEXT,
        description         TEXT
    );
    _END_

To use with DBI

    $dbh = $deploy->connect 

    # ...or the long way:

    $dbh = DBI->connect( $deploy->information )

To use with L<DBIx::Class>

    $schema = My::Schema->connect( $deploy->information )

=head1 DESCRIPTION

DBIx::SQLite::Deploy is a tool for creating a database and getting back a DBI connection in as little work as possible. Essentially, you pass the path
of your database and the schema (as a Template Toolkit template) to C<< DBIx::SQLite::Deploy->deploy >>. If the database is not there (file does not exist or is size 0), then
::Deploy will create the database and install the schema

=head1 Why Template Toolkit?

Purely as a convenience. You probably have lots of repetition in your schema, and TT gives a way to combat that redundancy. You don't need to use it if you don't want/need to.

=head1 USAGE

=head2 $deploy = DBIx::SQLite::Deploy->deploy( <path>, [ <schema> ], ... )

Create a new deployment using <path> as the file for the SQLite database, and <schema> as the (optional) schema

The schema argument can be in the form of a Template Toolkit document.

The database will NOT be created until you ask to C<< ->connect >>, ask for C<< ->information >>, or manually C<< ->deploy >>. To do creation on construction, pass
C<< create => 1 >> as an argument

DBIx::SQLite::Deploy will not deploy over an existing database (the file exists and has non-zero size)

=head2 $deploy->connect

Return a L<DBI> database handle (C<$dbh>)

=head2 $deploy->information

=head2 $deploy->info

Return a list of connection information, suitable for passing to C<< DBI->connect >>

=head2 $deploy->deploy

Deploy the database unless it already exists

=cut

use Moose;
use DBIx::SQLite::Deploy::Carp;

has schema_parser => qw/is ro lazy_build 1/;
sub _build_schema_parser {
    require SQL::Script;
    return SQL::Script->new( split_by => qr/\n\s*-{2,4}\n/ );
};

has tt => qw/is ro lazy_build 1/;
sub _build_tt {
    require Template;
    return Template->new({});
};

has schema => qw/is ro/;
has connection => qw/is ro required 1/;

sub _deploy {
    my $class = shift;
    my ($connection, $schema) = (shift, shift);
    my %given = @_;
    @given{qw/ connection schema /} = ( $connection, $schema );

    $connection = DBIx::SQLite::Deploy::Connection->parse( delete $given{connection} );

    my $create = delete $given{create};
    my $deploy = $class->new( connection => $connection, %given );
    $deploy->deploy if $create;
    return $deploy;
}

sub deploy {
    return shift->_deploy( @_ ) unless ref $_[0];
    my $self = shift;

    my $connection = $self->connection;

    if ( my $schema = $self->schema ) {

        unless ( $connection->database_exists ) {
            {
                my $input = $schema;
                my $output;
                $self->tt->process( \$input, {}, \$output ) or die $self->tt->error;
                $schema = $output;
            }
            $self->schema_parser->read( \$schema );
            my @statements = $self->schema_parser->statements;
            {
                my $dbh = $connection->connect;
                for my $statement ( @statements ) {
                    chomp $statement;
                    $dbh->do( $statement ) or die $dbh->errstr;
                }
                $dbh->disconnect;
            }
        }
    }

    $connection->disconnect; # TODO huh?

    return $connection->information;
}

sub information {
    my $self = shift;
    my %given = @_;
    $given{deploy} = 1 unless exists $given{deploy};
    $self->deploy if $given{deploy};
    return $self->connection->information;
}

sub info {
    return shift->information( @_ );
}

sub connect {
    my $self = shift;
    my %given = @_;
    $given{deploy} = 1 unless exists $given{deploy};
    $self->deploy if $given{deploy};
    return $self->connection->connect;
}

1;

package DBIx::SQLite::Deploy::Connection;

use strict;
use warnings;

use Moose;
use DBIx::SQLite::Deploy::Carp;

has [qw/ source database username password attributes /] => qw/is ro/;
has handle => qw/ is ro lazy_build 1 /;
sub _build_handle {
    my $self = shift;
    return $self->connect;
}

sub dbh {
    return shift->handle;
}

sub open {
    return shift->handle;
}

sub close {
    my $self = shift;
    if ( $self->{handle} ) {
        $self->handle->disconnect;
        $self->meta->get_attribute( 'handle' )->clear_value( $self );
    }
}

sub disconnect {
    my $self = shift;
    return $self->close;
}

sub connect {
    my $self = shift;
    require DBI;
    return DBI->connect( $self->information );
}

before connect => sub {
    require Path::Class;
    my $self = shift;
    my $database = Path::Class::Dir->new( $self->database );
    $database->parent->mkpath unless -d $database->parent;
};

sub connectable {
    my $self = shift;

    my ($source, $username, $password, $attributes) = $self->information;
    $attributes ||= {};
    $attributes->{$_} = 0 for qw/PrintWarn PrintError RaiseError/;
    my $dbh = DBI->connect($source, $username, $password, $attributes);
    my $success = $dbh && ! $dbh->err && $dbh->ping;
    $dbh->disconnect if $dbh;
    return $success;
}


sub database_exists {
    my $self = shift;
    return -f $self->database && -s _ ? 1 : 0;
}

sub parse {
    my $class = shift;
    my $given = shift;

    my ( $database, $attributes );
    if ( ref $given eq "ARRAY" ) {
        ( $database, $attributes ) = @{ $given };
    }
    elsif ( ref $given eq "HASH" ) {
        ( $database, $attributes ) = @{ $given }{qw/ database attributes /};
    }
    elsif ( blessed $given && $given->isa( __PACKAGE__ ) ) {
        return $given;
    }
    elsif ( $given ) {
        $database = $given;
    }
    else {
        croak "Don't know what to do with @_";
    }

    my $source = "dbi:SQLite:dbname=$database";

    return $class->new( source => $source, database => $database, attributes => $attributes );
}

sub information {
    my $self = shift;
    my @information = ( $self->source, $self->username, $self->password, $self->attributes );
    return wantarray ? @information : \@information;
}

1;

=head1 SYNOPSIS

=head1 AUTHOR

Robert Krimen, C<< <rkrimen at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-dbix-sqlite-deploy at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=DBIx-SQLite-Deploy>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc DBIx::SQLite::Deploy


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=DBIx-SQLite-Deploy>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/DBIx-SQLite-Deploy>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/DBIx-SQLite-Deploy>

=item * Search CPAN

L<http://search.cpan.org/dist/DBIx-SQLite-Deploy/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Robert Krimen, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of DBIx::SQLite::Deploy
