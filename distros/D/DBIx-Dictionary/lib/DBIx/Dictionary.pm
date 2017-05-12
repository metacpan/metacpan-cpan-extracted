package DBIx::Dictionary;

=head1 NAME

DBIx::Dictionary - Support for query dictionaries in DBI

=head1 SYNOPSIS
  
  use DBIx::Dictionary;
  
  my $dbh = DBIx::Dictionary->connect(
      $dsn, $user,
      $password,
      {
          DictionaryFile => 'dictionary.ini',
          DictionaryName => 'mysql',
      }
  ) or die DBIx::Dictionary->errstr;
  
  # Will prepare query 'insert' from dictionary
  my $sth = $dbh->prepare('insert')
    or die $dbh->errstr;
  
  $sth->execute(@bind);

=head1 ABSTRACT

The C<DBIx::Dictionary> implements a common practice of database
development called "query dictionary". It makes the programmer's life
easier by adding support to those query dictionaries directly into
L<DBI>.

Instead of add common SQL queries inside a program using heredocs or
concatenating strings, the programmer can put those queries into a
query dictionary and use it all over the application.

This can be also a substitute for underlying smart code, allowing one
to construct applications which can be deployed to different database
queries without relying on heavy logic to maintain the SQL queries
compatible.

With C<DBIx::Dictionary>, one can have a C<mysql>, C<postgre> and
C<oracle> sections with specific queries translated to each database
dialect.

A typical C<dictionary.ini> content, in L<Config::General|Config::General>
format would be like this:

  <Dictionary mysql>
  
      insert <<SQL
          INSERT INTO sometable VALUES (?, ?)
  SQL

  </Dictionary>

  <Dictionary oracle>

      insert <<SQL
          INSERT INTO sometable VALUES (?, ?)
  SQL

  </Dictionary>

Please be advised that it is planned to support more than one
dictionary storage format.

=cut

use warnings;
use strict;

use Carp;
use Config::General;

use base 'DBI';

our $VERSION = '0.01';
our @ISA;

use constant ATTR => 3;

=head1 API

=head2 DBIx::Dictionary

This class provides the necessary glue to add support for query
dictionaries on top of L<DBI|DBI>.

=over 4

=cut

#
# __load_dictionary( $file, $name )
#
# This function loads the given dictionary $file and assure there's a
# section with the given $name.
#
sub __load_dictionary {
    my ( $file, $name ) = @_;

    croak "File '$file' doesn't exist!"
      unless -e $file;

    my $config = Config::General->new(
        -AllowMultiOptions => 'no',
        -ConfigFile        => $file,
    );

    my %config = $config->getall;

    croak "Dictionary '$name' not found!"
      unless exists $config{Dictionary}{$name};

    return $config{Dictionary}{$name};
}

=item connect( $dsn, $username, $password, \%attributes )

This method overloads L<DBI|DBI> C<connect> method. It can parse two
more attributes other than L<DBI|DBI>: C<DictionaryFile> which is a
valid path to some L<Config::General|Config::General> file and
C<DictionaryName> is the section name we want to load. Default value
for C<DictionaryName> is C<default>.


  my $dbh = DBIx::Dictionary->connect(
      $dsn, 
      $username,
      $password,
      {
          DictionaryFile => 'dictionary.ini',
          DictionaryName => 'mysql',
      }
  );

The above example loads the dictionary file C<dictionary.ini> and will
look up the named queries in the section C<mysql>.

C<connect()> can also receive a C<RootClass> attribute as L<DBI>
does. It will load the module, and make C<DBIx::Dictionary::db> and
C<DBIx::Dictionary::st> subclasses of the given C<RootClass> as well.

This is useful for using named placeholders with
L<DBIx::Placeholder::Named>, like:

  my $dbh = DBIx::Dictionary->connect(
      $dsn, 
      $username,
      $password,
      {
          DictionaryFile => 'dictionary.ini',
          RootClass      => 'DBIx::Placeholder::Named',
      }
  );
  
=cut

sub connect {
    my ( $class, @args ) = @_;

    my $dictionary_file;
    my $dictionary_name = 'default';

    if ( $args[ATTR] and ref( $args[ATTR] ) eq 'HASH' ) {
        $dictionary_file = delete $args[ATTR]{DictionaryFile}
          if ( exists $args[ATTR]{DictionaryFile} );
        $dictionary_name = delete $args[ATTR]{DictionaryName}
          if ( exists $args[ATTR]{DictionaryName} );

        if ( exists $args[ATTR]{RootClass} ) {
            my $root_class = delete $args[ATTR]{RootClass};

            # Loads root class
            eval "require $root_class;";

            croak $@ if $@;

            # install user's given RootClass as base class for
            # DBIx::Dictionary, DBIx::Dictionary::db and
            # DBIx::Dictionary::st
            unshift @DBIx::Dictionary::ISA,     $root_class;
            unshift @DBIx::Dictionary::db::ISA, $root_class . "::db";
            unshift @DBIx::Dictionary::st::ISA, $root_class . "::st";
        }
    }

    # what is the purpose of this module if we don't have a dictionary?!
    croak "DictionaryFile attribute is obligatory!"
      unless $dictionary_file;

    my $self = $class->SUPER::connect(@args);

    my $dictionary = __load_dictionary( $dictionary_file, $dictionary_name );
    $self->{private_dbix_dictionary_info}{dictionary} = $dictionary;

    return $self;
}

=back

=cut

package DBIx::Dictionary::db;

=head2 DBIx::Dictionary::db

This is a L<DBI::db|DBI> subclass.

=cut 

use Carp;

use base 'DBI::db';

our @ISA;

=over 4

=item prepare( $query )

C<prepare()> accepts the a query name from dictionary as parameter,
otherwise will assume it is a SQL query.

  my $sth;
  $sth = $dbh->prepare('insert_customer');
  $sth = $dbh->prepare($some_dynamic_query);

On the above example, both C<prepare()> statements should work as
expected.

=cut

sub prepare {
    my ( $dbh, $query_name ) = @_;

    my $query;

    if ( exists $dbh->{private_dbix_dictionary_info}{dictionary}{$query_name} )
    {

        # $query_name is a key on dictionary.
        $query = $dbh->{private_dbix_dictionary_info}{dictionary}{$query_name};
    }
    else {

        # $query_name is not a key on our dictionary, so let's assume
        # it *is* the query.
        $query = $query_name;
    }

    my $sth = $dbh->SUPER::prepare($query)
      or return;

    return $sth;
}

=back

=cut

package DBIx::Dictionary::st;

=head2 DBIx::Dictionary::st

This is a L<DBI::st|DBI> subclass.

=cut

use base 'DBI::st';

our @ISA;

1;

=head1 CAVEATS

=over 4

=item 

C<DBIx::Dictionary> won't work if you use it using the C<RootClass>
attribute with L<DBI|DBI>. It is expect not to work, because when
connecting to database like this:

  my $dbh = DBI->connect(
      $dsn,
      $username,
      $password,
      {
          RootClass => 'DBIx::Dictionary, 
      }
  );

L<DBI|DBI> won't call C<DBIx::Dictionary::connect()>. Calling
C<DBIx::Dictionary::connect()> is important because the dictionary
setup is done there. This can change in the future, but not for now.

=back

=head1 AUTHOR

Copyright (c) 2008, Igor Sutton Lopes C<< <IZUT@cpan.org> >>. All rights
reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<DBI|DBI>, L<Config::General|Config::General>,
L<DBIx::Placeholder::Named|DBIx::Placeholder::Named>
