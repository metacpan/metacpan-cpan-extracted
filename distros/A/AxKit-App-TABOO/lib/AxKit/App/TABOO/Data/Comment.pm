package AxKit::App::TABOO::Data::Comment;
use strict;
use warnings;
use Carp;

use Data::Dumper;
use AxKit::App::TABOO::Data;
use AxKit::App::TABOO::Data::User;
use AxKit::App::TABOO::Data::Plurals::Comments;
use Encode;

use vars qw/@ISA/;
@ISA = qw(AxKit::App::TABOO::Data);

use DBI;


our $VERSION = '0.095';



=head1 NAME

AxKit::App::TABOO::Data::Comment - Comment Data object for TABOO

=head1 SYNOPSIS

  use AxKit::App::TABOO::Data::Comment;
  $comment = AxKit::App::TABOO::Data::Comment->new();
  $comment->load(limit => {sectionid => $self->{section},
			   storyname => $self->{storyname}});
  $comment->tree;
  $comment->adduserinfo;
  $timestamp = $comment->timestamp();

=head1 DESCRIPTION

This Data class contains a comment, which may be posted by any
registered user of the site. Each object will also contain an
identifier of replies to the comment, that may be replaced with a
reference to another comment object.

=head1 METHODS

This class implements several methods, reimplements the load method,
but inherits some from L<AxKit::App::TABOO::Data>.

=over

=item C<new($self->dbconnectargs())>

The constructor. Nothing special.

=cut

AxKit::App::TABOO::Data::Comment->dbtable("comments");
AxKit::App::TABOO::Data::Comment->dbfrom("comments");
AxKit::App::TABOO::Data::Comment->dbprimkey("commentpath");
AxKit::App::TABOO::Data::Comment->elementneedsparse("content");
AxKit::App::TABOO::Data::Comment->elementorder("commentpath, title, content, timestamp, USER, REPLIES");

sub new {
    my $that  = shift;
    my $class = ref($that) || $that;
    my $self = {
	commentpath => undef,
	storyname => undef,
	sectionid => undef,
	title => undef,
	content => undef,
	timestamp => undef,
	username => undef,
	USER => undef,
	REPLIES => undef,
	DBCONNECTARGS => \@_,
	XMLELEMENT => 'reply',
	XMLPREFIX => 'comm',
	XMLNS => 'http://www.kjetil.kjernsmo.net/software/TABOO/NS/Comment/Output',
	ONFILE => undef,

    };
    bless($self, $class);
    return $self;
}

=item C<load(what =E<gt> fields, limit =E<gt> {key =E<gt> value, [...]}>

The load method is not reimplemented but needs elaboration. It follows
the convention of the load methods of the parent class, but to
uniquely identify a comment, one has to set certain C<limit>s.

First one should identify the story that the comment is attached to,
by giving C<storyname> and C<sectionid>, see
L<AxKit::App::TABOO::Data::Story> for details.

To identify the comment itself, TABOO introduces the concept of a
I<commentpath>. A commentpath is a string that identifies a comment by
appending the username of the poster for each reply posted, separated
by a C</>. In computer science terms, I think this is known as a
I<trie>. Thus, commentpaths will grow as people respond to each
other's comments. For example, if user bar replies to user foo, the
commentpath to bar's comment will be C</foo/bar>. The commenpath will
typically be in the URI of a comment. If the same user post more
replies to a comment, they will be suffixed with e.g. C<_2> for the
second comment.

The C<commentpath>, C<sectionid> and C<storyname> together identifies
a comment.


=item C<adduserinfo()>

When data has been loaded into an object of this class, it will
contain a string only identifying the user who posted the comment.
This method will replace that strings with a reference to a
L<AxKit::App::TABOO::Data::User>-object, containing the needed user
information.

=cut

sub adduserinfo {
  my $self = shift;
  my $user = AxKit::App::TABOO::Data::User->new($self->dbconnectargs());
  $user->load(what => 'username,name', limit => {username => ${$self}{'username'}});
  ${$self}{'USER'} = $user;
  return $self;
}


=item C<reply($comment)>

This method can be used to attach a reply to a comment, or to retrieve
a reply. If no argument is given, it will return the reply object if
it exists. To attach a comment, give an argument which is an instance
of this class or an instance of
L<AxKit::App::TABOO::Data::Plurals::Comments>.

=cut

sub reply {
  my $self = shift;
  if (@_) { 
    my $comments = shift;
    return undef unless (defined($comments));
    croak "The reply object must be a Comment or Comments object" 
      unless ((ref($comments) eq 'AxKit::App::TABOO::Data::Comment') || 
	      (ref($comments) eq 'AxKit::App::TABOO::Data::Plurals::Comments'));
    ${$self}{'REPLIES'} = $comments;
    return $self;
  } else {
    return ${$self}{'REPLIES'};
  }
}

=item C<tree([$what, $orderby])>

This method has changed considerably since earlier releases. You may
call it on any object of this class that has C<commentpath>,
C<sectionid> and C<storyname> defined. It will return an instance of
the L<AxKit::App::TABOO::Data::Plurals::Comments> class consisting of
all comments in the tree with the comment in the object it was called
on as root.

=cut

sub tree {
  my $self = shift;
  my $what = shift;
  my $orderby = shift;
  my $comments = AxKit::App::TABOO::Data::Plurals::Comments->new($self->dbconnectargs());
  return $comments->load(what => $what, 
			 limit => {commentpath => ${$self}{'commentpath'}, 
				   sectionid => ${$self}{'sectionid'}, 
				   storyname=> ${$self}{'storyname'}}, 
			 orderby => $orderby, regex => ['commentpath']);
}


=item C<timestamp([($sectionid, $storyname, $commentpath)|Time::Piece])>

The timestamp method will retrieve or set the timestamp of the
comment. If the timestamp has been loaded earlier from the data
storage (for example by the load method), you need not supply any
arguments. If the timestamp is not available, you must supply the
sectionid, storyname and commentpath identifiers, the method will then
load it into the data structure first.

The timestamp method will return a L<Time::Piece> object with the
requested time information.

To set the timestamp, you must supply a L<Time::Piece> object, the
timestamp is set to the time given by that object.

=back

=cut


sub timestamp {
  my $self = shift;
  my $arg = shift;
  if (ref($arg) eq 'Time::Piece') {
    ${$self}{'timestamp'} = $arg->datetime;
    return $self;
  }
  if (! ${$self}{'timestamp'}) {
    my ($storyname, $commentpath) = @_;
    $self->load(what => 'timestamp', limit => {sectionid   => $arg,
					       storyname   => $storyname,
					       commentpath => $commentpath 
					      });
  }
  unless (${$self}{'timestamp'}) { return undef; }
  (my $tmp = ${$self}{'timestamp'}) =~ s/\+\d{2}$//;
  return Time::Piece->strptime($tmp, "%Y-%m-%d %H:%M:%S");
}





1;

=head1 STORED DATA

The data is stored in named fields, and for certain uses, it is good
to know them. If you want to subclass this class, you might want to
use the same names, see the documentation of
L<AxKit::APP::TABOO::Data> for more about this.

In this class it gets even more interesting, because you may pass a
list of those to the load method. This is useful if you for example
just want the title of the comments, not all their content.

These are the names of the stored data of this class:

=over

=item * commentpath - the identifying commentpath, as described above. 

=item * storyname - an identifier for the story, a simple word you use
to retrieve the desired object.

=item * sectionid - an identifier for the section, also a simple word
you use to retrieve the desired object.

=item * title - the title for the comment chosen by the poster. 

=item * content - the full comment text.

=item * timestamp - typically the time when the comment was
posted. See also the C<timestamp()> method.

=item * username - the username of the user who posted the comment.

=back


=head1 XML representation

The C<write_xml()> method, implemented in the parent class, can be
used to create an XML representation of the data in the object. The
above names will be used as element names. The C<xmlelement()> and
C<xmlns()> methods can be used to set the name of the root element and
the namespace respectively. Usually, it doesn't make sense to change
the defaults, which are


=over

=item * C<reply>

=item * C<http://www.kjetil.kjernsmo.net/software/TABOO/NS/Comment/Output>

=back

=head1 BUGS/TODO

=over

=item * Add a category for the nature of the response, to support
things like the Thread Description Language.

=item * C<reply> should check the class of the object it is passed.

=back

=head1 FORMALITIES

See L<AxKit::App::TABOO>.

=cut
