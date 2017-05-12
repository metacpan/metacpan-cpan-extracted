# $Id: HTML.pm,v 1.1.1.1 2002/05/29 22:03:41 matt Exp $

package AxKit::Provider::HTML;

@ISA = qw(Apache::AxKit::Provider::File);
$VERSION = '1.0';

use strict;
use XML::LibXML;
use Apache::AxKit::Provider::File;
use Apache::AxKit::Exception;

sub get_fh {
    throw Apache::AxKit::Exception ( -text => "get_fh not supported for HTML provider" );
}

sub get_strref {
    my $self = shift;
    
    my $file = $self->{file};
    my $parser = XML::LibXML->new();
    my $doc = $parser->parse_html_file($file);
    my $str = $doc->toString;
    return \$str;
}

1;
__END__

=head1 NAME

AxKit::Provider::HTML - AxKit Provider Module for HTML files

=head1 SYNOPSIS

  <Files *.html>
    AxContentProvider AxKit::Provider::HTML
  </Files>

=head1 DESCRIPTION

A filesystem based provider for HTML files.

=head1 LICENSE

Free software. Perl terms.

=head1 AUTHOR

Matt Sergeant, <matt@sergeant.org>. Copyright AxKit.com Ltd 2002.

=cut
