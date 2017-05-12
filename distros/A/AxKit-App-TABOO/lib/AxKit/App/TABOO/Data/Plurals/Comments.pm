package AxKit::App::TABOO::Data::Plurals::Comments;
use strict;
use warnings;
use Carp;

use Data::Dumper;
use AxKit::App::TABOO::Data;
use AxKit::App::TABOO::Data::Comment;
use AxKit::App::TABOO::Data::Plurals;


use vars qw/@ISA/;
@ISA = qw(AxKit::App::TABOO::Data::Plurals);

use DBI;
use Exception::Class::DBI;


our $VERSION = '0.093';

AxKit::App::TABOO::Data::Plurals::Comments->dbtable("comments");
AxKit::App::TABOO::Data::Plurals::Comments->dbfrom("comments");


=head1 NAME

AxKit::App::TABOO::Data::Plurals::Comments - Data objects to handle
multiple Comments in TABOO

=head1 DESCRIPTION

Usually, you want to retrieve many different comments from the data
store, for example all comments below a certain comment. You may use
this class to retrieve all comments, comments just below a specified
comment or a threaded tree.

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
	DBCONNECTARGS => \@_,
	XMLELEMENT => 'reply',
	XMLPREFIX => 'comm',
	XMLNS => 'http://www.kjetil.kjernsmo.net/software/TABOO/NS/Comment/Output',

    };
    bless($self, $class);
    return $self;
}



=item C<load(what =E<gt> fields, limit =E<gt> {key =E<gt> value, [...]}, orderby =E<gt> fields)>

This load method can be used to retrieve a number of entries from a
data store.  It uses named parameters, the first C<what> is used to
determine which fields to retrieve. It is a string consisting of a
commaseparated list of fields, as specified in the data store. The
C<limit> argument is to be used to determine which records to
retrieve, these will be combined by logical AND. You will most
certainly want to supply the C<sectionid>, the C<storyname> and
usually the C<commentpath>.

The latter is described in the
L<singular|AxKit::App::TABOO::Data::Comment> class documentation. It
is worth noting that if the commentpath ends with a C</>, this method
will return only the comments on the next level, if it doesn't, it
will return the whole tree starting with the given commentpath. If no
commentpath is given, a tree of all comments are retrieved.

You may also supply a C<orderby> argument, which is an expression used
to determine the order of entries returned. Usually, it would be a
simple string with the field name to use, e.g. C<'timestamp'>, but you
might want to append the keyword "C<DESC>" to it for descending
order. Finally, you may supply a C<entries> argument, which is the
maximum number of entries to retrieve.

It will retrieve the data, and then call C<populate()> for each of the
records retrieved to ensure that the plural data objects actually
consists of an array of L<AxKit::App::TABOO::Data::Comment>s.

If there is no data that corresponds to the given arguments, this
method will return C<undef>.

=cut

sub load {
  my ($self, %args) = @_;
  my $array = 0;
  my $basepath = $args{'limit'}{'commentpath'};
  if ($basepath =~ m|/$|) {
    # If it ends with a / we will only retrieve the records on the
    # next level, and they will be a single, non-threaded array
    $array = 1;
    $args{'limit'}{'commentpath'} = '^' . $basepath . '[a-z]+?_?[0-9]*/?$';
  }
  my $data = $self->_load(%args, regex => ['commentpath']);
  return undef unless (@{$data});
  if ($array) {
    foreach my $entry (@{$data}) {
      my $comment = AxKit::App::TABOO::Data::Comment->new($self->dbconnectargs());
      $comment->populate($entry);
      $comment->onfile;
      $self->Push($comment);
    }
  } else {
    my %data;
    foreach my $entry (@{$data}) {
      $data{${$entry}{'commentpath'}} = $entry;
    }
    my $comment = AxKit::App::TABOO::Data::Comment->new($self->dbconnectargs());
    if (length($basepath) == 0) {
      my @build = grep(m|^/[a-z]+?_?[0-9]*$|, keys(%data));
      return undef if ($#build < 0);
      foreach (@build) {
	# Apparently, I can't just modify $self straightforwardly. Quirky
	my $comment = AxKit::App::TABOO::Data::Comment->new($self->dbconnectargs());
	$comment->populate($data{$_});
	$comment->onfile;
	$comment->reply($self->_threadhelper($_, %data));
	$self->Push($comment);
      }
    } else {
      $comment->populate($data{$basepath});
      $comment->onfile;
      $comment->reply($self->_threadhelper($basepath, %data));
      $self->Push($comment);
    }
  }
  return $self;
}

# Internal helper method. Will walk all nodes in a tree to add replies
# recursively in the cases where a complete tree of comments are to be
# built. Takes as argument the commentpath we're starting out from,
# and a %data hash containing all comments with the commentpath as a
# key.

sub _threadhelper {
  my $self = shift;
  my $path = shift;
  my %data = @_;
  my @build = grep(m|^$path/[a-z]+?_?[0-9]*$|, keys(%data));
  return undef if ($#build < 0);
  my $comments = AxKit::App::TABOO::Data::Plurals::Comments->new($self->dbconnectargs());
  foreach (@build) {
    my $comment = AxKit::App::TABOO::Data::Comment->new($self->dbconnectargs());
    $comment->populate($data{$_});
    $comment->onfile;
    $comment->reply($self->_threadhelper($_, %data));
    $comments->Push($comment);
  }
  return $comments;
}



=item C<adduserinfo>

This methods is implemented in a plurals context, and can be called on
a plurals object just like a singular object. Each entry will have
their data structure extended with user information.

=cut


sub adduserinfo {
  my $self = shift;
  foreach my $comment (@{${$self}{ENTRIES}}) {
    $comment->adduserinfo;
    if ((ref($comment->reply) eq 'AxKit::App::TABOO::Data::Comment') || 
	(ref($comment->reply) eq 'AxKit::App::TABOO::Data::Plurals::Comments')) {
      $comment->reply->adduserinfo;
    }
  }
  return $self;
}


=item C<exist(commentpath =E<gt> '/foo', storyname =E<gt> 'story', sectionid =E<gt> 'section')>

This method can be used to check if there are one or more comments
starting with the commentpath given. It takes a hash to identify the
comment. It will return a scalar with the number of found comments.

=cut

sub exist {
  my $self = shift;
  my %args = @_;
  $args{'commentpath'} = '^' . $args{'commentpath'} . '_?[0-9]*[^/]?$';
  my $data = $self->_load(what => 'commentpath', regex => ['commentpath'], limit => \%args);
  return scalar(@{$data});
}


=back

=head1 BUGS/TODO

It might be a good idea to return just a singular type object if there
is indeed just a single object that is returned from load.


=head1 FORMALITIES

See L<AxKit::App::TABOO>.

=cut

1;


