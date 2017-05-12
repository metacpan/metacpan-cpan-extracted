package Apache::AxKit::Provider::Article;

use DBI;
use Data::Dumper;
use strict;
use XML::LibXML;

our $VERSION = '0.18_01';

=head1 NAME

AxKit::App::TABOO::Provider::Article - Article Provider for TABOO

=head1 BUGS/TODO

Right now, this Provider hardly works at all. It encounters some nasty
problems, apparently within XML::LibXML that makes the apache process
segfault. I really can't find a way around it. The important functions
that this provider should perform is currently implemented in XSP, and
those familiar with TABOO's design goals will be aware that this is
not something I take lightly.

=cut


use vars qw/@ISA/;
@ISA = ('Apache::AxKit::Provider');

use Apache;
use Apache::AxKit::Exception;
use Apache::AxKit::Provider;
use AxKit::App::TABOO;
use AxKit;

# sub: Init
# Here we do some initialization stuff. 
sub init {
  my $self = shift;
  my $r = $self->apache_request();
  
  AxKit::Debug(10, "Request object: " . $r->as_string);
  AxKit::Debug(8, "[uri] Article Provider using URI " . $r->uri);
  
  $self->{uri} = $r->uri;
  ($self->{primcat}, $self->{filename}) = $r->uri =~ m|/articles/(.*?)/(.*?)$|;
  
  AxKit::Debug(9, "Filename is: " . $self->{filename});
  AxKit::Debug(9, "Primary category is: " . $self->{primcat});
  
  $self->{metadata} = AxKit::App::TABOO::Data::Article->new();
  $self->{metadata}->load(limit => { filename => $self->{filename},
				     primcat  => $self->{primcat}});
  return $self;
}

sub get_strref {
  my $self = shift;
  unless (defined($self->{metadata})) {
    throw Apache::AxKit::Exception::Retval(
					   return_code => 404,
					   -text => "Article does not exist");
  }
  my $doc = XML::LibXML::Document->new();
  my $rootel = $doc->createElement('taboo');
#  $rootel->setAttribute('type', 'article');
#  $rootel->setAttribute('origin', 'Article');
  $doc->setDocumentElement($rootel);
  $self->{metadata}->write_xml($doc, $rootel);
  return $doc->toString(1);
}
  
# sub: get_fh
# we don't want to handle files, so we just throw an exception here.
sub get_fh {
    throw Apache::AxKit::Exception::IO( 
            -text => "Can't get fh for DBI filehandle"
            );
}


# sub: mtime
# This should return the modification time of the resource, for simplicity here we decrement it everytime we are called

sub mtime {
  my $self=shift;
   return time();  
}

# sub: process

sub process {
  my $self = shift;
  return $self->{exists};
} 

# sub: key
# should return a unique identifier for the resource.

sub key {
  my $self = shift;
  return $self->{primcat} . '/' . $self->{filename} ;
}

# sub: exists
# should return 1 only if the resource actually exists. 
# Checking if the underlying file exists.
sub exists {
  my $self = shift;
#  my $fullfile = $self->{basedir} . $self->{primcat} . '/' . $self->{filename} . '/main';
#  my $status = -e $fullfile;
  $self->{exists} = (defined($self->{metadata})) ?1:0;
#  if (!$status)
#  {
#    AxKit::Debug(5, "file '$fullfile' does not exist or is not readable");
#  }
  return $self->{exists};
}


1;



