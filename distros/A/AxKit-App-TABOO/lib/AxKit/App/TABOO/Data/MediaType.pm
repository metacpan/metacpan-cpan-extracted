package AxKit::App::TABOO::Data::MediaType;
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


our $VERSION = '0.2';


=head1 NAME

AxKit::App::TABOO::Data::MediaType - MediaType Data objects for TABOO

=head1 SYNOPSIS

  use AxKit::App::TABOO::Data::MediaType;
  $type = AxKit::App::TABOO::Data::MediaType->new(@dbconnectargs);
  $type->load(limit => {mimetype => 'text/html'});


=head1 DESCRIPTION

This contains a simple class for MIME Types as defined by IANA.

=cut

AxKit::App::TABOO::Data::MediaType->elementorder("mimetype, name, uri");
AxKit::App::TABOO::Data::MediaType->dbfrom("mediatypes");

=head1 METHODS

This class implements only one method and reimplements two, in
addition to the constructor, the rest is inherited from
L<AxKit::App::TABOO::Data>.

=over

=item C<new(@dbconnectargs)>

The constructor. Nothing special.


=item C<load(what =E<gt> fields, limit =E<gt> {mimetype =E<gt> value, [...]})>

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


=item C<populate($args)>

The populate method is reimplemented, to deal well with L<MIME::Type>
objects. Its interface is unchanged, however.

=cut

sub populate {
    my $self = shift;
    my $args = shift;
    ${$self}{'uri'} = ${$args}{'uri'};
    ${$self}{'name'} = Encode::decode_utf8(${$args}{'name'});
    my $mimetypes = MIME::Types->new(only_complete => 1);
    my MIME::Type $type = $mimetypes->type(${$args}{'mimetype'});  
    ${$self}{'mimetype'} = ($type) ? $type : ${$args}{'mimetype'};
    return $self;
}


=item C<mimetype>

Will return a L<MIME::Type> object with the loaded MIME Type.

=cut

sub mimetype {
  my $self = shift;
  if (ref(${$self}{'mimetype'}) eq 'MIME::Type') {
    return ${$self}{'mimetype'};
  }
  my $mimetypes = MIME::Types->new(only_complete => 1);
  my MIME::Type $type = $mimetypes->type(${$self}{'mimetype'});
  return $type;
}
    

=back

=head1 STORED DATA

The data is stored in named fields, and for certain uses, it is good
to know them. If you want to subclass this class, you might want to
use the same names, see the documentation of
L<AxKit::APP::TABOO::Data> for more about this. These are the names of
the stored data of this class:

=over

=item * mimetype

The IANA-registered MIME types.

=item * name

An expanded name intended for human consumption.


=item * uri

Creating new media types seems like a long and burdensome process. I
was hoping that some day, also media types will be identified by
URIs. I don't know if there is any progress on that, but I reserve
this field in the hope. Also, in the Semantic Web you'd like to
identify things and their relationships with URIs, so we might as well
have a field.



=back



=head1 XML representation

The C<write_xml()> method, implemented in the parent class, can be
used to create an XML representation of the data in the object. The
above names will be used as element names. The C<xmlelement()>,
C<xmlns()> and C<xmlprefix()> methods can be used to set the name of
the root element, the namespace URI and namespace prefix
respectively. Usually, it doesn't make sense to change the default
namespace or prefix, that are

=over

=item * C<http://www.kjetil.kjernsmo.net/software/TABOO/NS/MediaType/Output>

=item * C<type>

=back

However, the root element may change depending on what kind of mediatype we have. The default is C<mediatype>.

=cut

sub new {
  my $that  = shift;
  my $class = ref($that) || $that;
  my $self = {
	      mimetype => undef,
	      name => undef,
	      uri => undef,
	      DBCONNECTARGS => \@_,
	      XMLELEMENT => 'mediatype',
	      XMLPREFIX => 'type',
	      XMLNS => 'http://www.kjetil.kjernsmo.net/software/TABOO/NS/MediaType/Output',
	      ONFILE => undef,
	     };
  bless($self, $class);
  return $self;
}


=head1 FORMALITIES

See L<AxKit::App::TABOO>.

=cut

1;


