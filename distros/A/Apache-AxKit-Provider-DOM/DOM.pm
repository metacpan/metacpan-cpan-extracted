package Apache::AxKit::Provider::DOM;

use strict;

use vars qw( $VERSION @ISA );

use Apache::AxKit::Exception;
use Apache::AxKit::Provider;

$VERSION = 0.01;
@ISA = ('Apache::AxKit::Provider');

#------------------------------------------------------------------------#
# process                                                                #
#------------------------------------------------------------------------#
# AxKit should only process the ressource if the provider has a dom_tree
#
sub process {
    my $self = shift;
    return defined $self->{dom_tree} ? 1 : 0 ;
}

sub exists {
    my $self = shift;
    return $self->process;
}

#------------------------------------------------------------------------#
# pseudo noops                                                           #
#------------------------------------------------------------------------#
sub mtime        { return time; }
sub has_changed  { return 1; }
sub key          { return 'dom_provider'; }

sub get_fh {
    throw Apache::AxKit::Exception::IO( -text => "Can't get fh for Scalar" );
}

#------------------------------------------------------------------------#
# get_strref                                                             #
#------------------------------------------------------------------------#
# The DOM provider returns the string value of the document tree if a
# document is present, otherwise it throws an error
#
sub get_strref {
    my $self = shift;
    if ( defined $self->{dom_tree} ) {
        my $str = $self->{dom_tree}->toString;
        $self->{apache}->pnotes('dom_tree' => $self->{dom_tree} );
        return \$str;
    }
    else {
        throw Apache::AxKit::Exception::IO( -text => "Can't get the XML DOM" );
    }
}


1;

__END__

=head1 NAME

Apache::AxKit::Provider::DOM - Base Class For Parsed XML Providers

=head1 SYNOPSIS

  use base Apache::AxKit::Provider::DOM;

=head1 DESCRIPTION

Apache::AxKit::Provider::DOM allows to pass a parsed XML document
directly to AxKit. It can be used as a base class for application
providers, that create XML documents in memory. So
Apache::AxKit::Provider::DOM provides an easy way to write
application providers for AxKit 1.6.

Commonly an inheritated class only implements the provider function
'init()' and if required the provider function 'get_styles()'.

To make the provider work properly a class must provide the document
tree in the special provider key 'dom_tree'.

A sample DOM provider could be:

  package MyDomProvider;

  use vars (@INC);
  use XML::LibXML;
  use Apache::AxKit::Provider::DOM;
  @INC = ('Apache::AxKit::Provider::DOM');

  sub init {
      my $class = shift;
      $class->{dom_tree} = XML::LibXML->new;
      $class->{dom_tree}->setDocumentElement(
         $class->{dom_tree}->createElement( 'foo' );
      );
  }

  1;

This sample provider would cause AxKit to use the default style as
provided in the style map of the server configuration.

If a provider based on Apache::AxKit::Provider::DOM and does not set
the 'dom_tree' key as shown in the example AxKit will not process this
ressource.

=head1 SEE ALSO

AxKit, Apache::AxKit::Provider

=cut
