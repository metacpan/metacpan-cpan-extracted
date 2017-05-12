package # hide from PAUSE
    DBICTest;

use strict;
use warnings;
use RestTest::Schema;

=head1 NAME

DBICTest - Library to be used by DBIx::Class test scripts.

=head1 SYNOPSIS

  use lib qw(t/lib);
  use DBICTest;
  use Test::More;

  my $schema = DBICTest->init_schema();

=head1 DESCRIPTION

This module provides the basic utilities to write tests against
DBIx::Class.

=head1 METHODS

=head2 init_schema

  my $schema = DBICTest->init_schema(
    no_deploy=>1,
    no_populate=>1,
  );

This method removes the test SQLite database in t/var/DBIxClass.db
and then creates a new, empty database.

This method will call deploy_schema() by default, unless the
no_deploy flag is set.

Also, by default, this method will call populate_schema() by
default, unless the no_deploy or no_populate flags are set.

=cut

sub init_schema {
    my $self = shift;
    my %args = @_;

    my $db_file = "t/var/DBIxClass.db";

    unlink($db_file) if -e $db_file;
    unlink($db_file . "-journal") if -e $db_file . "-journal";
    mkdir("t/var") unless -d "t/var";

    my $dsn = $args{"dsn"} || "dbi:SQLite:${db_file}";
    my $dbuser = $args{"user"} || '';
    my $dbpass = $args{"pass"} || '';

    my $schema;

    my @connect_info = ($dsn, $dbuser, $dbpass, { AutoCommit => 1 });

    if ($args{compose_connection}) {
      $schema = RestTest::Schema->compose_connection(
                  'DBICTest', @connect_info
                );
    } else {
      $schema = RestTest::Schema->compose_namespace('DBICTest')
                                ->connect(@connect_info);
    }

    if ( !$args{no_deploy} ) {
        __PACKAGE__->deploy_schema( $schema );
        __PACKAGE__->populate_schema( $schema ) if( !$args{no_populate} );
    }
    return $schema;
}


sub get_ddl_file {
  my $self = shift;
  my $schema = shift;

  return 't/lib/' . lc($schema->storage->dbh->{Driver}->{Name}) . '.sql';
}

=head2 deploy_schema

  DBICTest->deploy_schema( $schema );

=cut

sub deploy_schema {
    my $self = shift;
    my $schema = shift;

    my $file = shift || $self->get_ddl_file($schema);
    open IN, $file;
    my $sql;
    { local $/ = undef; $sql = <IN>; }
    close IN;
    ($schema->storage->dbh->do($_) || print "Error on SQL: $_\n") for split(/;\n/, $sql);
}


=head2 clear_schema

  DBICTest->clear_schema( $schema );

=cut

sub clear_schema {
    my $self = shift;
    my $schema = shift;

    foreach my $class ($schema->sources) {
      $schema->resultset($class)->delete;
    }
}


=head2 populate_schema

  DBICTest->populate_schema( $schema );

After you deploy your schema you can use this method to populate
the tables with test data.

=cut

sub populate_schema {
    my $self = shift;
    my $schema = shift;

    $schema->populate('Artist', [
        [ qw/artistid name/ ],
        [ 1, 'Caterwauler McCrae' ],
        [ 2, 'Random Boy Band' ],
        [ 3, 'We Are Goth' ],
    ]);

    $schema->populate('CD', [
        [ qw/cdid artist title year/ ],
        [ 1, 1, "Spoonful of bees", 1999 ],
        [ 2, 1, "Forkful of bees", 2001 ],
        [ 3, 1, "Caterwaulin' Blues", 1997 ],
        [ 4, 2, "Generic Manufactured Singles", 2001 ],
        [ 5, 2, "We like girls and stuff", 2003 ],
        [ 6, 3, "Come Be Depressed With Us", 1998 ],
    ]);

    $schema->populate('Tag', [
        [ qw/tagid cd tag/ ],
        [ 1, 1, "Blue" ],
        [ 2, 2, "Blue" ],
        [ 3, 3, "Blue" ],
        [ 4, 5, "Blue" ],
        [ 5, 2, "Cheesy" ],
        [ 6, 4, "Cheesy" ],
        [ 7, 5, "Cheesy" ],
        [ 8, 2, "Shiny" ],
        [ 9, 4, "Shiny" ],
    ]);

    $schema->populate('Producer', [
        [ qw/producerid name/ ],
        [ 1, 'Matt S Trout' ],
        [ 2, 'Bob The Builder' ],
        [ 3, 'Fred The Phenotype' ],
    ]);

    $schema->populate('CD_to_Producer', [
        [ qw/cd producer/ ],
        [ 1, 1 ],
        [ 3, 2 ],
        [ 2, 3 ],
    ]);

    $schema->populate('Track', [
        [ qw/trackid cd  position title last_updated_on/ ],
        [ 4, 2, 1, "Stung with Success"],
        [ 5, 2, 2, "Stripy"],
        [ 6, 2, 3, "Sticky Honey"],
        [ 7, 3, 1, "Yowlin"],
        [ 8, 3, 2, "Howlin"],
        [ 9, 3, 3, "Fowlin", '2007-10-20 00:00:00'],
        [ 10, 4, 1, "Boring Name"],
        [ 11, 4, 2, "Boring Song"],
        [ 12, 4, 3, "No More Ideas"],
        [ 13, 5, 1, "Sad"],
        [ 14, 5, 2, "Under The Weather"],
        [ 15, 5, 3, "Suicidal"],
        [ 16, 1, 1, "The Bees Knees"],
        [ 17, 1, 2, "Apiary"],
        [ 18, 1, 3, "Beehind You"],
    ]);
}

1;
