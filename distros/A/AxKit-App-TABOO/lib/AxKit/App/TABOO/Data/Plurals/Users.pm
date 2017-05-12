package AxKit::App::TABOO::Data::Plurals::Users;
use strict;
use warnings;
use Carp;

use Data::Dumper;
use AxKit::App::TABOO::Data;
use AxKit::App::TABOO::Data::User;
use AxKit::App::TABOO::Data::Plurals;


use vars qw/@ISA/;
@ISA = qw(AxKit::App::TABOO::Data::Plurals);

use DBI;
use Exception::Class::DBI;


our $VERSION = '0.19';

AxKit::App::TABOO::Data::Plurals::Users->dbtable("users");
AxKit::App::TABOO::Data::Plurals::Users->dbfrom("users");


=head1 NAME

AxKit::App::TABOO::Data::Plurals::Users - Data objects to handle multiple Users in TABOO

=head1 DESCRIPTION

Often, you want to retrieve many different users from the data store,
for example all with certain privileges. This is a typical situation
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


=item C<load(what =E<gt> fields, limit =E<gt> {key =E<gt> value, [...]}, orderby =E<gt> fields, entries =E<gt> number)>

This load method can be used to retrieve a number of entries from a
data store.  It uses named parameters, the first C<what> is used to
determine which fields to retrieve. It is a string consisting of a
commaseparated list of fields, as specified in the data store. The
C<limit> argument is to be used to determine which records to
retrieve, these will be combined by logical AND. You may also supply a
C<orderby> argument, which is an expression used to determine the
order of entries returned. Finally, you may supply a C<entries>
argument, which is the maximum number of entries to retrieve.

It will retrieve the data, and then call C<populate()> for each of the
records retrieved to ensure that the plural data objects actually
consists of an array of L<AxKit::App::TABOO::Data::User>s. But it
calls the internal C<_load()>-method to do the hard work (and that's
in the parent class).

If there is no data that corresponds to the given arguments, this
method will return C<undef>.

=cut


sub load {
  my ($self, %args) = @_;
  my $data = $self->_load(%args); # Does the hard work
  return undef unless (@{$data});
  foreach my $entry (@{$data}) {
    my $cat = AxKit::App::TABOO::Data::User->new($self->dbconnectargs());
    $cat->populate($entry);
    $cat->onfile;
    $self->Push($cat);
  }
  return $self;
}

=back

=head1 BUGS/TODO

This is really not very well tested, it gets the users, but probably
not all the information from subclasses of the singular objects.


=head1 FORMALITIES

See L<AxKit::App::TABOO>.

=cut

1;


