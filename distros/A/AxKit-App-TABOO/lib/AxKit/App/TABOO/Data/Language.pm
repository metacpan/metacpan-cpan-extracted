package AxKit::App::TABOO::Data::Language;
use strict;
use warnings;
use Carp;
use Encode;

use Data::Dumper;
use AxKit::App::TABOO::Data;
use vars qw/@ISA/;
@ISA = qw(AxKit::App::TABOO::Data);

use DBI;
use Exception::Class::DBI;
use MIME::Types;


our $VERSION = '0.3';


=head1 NAME

AxKit::App::TABOO::Data::Language - Language Data objects for TABOO

=head1 SYNOPSIS

  use AxKit::App::TABOO::Data::Language;
  $type = AxKit::App::TABOO::Data::Language->new(@dbconnectargs);
  $type->load(limit => {code => 'no'});


=head1 DESCRIPTION

This contains a simple class for ISO 639 language codes.

=cut

AxKit::App::TABOO::Data::Language->elementorder("code, localname");
AxKit::App::TABOO::Data::Language->dbfrom("languages");

=head1 METHODS

This class reimplements only one method in addition to the
constructor, the rest is inherited from L<AxKit::App::TABOO::Data>.

=over

=item C<new(@dbconnectargs)>

The constructor. Nothing special.


=item C<load(what =E<gt> fields, limit =E<gt> {code =E<gt> value, [...]})>

Nothing very different from other load methods. You would usually load
an object by specifying the C<mimetype> as in the above example.

=cut

sub load {
  my ($self, %args) = @_;
  my $data = $self->_load(%args);
  if ($data) {
    ${$self}{'ONFILE'} = 1;
  } else {
    return undef;
  }
  $self->populate($data);
  return $self;
}


=back

=head1 STORED DATA

The data is stored in named fields, and for certain uses, it is good
to know them. If you want to subclass this class, you might want to
use the same names, see the documentation of
L<AxKit::APP::TABOO::Data> for more about this. These are the names of
the stored data of this class:

=over

=item * code

The ISO 639 two-letter code

=item * localname

An expanded name intended for human consumption. Must be in the code's
own langugage.


=back

=head1 XML representation

The C<write_xml()> method, implemented in the parent class, can be
used to create an XML representation of the data in the object. The
above names will be used as element names. The C<xmlelement()>,
C<xmlns()> and C<xmlprefix()> methods can be used to set the name of
the root element, the namespace URI and namespace prefix
respectively. Usually, it doesn't make sense to change the default
namespace, prefix, or root element that are

=over

=item * C<http://www.kjetil.kjernsmo.net/software/TABOO/NS/Language/Output>

=item * C<lang>

=item * C<language>

=back


=cut

sub new {
  my $that  = shift;
  my $class = ref($that) || $that;
  my $self = {
	      localname => undef,
	      code => undef,
	      DBCONNECTARGS => \@_,
	      XMLELEMENT => 'language',
	      XMLPREFIX => 'type',
	      XMLNS => 'http://www.kjetil.kjernsmo.net/software/TABOO/NS/Language/Output',
	      ONFILE => undef,
	     };
  bless($self, $class);
  return $self;
}


=head1 FORMALITIES

See L<AxKit::App::TABOO>.

=cut

1;


