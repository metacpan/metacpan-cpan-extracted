package DBICx::TestDatabase::Subclass;
use strict;
use warnings;

use File::Temp 'tempfile'; 

sub connect {
    my ($class) = @_;
    
    my (undef, $filename) = tempfile;
    my $schema = $class->next::method("DBI:SQLite:$filename") 
      or die "failed to connect to DBI:SQLite:$filename";
    
    $schema->{_tmpfile} = $filename;
    
    $schema->deploy;
    return $schema;
}

sub DESTROY {
    my ($schema) = @_;
    my $tmpfile = $schema->{_tmpfile};
    unlink $tmpfile;
}

1;

__END__

=head1 NAME

DBICx::TestDatabase::Subclass - a DBICx::TestDatabase you can add your 
own methods to

=head1 SYNOPSIS

Your test database subclass:

   package MyApp::TestDatabase
   use base qw(DBICx::TestDatabase::Subclass MyApp::Schema);

   sub foo { 
      my $self = shift;
      return $self->resultset('Foo')->create({ foo => 'bar' });
   }

Later:

   use MyApp::TestDatabase;
   my $schema = MyApp::TestDatabase->connect;
   my $foo_row = $schema->foo; # MyApp::TestDatabase::foo
   my $bars = $schema->resultset('Bar'); # MyApp::Schema::resultset

=head1 DESCRIPTION

Sometimes DBICx::TestDatabase doesn't give you enough control over the
object returned.  This module lets you create a custom test database
class.

=head1 METHODS

=head2 connect

This method creates the temporary database and returns the connection.
If your subclass needs to change the way connect works, do something like
this:

    sub connect {
        my ($class) = @_;

        say 'This happens before we create the test database.';
        my $schema = $class->next::method;
        say '$schema is the temporary test database';
       
        return $schema;
    }

=head1 SEE ALSO

If you want a simple test database based on a DBIC schema, just use
L<DBICx::TestDatabase|DBICx::TestDatabase>.

=head1 AUTHOR

Jonathan Rockway C<< <jrockway@cpan.org> >>

=head1 LICENSE

Copyright (c) 2007 Jonathan Rockway.

This program is free software.  You may use, modify, and redistribute
it under the same terms as Perl itself.
