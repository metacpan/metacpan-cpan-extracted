package AxKit::App::TABOO::Data::Story;
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
use AxKit::App::TABOO::Data::Plurals::Categories;
use Time::Piece;

use DBI;


our $VERSION = '0.33';


=head1 NAME

AxKit::App::TABOO::Data::Story - Story Data object for TABOO

=head1 SYNOPSIS

  use AxKit::App::TABOO::Data::Story;
  $story = AxKit::App::TABOO::Data::Story->new(@dbconnectargs);
  $story->load(what => '*', limit => {sectionid => $sectionid, storyname => $storyname});
  $story->adduserinfo();
  $story->addcatinfo();
  $timestamp = $story->timestamp();
  $lasttimestamp = $story->lasttimestamp();
  $story->timestamp($lasttimestamp);

=head1 DESCRIPTION

This Data class contains a story, as posted by the editors of a site. 

=head1 METHODS

This class implements several methods, reimplements the load method,
but inherits some from L<AxKit::App::TABOO::Data>.

=over

=item C<new(@dbconnectargs)>

The constructor. Nothing special.

=cut

AxKit::App::TABOO::Data::Story->dbtable("stories");
AxKit::App::TABOO::Data::Story->dbfrom("stories");
AxKit::App::TABOO::Data::Story->dbprimkey("storyname");
AxKit::App::TABOO::Data::Story->elementorder("storyname, sectionid, image, primcat, seccat, freesubject, editorok, title, minicontent, content, USER, SUBMITTER, linktext, timestamp, lasttimestamp");
AxKit::App::TABOO::Data::Story->elementneedsparse("minicontent, content");

sub new {
    my $that  = shift;
    my $class = ref($that) || $that;
    my $self = {
	storyname  => undef,
	sectionid => undef,
	image => undef,
	primcat => undef,
	seccat => [],
	freesubject => [],
	editorok => undef,
	title => undef,
	minicontent => undef,
	content => undef,
	username => undef,
	USER => undef,
	submitterid => undef,
	SUBMITTER => undef,
	linktext => undef,
	timestamp => undef,
	lasttimestamp => undef,
	DBCONNECTARGS => \@_,
	XMLELEMENT => 'story',
	XMLPREFIX => 'story',
	XMLNS => 'http://www.kjetil.kjernsmo.net/software/TABOO/NS/Story/Output',
	ONFILE => undef,
    };
    bless($self, $class);
    return $self;
}


=item C<load(what =E<gt> fields, limit =E<gt> {sectionid =E<gt> value, storyname =E<gt> value, [...]})>

This class reimplements the load method, to support the fact that some
data may be stored as arrays in the datastore. It shares the API of
the parent class. It is useful to note, however, that there are two
fields that you most likely would want to specify for the common use
of retrieving a specific story:

=over


=item * The C<sectionid> which the story has been posted
to. Typically, this string will be taken directly from the URI. The
use of sections makes it possible to divide the site in different
ways. Sections are a type of
L<category|AxKit::App::TABOO::Data::Category>, specifically C<stsec>,
but they are not intended to be like the C<categ> types. Rather, one
can have sections with "small news", i.e. blatant rip-offs of other
news sites with a few comments added, or longer articles with more
unique content.

=item * C<storyname> is a unique identifier for the story. This too
will typically be derived from the URI directly.

=back

It is of course possible to identify a single story by a completely
different set of parameters, and you can do that too, but it is not a
very common thing to do.


=cut

sub load
{
  my ($self, %args) = @_;
  my $data = $self->_load(%args);
  return undef unless ($data);
  if ($data) { ${$self}{'ONFILE'} = 1; }
  foreach my $key (keys(%{$data})) {
    if (defined(${$data}{$key}) && (${$data}{$key} =~ m/^\{(\S+)\}$/)) { # Support SQL3 arrays ad hoc
      my @arr = split(/\,/, $1);
      ${$self}{$key} = \@arr;
    } else {
      ${$self}{$key} = Encode::decode_utf8(${$data}{$key});
    }
  }
  return $self;
}

=item C<adduserinfo()>

When data has been loaded into an object of this class, it will
contain a string only identifying a user.  This method will replace
those strings (for the user posting the article, and for the submitter
who sent the article to the site) with a reference to a
L<AxKit::App::TABOO::Data::User>-object, containing the needed user
information.

=cut

sub adduserinfo {
    my $self = shift;
    my $user = AxKit::App::TABOO::Data::User->new($self->dbconnectargs());
    $user->xmlelement("user");
    $user->load(what => 'username,name', limit => {username => ${$self}{'username'}});
    ${$self}{'USER'} = $user;
    my $submitter = AxKit::App::TABOO::Data::User->new($self->dbconnectargs());
    $submitter->xmlelement("submitter");
    $submitter->load(what => 'username,name', limit => {username => ${$self}{'submitterid'}});
    ${$self}{'SUBMITTER'} = $submitter;
    return $self;
}

=item C<addcatinfo()>

Similarly to adding user info, this method will also add category
information, for different types of categories, again by creating a
reference to a L<AxKit::App::TABOO::Data::Category>-object and calling
its C<load>-method with the string from the data loaded by the story
as argument.

=cut

sub addcatinfo {
    my $self = shift;
    my $cat = AxKit::App::TABOO::Data::Category->new($self->dbconnectargs());
   # There is only one primary category allowed.
    $cat->xmlelement("primcat");
    $cat->load(what => '*', limit => {catname => ${$self}{'primcat'}});

    ${$self}{'primcat'} = $cat;

    # We allow several secondary categories, so we may get an array to run through. 
#      my $cats = AxKit::App::TABOO::Data::Plurals::Categories->new($self->dbconnectargs());
#      $cats->xmlelement("seccat");
#      foreach my $catname (@{${$self}{'seccat'}}) {
#        my $cat = AxKit::App::TABOO::Data::Category->new($self->dbconnectargs());
#        $cat->load(what => '*', limit => {catname => $catname});
#        $cats->Push($cat);
#      }
#      ${$self}{'seccat'} = $cats;
#      my $frees = AxKit::App::TABOO::Data::Plurals::Categories->new($self->dbconnectargs());
#      $frees->xmlelement("freesubject");
#      foreach my $catname (@{${$self}{'freesubject'}}) {
#        my $cat = AxKit::App::TABOO::Data::Category->new($self->dbconnectargs());
#        $cat->load(what => '*', limit => {catname => $catname});
#        $frees->Push($cat);
#      }
#      ${$self}{'freesubject'} = $frees;

    return $self;
}

=item C<timestamp([($sectionid, $storyname)|Time::Piece])>

The timestamp method will retrieve or set the timestamp of the
story. If the timestamp has been loaded earlier from the data storage
(for example by the load method), you need not supply any
arguments. If the timestamp is not available, you must supply the
sectionid and storyname identifiers, the method will then load it into
the data structure first.

The timestamp method will return a L<Time::Piece> object with the
requested time information.

To set the timestamp, you must supply a L<Time::Piece> object, the
timestamp is set to the time given by that object.

=cut

sub timestamp {
  my $self = shift;
  my $arg = shift;
  if (ref($arg) eq 'Time::Piece') {
    ${$self}{'timestamp'} = $arg->datetime;
    return $self;
  }
  if (! ${$self}{'timestamp'}) {
    my $storyname = shift;
    $self->load(what => 'timestamp', limit => {sectionid => $arg, storyname => $storyname});
  }
  unless (${$self}{'timestamp'}) { return undef; }
  (my $tmp = ${$self}{'timestamp'}) =~ s/\+\d{2}$//;
  return Time::Piece->strptime($tmp, "%Y-%m-%d %H:%M:%S");
}


=item C<lasttimestamp([($sectionid, $storyname)|Time::Piece])>

This does exactly the same as the timestamp method, but instead
returns the lasttimestamp, which is intended to show when anything
connected to the story (which may include comments) last changed.

It may require arguments like the timestamp method does, and it will
return a Time::Piece object.


=cut

sub lasttimestamp {
  my $self = shift;
  my $arg = shift;
  if (ref($arg) eq 'Time::Piece') {
    ${$self}{'lasttimestamp'} = $arg->datetime;
    return $self;
  }
  if (! ${$self}{'lasttimestamp'}) {
    my $storyname = shift;
    $self->load(what => 'lasttimestamp', limit => {sectionid => $arg, storyname => $storyname});
  }
  unless (${$self}{'lasttimestamp'}) { return undef; }
  (my $tmp = ${$self}{'lasttimestamp'}) =~ s/\+\d{2}$//;
  return Time::Piece->strptime($tmp, "%Y-%m-%d %H:%M:%S");
}


=item C<editorok([($sectionid, $storyname)])>

This is similar to the timestamp method in interface, but can't be
used to set the value, only retrieves it. It returns the C<editorok>,
which is a boolean variable that says can be used to see if an editor
has approved a story.

It takes arguments like the timestamp method does, and it will return
1 if the story has been approved, 0 if not.

=cut

sub editorok {
  my $self = shift;
  unless (defined(${$self}{'editorok'})) {
    my ($section, $storyname) = @_;
    $self->load(what => 'editorok', limit => {sectionid => $section, storyname => $storyname});
  }
  return ${$self}{'editorok'};
}


=back

=head1 STORED DATA

The data is stored in named fields, and for certain uses, it is good
to know them. If you want to subclass this class, you might want to
use the same names, see the documentation of
L<AxKit::APP::TABOO::Data> for more about this.

In this class it gets even more interesting, because you may pass a
list of those to the load method. This is useful if you don't want to
load all data, in those cases where you don't need all the data that
the object can hold.

These are the names of the stored data of this class:

=over

=item * storyname - an identifier for the story, a simple word you use
to retrieve the desired object.

=item * sectionid - an identifier for the section, also a simple word
you use to retrieve the desired object.

=item * image - the URL of an image that you want to associate with
the story.

=item * primcat - the primary category. You want to classify the story
into one primary category.

=item * seccat - the secondary categories. May be an array, so you can
classify the story into any number of categories. This may be useful
when you try to find relevant articles but searching along different
paths.

=item * freesubject - free categories. The primary categories are
intended to be controlled vocabularies, whereas free subjects can be
used and created more ad hoc. Also an array, you can have any number
of such categories.

=item * editorok - a boolean variable indicated if an editor has
approved the story for publishing.

=item * title - the main title of the story. 

=item * minicontent - Intended to be used as a summary or introduction
to a story. Typically, the minicontent will be shown on a front page,
where a visitor clicks happily along to read the full story.

=item * content - the full story text.

=item * username - the username of the user who actually does the
posting of hte story. Would usually be an editor.

=item * submitterid - the username of the user who submitted the
article to the site for review and posting.

=item * linktext - "Read More" makes a bad link text. Link texts
should be meaningful when read out of context, and this should contain
such a text.

=item * timestamp - typically the time when the story was posted. See
also the C<timestamp()> method.

=item * lasttimestamp - typically the time when something attached to
the story was last changed, for example when a comment was last
submitted. See also the C<lasttimestamp()> method.

=back

=head1 XML representation

The C<write_xml()> method, implemented in the parent class, can be
used to create an XML representation of the data in the object. The
above names will be used as element names. The C<xmlelement()>,
C<xmlns()> and C<xmlprefix()> methods can be used to set the name of
the root element, the namespace URI and namespace prefix
respectively. Usually, it doesn't make sense to change the defaults,
that are


=over

=item * C<story>

=item * C<http://www.kjetil.kjernsmo.net/software/TABOO/NS/Story/Output>

=item * C<story>

=back

=head1 BUGS/TODO

There is a quirk in the load method. I use SQL3 arrays in the
underlying database, but the database driver doesn't support this. So,
there is a very hackish ad hoc implementation to parse the arrays in
that method. It is in fact the only reason why this class reimplements
the load method. It works partly for reading, but just with L<DBD::Pg>
greater than 1.32.

=head1 FORMALITIES

See L<AxKit::App::TABOO>.

=cut

1;
