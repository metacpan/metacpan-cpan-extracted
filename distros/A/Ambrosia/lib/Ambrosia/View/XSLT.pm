package Ambrosia::View::XSLT;
use strict;
use warnings;
use Carp;

use XML::LibXML ();
#use XML::LibXSLT ();

use if $^O !~ /^MSWin/ ? 1 : 0, 'XML::LibXSLT' => ();
use if $^O =~ /^MSWin/ ? 1 : 0, 'XML::XSLT' => ();

require Ambrosia::core::Object;
require Ambrosia::error::Exceptions;

use Ambrosia::Meta;

class sealed
{
    extends => [qw/Ambrosia::View/],
    public => [qw/rootName/],
};

our $VERSION = 0.010;

sub can_xml_xsl
{
    return 0; #defined $ENV{HTTP_USER_AGENT} && $ENV{HTTP_USER_AGENT} =~ /Mozilla/;
}

sub process
{
    my $self = shift;

    return $self->as_xml unless $self->template;
    return $self->can_xml_xsl ? $self->__render_on_client() : $self->__render_on_server();
}

sub __render_on_server
{
    my $self = shift;

    my $parser = XML::LibXML->new();
    my $stylesheet = XML::LibXSLT->new()
        ->parse_stylesheet($parser->parse_file($self->template));
#warn 'template: ' . $self->template . "\n";
    return  $stylesheet->output_as_bytes(
                $stylesheet->transform(
                    $parser->parse_string(scalar $self->as_xml)
                )
            );
}

sub __render_on_client
{
    my $self = shift;

    my ($document, $node) = $self->as_xml;
    $document->insertProcessingInstruction('xml-stylesheet', 'type="text/xsl" href="' . $self->template . '"');

    return $document->toString();
}

sub as_xml
{
    my $self = shift;
    my $rootName = shift;
    $rootName ||= $self->rootName;

    my ($document, $node) = $self->__as_xml(0, $rootName);
    $document->setDocumentElement($node);
#warn 'document: ' . $document->toString(2) . "\n";
    return wantarray ? ($document, $node) : $document->toString();
}

#use Data::Dumper;
sub __as_xml
{
    my $self = shift;
    my $ignore = shift;
    my $name_node = shift;

    my ($document, $node);
    eval
    {
        my $charset = $self->charset || 'utf-8';
        $document = XML::LibXML->createDocument( '1.0', $charset );

        $node = $document->createElement($name_node || 'context');

        my $data = $self->data;

        foreach my $p ( keys %$data )
        {
            next if $p eq 'query';

            my $value = $data->{$p};
#warn "$p=".Dumper($value). "\n-----------------\n";
            if ( ref $value )
            {
                Ambrosia::core::Object::as_xml_nodes($document, $node, $p, $value, $ignore );
            }
            else
            {
                $node->setAttribute($p, $value);
            }
        }
    };
    if ( $@ )
    {
        carp("$@");
        throw Ambrosia::error::Exception 'error while converter to XML', $@ unless $ignore;
    }
    return ($document, $node);
}


1;

__END__

=head1 NAME

Ambrosia::View::JSON - it is VIEW in MVC.

=head1 VERSION

version 0.010

=head1 DESCRIPTION

C<Ambrosia::View::JSON> - it is VIEW in MVC.
Returns result in XML or HTML.

=head1 CONSTRUCTOR

=head1 THREADS

Not tested.

=head1 BUGS

Please report bugs relevant to C<Ambrosia> to <knm[at]cpan.org>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010-2012 Nickolay Kuritsyn. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Nikolay Kuritsyn (knm[at]cpan.org)

=cut
