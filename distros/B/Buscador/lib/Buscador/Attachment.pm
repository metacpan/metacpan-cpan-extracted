package Buscador::Attachment;
use strict;

=head1 NAME

Buscador::Attachment - Buscador plugin to access attachments

=head1 DESCRIPTION

This plugin allows you to do

    ${base}/attachment/view/<id>

And either download or view an attachment. It sets the 
filename correctly using B<Content-Disposition>.

=head1 AUTHOR

Simon Cozens, <simon@cpan.org>

with work from 

Simon Wistow, <simon@thegestalt.org>

=head1 COPYRIGHT

Copyright 2004, Simon Cozens

=cut



package Email::Store::Attachment;
use strict;
use MIME::Base64 qw(decode_base64);


sub view :Exported {
    my ($self, $r, $att) = @_;


    $r->ar->headers_out->set("Content-Disposition" => "inline; filename=".$att->filename) if $att->filename;

    $r->{content_type} = $att->content_type;
    $r->{output} = ($att->content_type =~ m!^text/!) ? $att->payload: decode_base64($att->payload);
}

1;

