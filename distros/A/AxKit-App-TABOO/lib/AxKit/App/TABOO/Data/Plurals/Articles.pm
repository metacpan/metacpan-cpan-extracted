package AxKit::App::TABOO::Data::Plurals::Articles;
use strict;
use warnings;
use Carp;

use Data::Dumper;
use AxKit::App::TABOO::Data;
use AxKit::App::TABOO::Data::Article;
use AxKit::App::TABOO::Data::Plurals;


use vars qw/@ISA/;
@ISA = qw(AxKit::App::TABOO::Data::Plurals);

use DBI;
use Exception::Class::DBI;


our $VERSION = '0.2';

AxKit::App::TABOO::Data::Plurals::Articles->dbtable("articles");
AxKit::App::TABOO::Data::Plurals::Articles->dbfrom("articles JOIN languages ON (languages.ID = articles.lang_ID) JOIN mediatypes ON (mediatypes.ID = articles.format_ID)");
AxKit::App::TABOO::Data::Plurals::Articles->dbprimkey("filename");
AxKit::App::TABOO::Data::Plurals::Articles->elementorder("filename, lang, primcat, seccat, freesubject, editorok, authorok, title, description, AUTHORS, date, publisher, type, format, coverage, rights");


=head1 NAME

AxKit::App::TABOO::Data::Plurals::Articles - Data objects to handle multiple Articles in TABOO

=head1 DESCRIPTION

Often, you want to retrieve many different articles from the data
store, for example all belonging to a certain category. This is a
typical situation where this class shoule be used.

=head2 Methods

=over

=item C<new(@dbconnectargs)>

The constructor. Nothing special.

=cut

sub new {
    my $that  = shift;
    my $class = ref($that) || $that;
    my $self = {
	ENTRIES => [], # Internally, some methods finds it useful that the entries are stored in a array of this name.
	ARTICLE_IDS => [], # This field gets the id numbers of the articles, and is only here.
	DBCONNECTARGS => \@_,
	XMLELEMENT => undef,
	XMLPREFIX => undef,
	XMLNS => undef,
    };
    bless($self, $class);
    return $self;
}


=item C<load(what =E<gt> fields, limit =E<gt> {key =E<gt> value, [...]}, orderby =E<gt> fields, entries =E<gt> number)>

This load method can be used to retrieve a number of entries from a
data store.  It can use named parameters, but has a unique other
possibility too, see below. In named parameters mode, the first
C<what> is used to determine which fields to retrieve. It is a string
consisting of a commaseparated list of fields, as specified in the
data store. The C<limit> argument is to be used to determine which
records to retrieve, these will be combined by logical AND. You may
also supply a C<orderby> argument, which is an expression used to
determine the order of entries returned. Usually, it would be a simple
string with the field name to use, e.g. C<'timestamp'>, but you might
want to append the keyword "C<DESC>" to it for descending
order. Finally, you may supply a C<entries> argument, which is the
maximum number of entries to retrieve.

The other possible use to first use the C<incat> method, see below,
and then you may call this method on the object without any
parameters, and the corresponding articles will be loaded.

It will retrieve the data, and then call C<populate()> for each of the
records retrieved to ensure that the plural data objects actually
consists of an array of L<AxKit::App::TABOO::Data::Article>s. But it
calls the internal C<_load()>-method to do the hard work (and that's
in the parent class).

If there is no data that corresponds to the given arguments, this
method will return C<undef>.



=cut

sub load {
  my ($self, %args) = @_;
  my $what = $args{'what'} || '*';
  my $dbh = DBI->connect($self->dbconnectargs());
  my $articles;
  if ($what eq '*') {
    $what = 'articles.ID,articles.filename,articles.authorok,articles.editorok,articles.title,articles.description,articles.publisher,articles.date,articles.type,articles.identifieruri,articles.identifierurn,articles.coverage,articles.rights,mediatypes.mimetype,languages.code';
  }
  if (scalar(@{${$self}{'ARTICLE_IDS'}})) {
    # Then we allready know what to load, but can use additional constraints
    my $query = "SELECT " . $what . " FROM articles JOIN languages ON (languages.ID = articles.lang_ID) JOIN mediatypes ON (mediatypes.ID = articles.format_ID) WHERE articles.id IN (" . "?, " x (scalar(@{${$self}{'ARTICLE_IDS'}})-1) . "?)";
    my @keys = keys(%{$args{'limit'}});
    if (scalar(@keys) == 1) {
      $query .= " AND " . join("", @keys) . "=?";
    }
    elsif(scalar(@keys) >= 1) {
      $query .= " AND " . join("=? AND ", @keys) . "=?";
    }
    $articles = $dbh->selectall_arrayref($query, {Slice => {}}, (@{${$self}{'ARTICLE_IDS'}}, values(%{$args{'limit'}})));
  } else {
    $articles = $self->_load(%args);
    foreach my $entry (@{$articles}) {
      push(@{${$self}{'ARTICLE_IDS'}}, ${$entry}{'id'});
    }
  }

  return undef unless ((defined($articles) && @{$articles}));
  my $categories = $dbh->selectall_arrayref("SELECT categories.catname, articlecats.field, articles.ID FROM categories JOIN articlecats ON (categories.ID = Cat_ID) JOIN articles ON (articlecats.Article_ID=articles.ID) WHERE articlecats.Article_ID IN (" . "?, " x (scalar(@{${$self}{'ARTICLE_IDS'}})-1) . "?)", {}, @{${$self}{'ARTICLE_IDS'}});
  my $users = $dbh->selectall_arrayref("SELECT users.username, articles.ID FROM users JOIN articleusers ON (users.ID = Users_ID) JOIN articles ON (articleusers.Article_ID=articles.ID) WHERE articleusers.Article_ID IN (" . "?, " x (scalar(@{${$self}{'ARTICLE_IDS'}})-1) . "?) ORDER BY articleusers.Users_ID", {}, @{${$self}{'ARTICLE_IDS'}});

  # Transform the users
  my %userstmp;
  foreach my $userentry (@{$users}) {
    push(@{$userstmp{${$userentry}[1]}}, ${$userentry}[0]);
  }

  # Transform the categories
  my %cattmp;
  foreach my $catentry (@{$categories}) {
    my @tmp = @{$catentry}[0..1];
    push(@{$cattmp{${$catentry}[2]}}, \@tmp);
  }

  foreach my $artentry (@{$articles}) {
    my $article = AxKit::App::TABOO::Data::Article->new($self->dbconnectargs());
    my $id = ${$artentry}{'id'};
    $article->populate($artentry, $cattmp{$id}, $userstmp{$id});
    $article->onfile;
    $self->Push($article);
  }
  return $self;
}


=item C<addcatinfo>

=item C<adduserinfo>

=item C<addformatinfo>

These three methods are implemented in a plurals context, and can be
called on a plurals object just like a singular object. Each entry
will have their data structure extended with user, category and format
information.

=cut


sub addcatinfo {
  my $self = shift;
  foreach my $article (@{${$self}{ENTRIES}}) {
    $article->addcatinfo;
  }
  return $self;
}


sub adduserinfo {
  my $self = shift;
  foreach my $article (@{${$self}{ENTRIES}}) {
    $article->adduserinfo;
  }
  return $self;
}



sub addformatinfo {
  my $self = shift;
  foreach my $article (@{${$self}{ENTRIES}}) {
    $article->addformatinfo;
  }
  return $self;
}

=item C<incat(@catnames)>

Takes as arguments an array containing array names, and will return
the number of articles that has been classified into B<all> those
categories. It will also, internally, store which articles that was,
so that you may call the C<load> method on the object afterwards
without any further arguments to load the articles.

=cut

# After pestering axkit-dahut a lot with the problem this routine is
# supposed to solve, Chris Prather came up with the following
# solution:

sub incat {
  my $self = shift;
  my @catnames = @_;
  my $dbh = DBI->connect($self->dbconnectargs());
  ${$self}{'ARTICLE_IDS'} = $dbh->selectcol_arrayref("SELECT a.article_id FROM articlecats a INNER JOIN categories c ON c.id = a.cat_id WHERE c.catname = ?" . "INTERSECT SELECT a.article_id FROM articlecats a INNER JOIN categories c ON c.id = a.cat_id WHERE c.catname = ?" x (scalar(@catnames)-1), {}, @catnames);
  return scalar(@{${$self}{'ARTICLE_IDS'}})
}


=back

=head1 BUGS/TODO

Not anything particular at the moment...


=head1 FORMALITIES

See L<AxKit::App::TABOO>.

=cut

1;


