package DBICx::TestDatabase;
use strict;
use warnings;

use File::Temp 'tempfile';

our $VERSION = '0.05';

# avoid contaminating the schema with the tempfile
my @TMPFILES;

sub new {
    my ($class, $schema_class, $opts) = @_;

    eval "require $schema_class"
      or die "failed to require $schema_class: $@";

    my $filename = ':memory:'; # use in-memory database

    if($ENV{DBIC_KEEP_TEST}){
        (undef, $filename) = tempfile;
        push @TMPFILES, $filename;
    }

    my $schema = $schema_class->connect( "DBI:SQLite:$filename", '', '',
        { sqlite_unicode => 1 } )
        or die "failed to connect to DBI:SQLite:$filename ($schema_class)";

    $schema->deploy unless $opts->{nodeploy};
    return $schema;
}

END {
    if($ENV{DBIC_KEEP_TEST}){
        print {*STDERR} "Keeping DBICx::TestDatabase databases: @TMPFILES\n";
    }
}

*connect = *new;

1;

__END__

=head1 NAME

DBICx::TestDatabase - create a temporary database from a DBIx::Class::Schema

=head1 SYNOPSIS

Given a L<DBIx::Class::Schema|DBIx::Class::Schema> at C<MyApp::Schema>,
create a test database like this:

   use DBICx::TestDatabase;
   my $schema = DBICx::TestDatabase->new('MyApp::Schema');

Then you can use C<$schema> normally:

   $schema->resultset('Blah')->create({ blah => '123' });

When your program exits, the temporary database will go away.

=head1 DESCRIPTION

This module creates a temporary SQLite database, deploys your DBIC
schema, and then connects to it.  This lets you easily test your DBIC
schema.  Since you have a fresh database for every test, you don't
have to worry about cleaning up after your tests, ordering of tests
affecting failure, etc.

=head1 METHODS

=head2 new($schema)

Loads C<$schema> and returns a connection to it.

=head2 connect

Alias for new.

=head1 ENVIRONMENT

You can control the behavior of this module at runtime by setting
environment variables.

=head2 DBIC_KEEP_TEST

If this variable is true, then the test database will not be deleted
at C<END> time.  Instead, a message containing the paths of the test
databases will be printed.

This is good if you want to look at the database your test generated,
for debugging.

(Note that the database will never exist on disk if you don't set this
to a true value.)

=head1 AUTHOR

Jonathan Rockway C<< <jrockway@cpan.org> >>

=head1 LICENSE

Copyright (c) 2007 Jonathan Rockway.

This program is free software.  You may use, modify, and redistribute
it under the same terms as Perl itself.

