package Catalyst::View::PDF::Reuse;

use warnings;
use strict;
use parent 'Catalyst::View::TT';
use File::chdir;
use File::Spec::Functions qw/catfile rel2abs/;
use File::Temp qw/tmpnam/;
use PDF::Reuse;

our $VERSION = '0.05';

=encoding utf8

=head1 NAME

Catalyst::View::PDF::Reuse - Create PDF files from Catalyst using Template Toolkit templates

=cut

=head1 SYNOPSIS

Create a PDF::Reuse view:

 script/myapp_create.pl view PDF::Reuse PDF::Reuse

In MyApp.pm, add a configuration item for the template include path:

 __PACKAGE__->config('View::PDF::Reuse' => {
   INCLUDE_PATH => __PACKAGE__->path_to('root','templates')
 });

In your controller:

 $c->stash->{pdf_template} = 'hello_pdf.tt';
 $c->forward('View::PDF::Reuse');

In F<root/templates/hello_pdf.tt>:

 [% pdf.prFont('Helvetica-Bold') %]
 [% pdf.prFontSize(20) %]
 [% pdf.prText(100,100,'Hello, World!') %]


=head1 DESCRIPTION

Catalyst::View::PDF::Reuse provides the facility to generate PDF files from
a Catalyst application by embedding L<PDF::Reuse> commands within a Template
Toolkit template.

=head2 Template Syntax

Within your template you will have access to a C<pdf> object which has
methods corresponding to all of L<PDF::Reuse>'s functions.

For example, to print the text I<Hello, World> at PDF coordinates 100,100,
use the following directive in your template:

 [% pdf.prText(100,100,'Hello, World') %]

Data held in the stash can be printed as follows:

 $c->stash->{list} = ['one', 'two', 'three', 'four'];

 [% y = 500 %]
 [% FOREACH item IN list %]
   [% pdf.prText(100,y,item) %]
   [% y = y - 13 %]
 [% END %]

Formatting can be defined using the Template Toolkit format plugin:

 [% USE format %]
 [% currency = format('£%.2f') %]
 [% pdf.prText(100,100,currency(10)) %]

=head2 Using existing PDF documents

The key benefit of L<PDF::Reuse> is the ability to load an existing PDF
file and use this as the basis for a new document.

For example, to produce receipts or shipping labels you could create a
blank receipt in Microsoft Word, convert this to PDF, then use PDF::Reuse
to add in details such as the order number and customer address.

 [% pdf.prForm('customer_receipt.pdf') %]
 [% pdf.prText(123,643,order.number) %]
 [% pdf.prText(299,643,order.date) %]

Note that the PDF document loaded by C<pdf.prForm> must be in the same
directory as your Template Toolkit template.

=head1 FUNCTIONS

=head2 process

Render the PDF file, places the contents in C<< $c->response->body >> and
sets appropriate HTTP headers.

You should normally not need to use this method directly, instead forward
to the PDF::Reuse view from your controller:

 $c->forward('View::PDF::Reuse');

The filename and content disposition (inline or attachment) can be controlled
by putting the following values in the stash:

 $c->stash->{pdf_disposition} = 'attachment';  # Default is 'inline'
 $c->stash->{pdf_filename}    = 'myfile.pdf';  

If the PDF filename is not specified, it will be set to the last component
of the URL path, appended with '.pdf'. For example, with a URL of
L<http://localhost/view/order/pdf/1234> the PDF filename would be set to
F<1234.pdf>.

=cut

sub process {
    my ($self, $c) = @_;

    my $output = $self->render_pdf($c);
    if (UNIVERSAL::isa($output, 'Template::Exception')) {
        my $error = qq/Couldn't render template "$output"/;
        $c->log->error($error);
        $c->error($error);
        return 0;
    }

    my $pdf_filename = $c->stash->{pdf_filename} || (split '/',$c->req->path)[-1] || 'index.pdf';
    $pdf_filename .= '.pdf' unless ($pdf_filename =~ /\.pdf$/i);
    
    my $pdf_disposition = $c->stash->{pdf_disposition} || 'inline';
      
    $c->response->content_type('application/pdf');
    $c->response->headers->header("Content-Disposition" => qq{$pdf_disposition; filename="$pdf_filename"});
    
    $c->response->body($output);
}


=head2 render_pdf

Renders the PDF file and returns the raw PDF data.

If you need to capture the PDF data, e.g. to store in a database or for
emailing, call C<render_pdf> as follows:

 my $pdf = $c->view("PDF::Reuse")->render_pdf($c);

=cut

sub render_pdf {
    my ($self, $c) = @_;
  
    my $template = <<'EOT';
    [% USE pdf = Catalyst::View::PDF::Reuse %]
    [% USE barcode = Catalyst::View::PDF::Reuse::Barcode %]
    [% PROCESS $pdf_template %]
EOT

    my $tempfile = tmpnam();
    prInitVars();
    prFile($tempfile);
    
    # Convert any relative include paths to absolute paths
    foreach my $path (@{$self->config->{INCLUDE_PATH}}) {
        $path = rel2abs($path);
    }

    my $output;
    SEARCH: foreach my $path (@{$self->config->{INCLUDE_PATH}}) {
        if (-e catfile($path,$c->stash->{pdf_template})) {
            local $CWD = $path;
            $output = $self->render($c,\$template);
            last SEARCH;
        }
    }
    
    prEnd();

    my $pdf;
    local $/ = undef;
    open PDF,'<',$tempfile;
    $pdf = (<PDF>);
    close PDF;
    unlink $tempfile;

    return (UNIVERSAL::isa($output, 'Template::Exception')) ? $output : $pdf;
}

=head1 AUTHOR

Jon Allen, L<jj@jonallen.info>


=head1 BUGS

Please report any bugs or feature requests to C<bug-catalyst-view-pdf-reuse at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Catalyst-View-PDF-Reuse>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

 perldoc Catalyst::View::PDF::Reuse

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Catalyst-View-PDF-Reuse>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Catalyst-View-PDF-Reuse>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Catalyst-View-PDF-Reuse>

=item * Search CPAN

L<http://search.cpan.org/dist/Catalyst-View-PDF-Reuse>

=back


=head1 SEE ALSO

L<PDF::Reuse>

Penny's Arcade Open Source - L<http://www.pennysarcade.co.uk/opensource>


=head1 COPYRIGHT & LICENSE

Copyright (C) 2009 Penny's Arcade Limited

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Catalyst::View::PDF::Reuse
