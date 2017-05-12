package AxKit::App::TABOO::Data::Article;
use strict;
use warnings;
use Carp;
use Encode;


use Data::Dumper;
use AxKit::App::TABOO::Data;
use vars qw/@ISA/;

@ISA = qw(AxKit::App::TABOO::Data);
use AxKit::App::TABOO::Data::User;
use AxKit::App::TABOO::Data::Category;
use AxKit::App::TABOO::Data::MediaType;
use AxKit::App::TABOO::Data::Plurals::Users;
use AxKit::App::TABOO::Data::Plurals::Categories;
use Time::Piece;
use MIME::Types;

use DBI;


our $VERSION = '0.3';


=head1 NAME

AxKit::App::TABOO::Data::Article - Article Data object for TABOO

=head1 SYNOPSIS

  use AxKit::App::TABOO::Data::Article;
  [etc ... similar as for other Data objects]

=head1 DESCRIPTION

This Data class contains an mainly metadata for an article. These
articles are of a more static nature than typical news stories.

=head1 METHODS

This class implements several methods, reimplements the load method,
but inherits some from L<AxKit::App::TABOO::Data>.

=over

=item C<new(@dbconnectargs)>

The constructor. Nothing special.

=cut

AxKit::App::TABOO::Data::Article->dbtable("articles");
AxKit::App::TABOO::Data::Article->dbfrom("articles JOIN languages ON (languages.ID = articles.lang_ID) JOIN mediatypes ON (mediatypes.ID = articles.format_ID)");
AxKit::App::TABOO::Data::Article->dbprimkey("filename");
AxKit::App::TABOO::Data::Article->elementorder("filename, lang, primcat, seccat, freesubject, editorok, authorok, title, description, AUTHORS, date, publisher, type, format, coverage, rights");


sub new {
    my $that  = shift;
    my $class = ref($that) || $that;
    my $self = {
		filename  => undef,
		primcat => undef,
		seccat => [],
		freesubject => [],
		angles => [],
		authorok => undef,
		editorok => undef,
		title => undef,
		description => undef,
		publisher => undef,
		date => undef,
		type => undef,
		format => undef,
		lang => undef,
		coverage => undef,
		rights => [],
		authorids => [],
		AUTHORS => undef,
		DBCONNECTARGS => \@_,
		XMLELEMENT => 'article',
		XMLPREFIX => 'art',
		XMLNS => 'http://www.kjetil.kjernsmo.net/software/TABOO/NS/Article/Output',
		ONFILE => undef,
	       };
    bless($self, $class);
    return $self;
}


=item C<load(what =E<gt> fields, limit =E<gt> {filename =E<gt> value, primcat =E<gt> value, [...]})>

This is a reimplementation of the load method, see the parent class
for details. It needs to get the category and user information, which
is not currently done very rigorously and will happen regardless of
the C<what> parameter. In the current implementation, C<filename> is
sufficient to identify an article uniquely, that may change in the
future, so you may want to supply C<primcat> too.

=cut

sub load
{
  my ($self, %args) = @_;
  my $what = $args{'what'} || '*';
  if ($what eq '*') {
    $what = 'articles.ID,articles.filename,articles.authorok,articles.editorok,articles.title,articles.description,articles.publisher,articles.date,articles.type,articles.identifieruri,articles.identifierurn,articles.coverage,articles.rights,mediatypes.mimetype,languages.code';
  }
  $args{'what'} = $what;
  my $data = $self->_load(%args);
  warn Dumper($data);
  return undef unless ($data);
  ${$self}{'ONFILE'} = 1;
  my $dbh = DBI->connect($self->dbconnectargs());
  # TODO: check 'what'
  my $categories = $dbh->selectall_arrayref("SELECT categories.catname, articlecats.field FROM categories JOIN articlecats ON (categories.ID = Cat_ID) JOIN articles ON (articlecats.Article_ID=articles.ID) WHERE articlecats.Article_ID=?", {}, (${$data}{'id'}));

  my $users = $dbh->selectcol_arrayref("SELECT users.username FROM users JOIN articleusers ON (users.ID = Users_ID) JOIN articles ON (articleusers.Article_ID=articles.ID) WHERE articleusers.Article_ID=? ORDER BY articleusers.Users_ID", {}, (${$data}{'id'}));

  $self->populate($data,$categories,$users);
  warn Dumper($self);
  return $self;
}

=item C<populate($articles, $categories, $users)>

This class reimplements the C<populate> method and gives it a new
interface. C<$articles> must be a hashref where the keys correspond to
that of the data store. C<categories> must be an arrayref where the
elements contain another arrayref, where the first element is the
C<catname>, i.e. identifier for the category, and the second is the
field type, i.e. whether it is a primary category, free subject words,
etc. C<$users> must contain an arrayref with the C<username>s of the
authors.

=cut


sub populate {
  my $self = shift;
  my $articles = shift;
  my $categories = shift;
  my @keys = grep(/[a-z]+/, keys(%{$self})); # all the lower-case keys
  foreach my $key (@keys) {
    if (defined(${$articles}{$key}) && (${$articles}{$key} =~ m/^\{(\S+)\}$/)) { # Support SQL3 arrays ad hoc
      my @arr = split(/\,/, $1);
      ${$self}{$key} = \@arr;
    } else {
      ${$self}{$key} = Encode::decode_utf8(${$articles}{$key}, Encode::FB_HTMLCREF);
    }
  }
  ${$self}{'authorids'} = shift;
  ${$self}{'lang'} = ${$articles}{'code'};
  ${$self}{'format'} = ${$articles}{'mimetype'};
  foreach my $cat (@{$categories}) {
    if (${$cat}[1] eq 'primcat') {
      ${$self}{'primcat'} = ${$cat}[0];
    } else {
      push(@{${$self}{${$cat}[1]}}, ${$cat}[0]);
    }
  }
  return $self;
}

=item C<save()>

The C<save()> method is reimplemented too, and it works similarly to
that of the parent class, so it is straightforward to use. Note,
however, that it is not able yet to update an existing record.

=cut

sub save {
  my $self = shift;
  my $dbh = DBI->connect($self->dbconnectargs());
  my @fields;
  my $i=0;
  my $catsusers=0;
  foreach my $key (keys(%{$self})) {
    next if ($key =~ m/[A-Z]/); # Uppercase keys are not in db
    next unless defined(${$self}{$key}); # No need to insert something that isn't there
    if (grep(/^$key$/, qw(primcat seccat freesubject angles authorids))) {
      # Needs to be dealt with specially
      $catsusers=1;
      next;
    }
    $key =~ s/^(format|lang)$/$1_id/;
    push(@fields, $key);
    $i++;
  }
  if (($i == 0) && ($catsusers == 0)) {
    carp "No data fields with anything to save";
  } else {
    my $sth;
    my ($articleid) = $dbh->selectrow_array("SELECT id FROM articles WHERE filename=?", {}, ${$self}{'filename'});
    if ($articleid) {
      die "Updating articles not yet implemented. Filename ${$self}{'filename'} exists";
    } else {
      ($articleid) = $dbh->selectrow_array("SELECT NEXTVAL('articles_id_seq')");
      $sth = $dbh->prepare("INSERT INTO articles (id, " . join(',', @fields) . ") VALUES (" . '?,' x $i . '?)');
      $sth->bind_param(1, $articleid);
      $i = 2;
      foreach my $key (@fields) {
	my $content = ${$self}{$key};
	if ($key eq 'format_id') {
	  my ($fid) = $dbh->selectrow_array("SELECT id FROM mediatypes WHERE mimetype=?", {}, ${$self}{'format'});
	  croak(${$self}{'format'} . " doesn't exist in database, insert first") unless ($fid);
	  $sth->bind_param($i, $fid);
	} elsif ($key eq 'lang_id') {
	  my ($lid) = $dbh->selectrow_array("SELECT id FROM languages WHERE code=?", {}, ${$self}{'lang'});
	  croak(${$self}{'lang'} . " doesn't exist in database, insert first") unless ($lid);
	  $sth->bind_param($i, $lid);
	} elsif (ref($content) eq '') {
	  $sth->bind_param($i, $content);
	} elsif (ref($content) eq "ARRAY") {
	  # The content is an array, save it as such, ad hoc SQL3 for now.
	  $sth->bind_param($i, "{" . join(',', @{$content}) . "}");
	} else {
	  # Actually, I should never get here, but anyway...:
	  warn "Advanced forms of references aren't implemented meaningfully yet. Don't be surprised if I crash or corrupt something.";
	  $content->save(); # IOW: Panic!! Everybody save yourselves if you can! :-)
	}
	$i++;
      }
      $sth->execute;

      foreach my $catfield (qw(primcat seccat freesubject angles)) {
	if ((ref(${$self}{$catfield}) eq 'ARRAY') && scalar(@{${$self}{$catfield}})) {
	  warn Dumper(($articleid, $catfield, @{${$self}{$catfield}}));
	  $dbh->do("INSERT INTO articlecats (article_id, field, cat_id) SELECT ?,?,id FROM categories WHERE catname IN (?" . ',?' x (scalar(@{${$self}{$catfield}})-1) . ')', {}, ($articleid, $catfield, @{${$self}{$catfield}}));
	} elsif (defined(${$self}{$catfield})) {
	  $dbh->do("INSERT INTO articlecats (article_id, field, cat_id) SELECT ?,?,id FROM categories WHERE catname=?", {}, ($articleid, $catfield, ${$self}{$catfield}));

	}
      }
      $dbh->do("INSERT INTO articleusers (article_id, role_id, enabled, users_id) SELECT ?,1,true,id FROM users WHERE username IN (?" . ',?' x (scalar(@{${$self}{'authorids'}})-1) . ')', {}, ($articleid, @{${$self}{'authorids'}}));
    }
  }
  return $self;
}


=item C<adduserinfo()>

When data has been loaded into an object of this class, it will
contain a string only identifying a user, the authors of the article.
This method will replace those strings with a reference to a
L<AxKit::App::TABOO::Data::User>-object, containing the needed user
information.

=cut

sub adduserinfo {
  my $self = shift;
  my $users = AxKit::App::TABOO::Data::Plurals::Users->new($self->dbconnectargs());
  foreach my $username (@{${$self}{'authorids'}}) {
    my $user = AxKit::App::TABOO::Data::User->new($self->dbconnectargs());
    $user->xmlelement("author");
    $user->load(what => 'username,name', limit => {username => $username});
    $users->Push($user);
  }
  ${$self}{'AUTHORS'} = $users;
  return $self;
}

=item C<addcatinfo()>

Similarly to adding user info, this method will also add category
information, for different types of categories, again by creating a
reference to a L<AxKit::App::TABOO::Data::Category>-object and calling
its C<load>-method with the string from the data loaded by the article
as argument.

=cut

sub addcatinfo {
  my $self = shift;
  my @cattypes = qw(primcat seccat freesubject angles);
  foreach my $cattype (@cattypes) {
#    warn $cattype . ": ". ref(${$self}{$cattype});
    if (ref(${$self}{$cattype}) eq 'ARRAY') {
      my $cats = AxKit::App::TABOO::Data::Plurals::Categories->new($self->dbconnectargs());
      $cats->xmlelement($cattype);
      foreach my $catname (@{${$self}{$cattype}}) {
	my $cat = AxKit::App::TABOO::Data::Category->new($self->dbconnectargs());
	$cat->load(limit => {catname => $catname});
	$cats->Push($cat);
      }
      ${$self}{$cattype} = $cats;
    } elsif (defined(${$self}{$cattype})) {
      my $cat = AxKit::App::TABOO::Data::Category->new($self->dbconnectargs());
      $cat->xmlelement($cattype);
      $cat->load(limit => {catname => ${$self}{$cattype}});
      ${$self}{$cattype} = $cat;
    } else {
      # Actually, this is where we have an empty list
      ${$self}{$cattype} = [];
    }
  }
  
  return $self;
}

=item C<addformatinfo()>

Similarly to adding user info, this method will also add format
(i.e. MIME type) information, for different types of categories, again
by creating a reference to a
L<AxKit::App::TABOO::Data::MediaType>-object and calling its
C<load>-method with the string from the data loaded by the article as
argument.

=cut

sub addformatinfo {
    my $self = shift;
    my $type = AxKit::App::TABOO::Data::MediaType->new($self->dbconnectargs());
    $type->load(limit => {mimetype => ${$self}{'format'}});
    ${$self}{'format'} = $type;
    return $self;
}

=item C<date([$filename|Time::Piece])>

The date method will retrieve or set the date of the
article. If the date has been loaded earlier from the data storage
(for example by the load method), you need not supply any
arguments. If the date is not available, you must supply the
filename  identifier, the method will then load it into
the data structure first.

The date method will return a L<Time::Piece> object with the
requested time information.

To set the date, you must supply a L<Time::Piece> object, the
date is set to the time given by that object.

=cut

sub date {
  my $self = shift;
  my $arg = shift;
  if (ref($arg) eq 'Time::Piece') {
    ${$self}{'date'} = $arg->datetime;
    return $self;
  }
  if (! ${$self}{'date'}) {
    my $filename = shift;
    $self->load(what => 'date', limit => {filename => $arg});
  }
  unless (${$self}{'date'}) { return undef; }
  (my $tmp = ${$self}{'date'}) =~ s/\+\d{2}$//;
  return Time::Piece->strptime($tmp, "%Y-%m-%d");
}


=item C<editorok([($filename)])>

This is similar to the date method in interface, but can't be
used to set the value, only retrieves it. It returns the C<editorok>,
which is a boolean variable that can be used to see if an editor
has approved a article.

It takes arguments like the date method does, and it will return
1 if the article has been approved, 0 if not.


=cut

sub editorok {
  my $self = shift;
  unless (defined(${$self}{'editorok'})) {
    my ($filename) = @_;
    croak "No filename given to editorok and no earlier record" unless ($filename);
    $self->load(what => 'editorok', limit => {filename => $filename});
  }
  return ${$self}{'editorok'};
}

=item C<authorok([($filename)])>

Identical to the C<editorok> method, but will return 1 if the article
has been approved by its I<authors>, 0 if not.

=cut

sub authorok {
  my $self = shift;
  unless (defined(${$self}{'authorok'})) {
    my ($filename) = @_;
    croak "No filename given to authorok and no earlier record" unless ($filename);
    $self->load(what => 'authorok', limit => {filename => $filename});
  }
  return ${$self}{'authorok'};
}

=item C<mimetype>

Will return a L<MIME::Type> object representing the MIME-type of the
content of the article. In the present implementation, that's all it
is does, it can't be used to set the MIME-type, also it has to be
loaded allready before this method is called.

=cut

sub mimetype {
  my $self = shift;
  if (ref(${$self}{'format'}) eq 'MIME::Type') {
    return ${$self}{'format'};
  }
  elsif (ref(${$self}{'format'}) eq 'AxKit::App::TABOO::Data::MediaType') {
    return ${$self}{'format'}->mimetype;
  }
  my $mimetypes = MIME::Types->new(only_complete => 1);
  my MIME::Type $type = $mimetypes->type(${$self}{'format'});
  return $type;
}

=item C<authorids>

Will return an array containing the usernames of the authors of the
article, if they have been loaded.

=cut

sub authorids {
  my $self = shift;
  return @{$self}{'authorids'};
}


=back

=head1 STORED DATA

The data is stored in named fields, and for certain uses, it is good
to know them. If you want to subclass this class, you might want to
use the same names, see the documentation of
L<AxKit::App::TABOO::Data> for more about this.

For those who didn't take my word for that the similarity between the
named fields and column names in the database was a coincidence, well,
too bad. The data of this class is more complex, and so this isn't
true anymore here.

Nevertheless, it isn't less useful to know the names, so here goes:

=over

=item * filename - The filename of the content stored in the file system.

=item * primcat - Primary categorization.

=item * seccat - Secondary categorization, an array.

=item * freesubject - Categorization in free subject terms, an array.

=item * angles - Categorization in different viewing angles, an array.

=item * authorok - If the authors have approved the article for publication, boolean.

=item * editorok - If the editors have approved the article for publication, boolean.

=item * authorids - The usernames of the article's author(s), an array.

=item * title - Title of the article.

=item * description - A description of the article.

=item * publisher - URI (preferably) identifying the publisher.

=item * date - Date of publication.

=item * type - "The nature or genre of the content of the resource."

=item * format - The MIME type of the content.

=item * lang - Natural resource of the content.

=item * coverage - "The extent or scope of the content of the resource."

=item * rights - URIs describing copyright policy, e.g. Creative Commons. 

=back

See L<AxKit::App::TABOO::Data::Category> for more about the different
category types. Also, note that many of these fields are taken from
the terms of the Dublin Core, including some of the labels.


=head1 XML representation

The C<write_xml()> method, implemented in the parent class, can be
used to create an XML representation of the data in the object. The
above names will be used as element names. The C<xmlelement()>,
C<xmlns()> and C<xmlprefix()> methods can be used to set the name of
the root element, the namespace URI and namespace prefix
respectively. Usually, it doesn't make sense to change the defaults,
that are


=over

=item * C<article>

=item * C<http://www.kjetil.kjernsmo.net/software/TABOO/NS/Article/Output>

=item * C<art>

=back

=head1 BUGS/TODO

This class is rather experimental at this point, and has not seen the
same level of testing as the rest of TABOO. The C<save> method needs
the ability to update records, and the C<load> method should check the
C<what> parameter properly.

=head1 FORMALITIES

See L<AxKit::App::TABOO>.

=cut

1;
