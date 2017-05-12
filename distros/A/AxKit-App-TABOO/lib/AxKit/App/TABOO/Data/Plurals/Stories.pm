package AxKit::App::TABOO::Data::Plurals::Stories;
use strict;
use warnings;
use Carp;

use Data::Dumper;
use AxKit::App::TABOO::Data;
use AxKit::App::TABOO::Data::Story;
use AxKit::App::TABOO::Data::Plurals;


use vars qw/@ISA/;
@ISA = qw(AxKit::App::TABOO::Data::Plurals);

use DBI;
use Exception::Class::DBI;


our $VERSION = '0.18';

AxKit::App::TABOO::Data::Plurals::Stories->dbtable("stories");
AxKit::App::TABOO::Data::Plurals::Stories->dbfrom("stories");


=head1 NAME

AxKit::App::TABOO::Data::Plurals::Stories - Data objects to handle multiple Stories in TABOO

=head1 DESCRIPTION

Often, you want to retrieve many different stories from the data store, for example all belonging to a certain category or a certain section. This is a typical situation where this class shoule be used.

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
	XMLELEMENT => undef,
	XMLPREFIX => undef,
	XMLNS => undef,
    };
    bless($self, $class);
    return $self;
}


=item C<load(what =E<gt> fields, limit =E<gt> {key =E<gt> value, [...]}, orderby =E<gt> fields, entries =E<gt> number)>

This load method can be used to retrieve a number of entries from a
data store.  It uses named parameters, the first C<what> is used to
determine which fields to retrieve. It is a string consisting of a
commaseparated list of fields, as specified in the data store. The
C<limit> argument is to be used to determine which records to
retrieve, these will be combined by logical AND. You may also supply a
C<orderby> argument, which is an expression used to determine the
order of entries returned. Usually, it would be a simple string with
the field name to use, e.g. C<'timestamp'>, but you might want to
append the keyword "C<DESC>" to it for descending order. Finally, you
may supply a C<entries> argument, which is the maximum number of
entries to retrieve.

It will retrieve the data, and then call C<populate()> for each of the
records retrieved to ensure that the plural data objects actually
consists of an array of L<AxKit::App::TABOO::Data::Story>s. But it
calls the internal C<_load()>-method to do the hard work (and that's
in the parent class).

If there is no data that corresponds to the given arguments, this method will return C<undef>.

=cut

sub load {
  my ($self, %args) = @_;
  my $data = $self->_load(%args); # Does the hard work
  return undef unless (@{$data});
  foreach my $entry (@{$data}) {
    my $story = AxKit::App::TABOO::Data::Story->new($self->dbconnectargs());
    $story->populate($entry);
    $story->onfile;
    $self->Push($story);
  }
  return $self;
}


=item C<addcatinfo>

=item C<adduserinfo>

These two methods are implemented in a plurals context, and can be called on a plurals object just like a singular object. Each entry will have their data structure extended with user and category information.

=cut


sub addcatinfo {
  my $self = shift;
  foreach my $story (@{${$self}{ENTRIES}}) {
    $story->addcatinfo;
  }
  return $self;
}


sub adduserinfo {
  my $self = shift;
  foreach my $story (@{${$self}{ENTRIES}}) {
    $story->adduserinfo;
  }
  return $self;
}

=item C<exists(key =E<gt> value, [...])>

This checks if there exists a story with the limits specified as a
hash, by the template of the C<limit> argument of the C<load> method.

It will return the number of such stories.

=cut


sub exists {
  my ($self, %limit) = @_;
  if (%limit) {
    return scalar(@{$self->_load(what => '1', limit => \%limit)});
  } else {
    return scalar(@{$self->_load(what => '1')});
  }
}




=back

=head1 BUGS/TODO

Not anything particular at the moment...


=head1 FORMALITIES

See L<AxKit::App::TABOO>.

=cut

1;


