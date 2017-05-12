# $Id: Syntax.pm,v 1.7 2004/07/16 04:40:56 nachbaur Exp $

package Apache::AxKit::Provider::File::Syntax;
use strict;
use vars qw/@ISA/;
use Apache::AxKit::Provider::File;
@ISA = ('Apache::AxKit::Provider::File');

our $VERSION = 0.06;
our $noMimeInfo = 0;    # unless told otherwise, we use File::MimeInfo::Magic

use Apache;
use Apache::Log;
use Apache::Constants qw(HTTP_OK);
use Apache::AxKit::Exception;
use Apache::AxKit::Provider;
use Text::VimColor;
use AxKit;
use File::Spec;
use Fcntl qw(O_RDONLY LOCK_SH);

# see if we can use File::MimeInfo::Magic
eval "use File::MimeInfo::Magic qw( mimetype )";
$noMimeInfo = 1 if $@;

#
# We can't output a filehandle, so throw the necessary exception
sub get_fh {
    throw Apache::AxKit::Exception::IO( -text => "Can't get fh for Syntax" );
}

#
# perform the necessary mime-type processing magic
sub get_strref {
    my $self = shift;

    # Return the XML data if we've already computed it
    return \$$self{xml} if ($self->{xml});

    # Let the superclass A:A:P:File handle the request if
    # this is a directory
    if ($self->_is_dir()) {
        return $self->SUPER::get_strref();
    }

    # Process the file with Text::VimColor
	my $filetype = '';
    $filetype = $self->_resolve_type unless $noMimeInfo;
	my $syntax = undef;
	if ($filetype) {
        $syntax = new Text::VimColor(
            file => $self->{file},
            filetype => $filetype,
            xml_root_element => 0, # We'll add the root ourselves
        );
    } else {
        # either the filetype is empty or set to 'plain'
        # in both cases, we let VimColor take care of
        # figuring out what kind of file this is
        $syntax = new Text::VimColor(
            file => $self->{file},
            xml_root_element => 0, # We'll add the root ourselves
        );
    }

    # Fetch the XML and return it
    my $data = $syntax->xml;

    # Trim off the > that Text::VimColor always seems to add
    $data =~ s/>>/>/;

    # Add <syn:line> tags, since it would be nice to have
    my $filename = $self->{file};
    $self->{data} = qq{<?xml version="1.0"?>\n<syn:syntax xmlns:syn="http://ns.laxan.com/text-vimcolor/1"};
    $self->{data} .= qq{ type="$filetype"} if ($filetype);
    $self->{data} .= qq{ filename="$filename">};
    my $line_number = 0;
    foreach my $line (split(/\n/, $data)) {
        $line_number++;
        $self->{data} .= qq{<syn:Line number="$line_number">$line$1</syn:Line>};
    }
    $self->{data} .= qq{</syn:syntax>};

    return \$$self{data};
}

sub _resolve_type {
    my ($self) = shift;
    # Figure out the mime-type, and rip it apart to determine
    # what VIM syntax file this should use
    my $mimetype = mimetype($self->{file}); 
    $mimetype = '' if $mimetype eq 'text/plain';  # I don't believe you!
    if ($mimetype) { 
        AxKit::Debug(8, "MimeInfo::Magic recognized file as '$mimetype'"); 
    }
    # reformating for VimColor
    my $filetype = $mimetype;
    $filetype =~ s/^(?:application|text)\/(?:x\-)?(.*)$/$1/;
    $filetype = 'xml' if $filetype eq 'rdf';
    return $filetype;
}

1;
__END__

=head1 NAME

Apache::AxKit::Provider::File::Syntax - File syntax XML generator

=head1 SYNOPSIS

    AxContentProvider Apache::AxKit::Provider::File::Syntax

=head1 DESCRIPTION

This provider processes the requested file and, instead of outputting
it verbatim, it marks the file up as XML representing the syntax of
the source document.  This is very useful for displaying JavaScript,
Perl, or other non-XML markup and syntax-colorizing it for display on
a website.

=head1 EXAMPLE

The following example shows how you can integrate the syntax processing
provider with an existing site, without having normal requests

  Alias /syntax/ /path/to/document/root/
  <Location /syntax/>
    SetHandler AxKit
    AxContentProvider Apache::AxKit::Provider::File::Syntax
    AxAddStyleMap text/xsl Apache::AxKit::Language::LibXSLT
  </Location>

=head1 BUGS

Probably very many more than listed here, but this is the known list.

=over 4

=item *

Attempts to process any file given to it, even if it cannot do so
successfully (e.g. binary files)

=item *

The method by which it identifies the VIM file type is faulty, and
currently only works properly with a small subset of filetypes.

=back

=head1 SEE ALSO

L<Text::VimColor>

=cut
