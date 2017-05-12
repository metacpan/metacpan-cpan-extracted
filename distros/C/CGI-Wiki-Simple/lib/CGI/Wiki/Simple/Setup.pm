package CGI::Wiki::Simple::Setup;

use strict;

use CGI::Wiki;
use CGI::Wiki::Simple;
use Carp qw(croak);
use Digest::MD5 qw( md5_hex );

use vars qw($VERSION);

$VERSION = '0.11';

=head1 NAME

CGI::Wiki::Simple::Setup - Set up the wiki and fill content into some basic pages.

=head1 DESCRIPTION

This is a simple utility module that given a database sets up a complete wiki within it.

=head1 SYNOPSIS

=for example begin

  setup( dbtype => 'sqlite', dbname => "mywiki.db" );
  # This sets up a SQLite wiki within the file mywiki.db

  setup( dbtype => 'mysql', dbname => "wiki", dbuser => "wiki", dbpass => "secret", file => 'nodeball.txt' );
  # This sets up a MySQL wiki and loads the nodes from the file nodeball.txt

=for example end

=cut

my %stores = (
  sqlite => 'SQLite',
  mysql  => 'MySQL',
  pg     => 'Pg',
);

=head2 C<get_store %ARGS>

C<get_store> creates a store from a hash of parameters. There
are two mandatory parameters  :

  dbtype => 'mysql'

This is the type of the database. Recognized values are C<mysql>,
C<sqlite> and C<pg>.

  dbname => 'wiki'

This is the name of the database.

The remaining parameters are optional :

  dbuser => 'wikiuser'

The database user

  dbpass => 'secret'

The password for the database

  setup => 1

Create the database unless it exists already

  clear => 1

Wipe all nodes from the database before reinitializing
it. Only valid if C<setup> is also true.

  check => 1

Check that a node called C<index> exists. This raises
an error if the database exists but is empty.

=cut

sub get_store {
  my %args = @_;

  my @setup_args;
  my $dbtype;

  push @setup_args, $args{dbname};
  for (qw(dbuser dbpass)) {
    push @setup_args, $args{$_}
      if exists $args{$_};
  };

  $dbtype = $args{dbtype};

  croak "Unknown database type $dbtype"
    unless exists $stores{lc($dbtype)};
  $dbtype = $stores{lc($dbtype)};

  eval "use CGI::Wiki::Store::$dbtype; use CGI::Wiki::Setup::$dbtype";

  if ($args{setup}) {
    no strict 'refs';
    &{"CGI::Wiki::Setup::${dbtype}::cleardb"}(@setup_args)
      if $args{clear};
    &{"CGI::Wiki::Setup::${dbtype}::setup"}(@setup_args);
  };

  # get the wiki store :
  my $store = "CGI::Wiki::Store::$dbtype"->new( %args );
  warn "Couldn't get store for $args{dbname}" unless $store;

  $store->retrieve_node("index")
    if ($args{check});

  return $store;
};

=head2 C<setup %ARGS>

Creates a new database and initializes it. Takes the
same parameters as C<get_store> and two additional
optional parameters :

  nocontent => 1

Prevents loading the three default nodes from the module
into the wiki.

  force => 1

Overwrites nodes with the loaded content even if they
already exists.

=cut

sub setup {
  my %args = @_;

  croak "No dbtype given"
    unless $args{dbtype};

  my $store = get_store( %args, setup => 1 );
  unless ($args{nocontent}) {
    print "Loading content\n"
      unless $args{silent};
    load_nodeball( store => $store, )
  };

  $store->dbh->disconnect;
};

=head2 C<setup_if_needed %ARGS>

Creates a new database and initializes it if no
current database is found. Takes the same arguments
as C<setup>

=cut

sub setup_if_needed {
  my %args = @_;

  my $store;
  eval { $store = get_store( %args, check => 1 ); };
  setup(%args) if $@ or ! $store;
};

=head2 C<load_nodeball>

Loads a nodeball into the wiki. A nodeball is a set of nodes
in a text file like this :

  __NODE__
  Title: TestNode

  This is a test node. It
  consists of content that will be formatted through the
  wiki formatter.

  __NODE__
  Title: AnotherTestNode

  You know it.

The routine takes the following parameters additional
to the usual database parameters :

  fh => \*FILE

Loads the nodeball from the filehandle FILE.

  file => 'nodeball.txt'

Loads the nodeball from the specified file.

=cut

sub load_nodeball {
  my %args = @_;

  if ($args{file}) {
    open F, "<$args{file}"
      or die "Couldn't read nodeball from '$args{file}' : $!\n";
  } elsif ($args{fh}) {
    *F = *{$args{fh}}
  } else {
    *F = *DATA;
  };

  my $store = $args{store} || get_store( %args );

  unless ($args{nocontent}) {
    my $wiki = CGI::Wiki->new(
               store  => $store,
               search => undef );

    my $offset = tell F;
    my @NODES = map {
        /^Title:\s+(.*?)\r?\n(.*)/ms
        ? { title => $1, content => $2 }
        : ()
      } do { undef $/; split /__NODE__/, <F> };
    seek F, $offset, 0;

    commit_content( %args, wiki => $wiki, nodes => \@NODES, );

    undef $wiki;
  };
};

=head2 C<commit_content %ARGS>

Loads a set of nodes into the wiki database. Takes the following
parameters :

  wiki => $wiki

An initialized CGI::Wiki.

  force => 1

Force overwriting existing nodes

  silent => 1

Do not print out normal messages. Warnings still get raised.

  nodes => \@NODES

A reference to an array of hash references. Each element should
have the following structure :

  { title => 'A node title', content => 'Some content' }


=cut

sub commit_content {
  my %args = @_;
  my $wiki = $args{wiki};

  croak "No wiki passed in the 'wiki' parameter"
    unless $wiki;

  my @nodes = @{$args{nodes}};
  foreach my $node (@nodes) {
    my $title = $node->{title};

    my %old_node = $wiki->retrieve_node($title);
    if (not $old_node{content} or $args{force}) {
      my $content = $node->{content};
      $content =~ s/\r\n/\n/g;
      my $cksum = $old_node{checksum};
      my $written = $wiki->write_node($title, $content, $cksum);
      if ($written) {
        print "(Re)initialized node '$title'\n"
          unless $args{silent};
      } else {
        warn "Node '$title' not written\n";
      };
    } else {
      warn "Node '$title' already contains data. Not overwritten.";
    };
  };
};

=head1 COPYRIGHT

     Copyright (C) 2003 Max Maischein.  All Rights Reserved.

This code is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<CGI::Wiki>, L<CGI::Wiki::Simple>

=cut

__DATA__
__NODE__
Title: index
This is the main page of your new wiki. It was preset
by the automatic content setup.

If your wiki will be accessible to the general public, you might want
to make this node read only by loading the [CGI::Wiki::Simple::Plugin::Static]
plugin for this node :

     use CGI::Wiki::Simple::Plugin::Static index => 'Text for the index node';

This node was loaded initially by the setup program among other nodes :

    * [Wiki Howto]
    * [CGI::Wiki::Simple]
__NODE__
Title: Wiki Howto

This is a wiki, things are simple :

    1. Everybody can edit any node.
    2. Linking between nodes is done by putting the text in square brackets.
    3. Lists are created by indenting stuff 4 spaces.
    4. Paragraphs are delimited by an empty line
    5. Dividers are "----"

Some examples :

    * An unordered list

    1. First item
    2. Second item
    3. third item

    a. Another
    b. List

Some normal text. Note that
line
breaks
happen where you type them and where
they seem necessary.

    Some(code);
      in some programming language

[A Link]. [With a different target node|Another link]

Have fun.


__NODE__
Title: CGI::Wiki::Simple

This wiki is powered by CGI::Wiki::Simple (at http://search.cpan.org/search?mode=module&query=CGI::Wiki::Simple ).
CGI::Wiki::Simple was written by Max Maischein (cgi-wiki-simple@corion.net). Please report bugs
through the CPAN RT at http://rt.cpan.org/NoAuth/Bugs.html?Dist=CGI-Wiki-Simple .

CGI::Wiki::Simple again is based on CGI::Wiki (at http://search.cpan.org/search?mode=module&query=CGI::Wiki )
by Kate Pugh.

