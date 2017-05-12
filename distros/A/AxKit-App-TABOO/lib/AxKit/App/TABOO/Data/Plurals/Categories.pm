package AxKit::App::TABOO::Data::Plurals::Categories;
use strict;
use warnings;
use Carp;

use Data::Dumper;
use AxKit::App::TABOO::Data;
use AxKit::App::TABOO::Data::Category;
use AxKit::App::TABOO::Data::Plurals;


use vars qw/@ISA/;
@ISA = qw(AxKit::App::TABOO::Data::Plurals);

use DBI;
use Exception::Class::DBI;


our $VERSION = '0.21';

AxKit::App::TABOO::Data::Plurals::Categories->dbtable("categories");
AxKit::App::TABOO::Data::Plurals::Categories->dbfrom("categories");


=head1 NAME

AxKit::App::TABOO::Data::Plurals::Categories - Data objects to handle multiple Categories in TABOO

=head1 DESCRIPTION

Often, you want to retrieve many different categories from the data
store, for example all of a certain type. This is a typical situation
where this class shoule be used.

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
	XMLPREFIX => undef,
	XMLELEMENT => undef,
	XMLNS => undef,
    };
    bless($self, $class);
    return $self;
}


=item C<load(what =E<gt> fields, limit =E<gt> {key =E<gt> value, [...]}, orderby =E<gt> fields, entries =E<gt> number, withcontent =E<gt> boolean)>

This load method can be used to retrieve a number of entries from a
data store.  It uses named parameters, the first C<what> is used to
determine which fields to retrieve. It is a string consisting of a
commaseparated list of fields, as specified in the data store. The
C<limit> argument is to be used to determine which records to
retrieve, these will be combined by logical AND. You may also supply a
C<orderby> argument, which is an expression used to determine the
order of entries returned. Finally, you may supply a C<entries>
argument, which is the maximum number of entries to retrieve. If a
boolean C<onlycontent> is set to true, it will check if there are
articles or stories in the C<categ> category types, and return only
those.

It will retrieve the data, and then call C<populate()> for each of the
records retrieved to ensure that the plural data objects actually
consists of an array of L<AxKit::App::TABOO::Data::Category>s. But it
calls the internal C<_load()>-method to do the hard work (and that's
in the parent class).

If there is no data that corresponds to the given arguments, this
method will return C<undef>.

=cut


sub load {
  my ($self, %args) = @_;
  my $data = $self->_load(%args); # Does the hard work
  return undef unless (@{$data});
  my $dbh = DBI->connect($self->dbconnectargs());
  my @hassomething;
  if ($args{'onlycontent'}) {
    my $tmp = $dbh->selectcol_arrayref("SELECT catname FROM categories JOIN articlecats ON (categories.id =articlecats.cat_id) WHERE type='categ' UNION SELECT primcat FROM stories WHERE NOT sectionid='subqueue'");
    if (ref($tmp) eq 'ARRAY') {
      @hassomething = @{$tmp};
    } else {
      return undef;
    }
  }
  my $anything = 0;
  foreach my $entry (@{$data}) {
    next if (($args{'onlycontent'}) && (! grep(/^${$entry}{'catname'}$/, @hassomething)));
    my $cat = AxKit::App::TABOO::Data::Category->new($self->dbconnectargs());
    $cat->populate($entry);
    $cat->onfile;
    $self->Push($cat);
    $anything = 1;
  }
  return undef unless $anything;
  return $self;
}

=back

=head1 BUGS/TODO

Not anything particular at the moment...


=head1 FORMALITIES

See L<AxKit::App::TABOO>.

=cut

1;


