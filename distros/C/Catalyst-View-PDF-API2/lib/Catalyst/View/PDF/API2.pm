package Catalyst::View::PDF::API2;

use warnings;
use strict;
use parent 'Catalyst::View::TT';
use File::chdir;
use File::Spec::Functions qw/catfile/;
use File::Temp qw/tmpnam/;
use PDF::API2;

=head1 NAME

Catalyst::View::PDF::API2 - Create PDF files from Catalyst using Template Toolkit templates

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

Create a PDF::API2 view:

 script/myapp_create.pl view PDF PDF::API2

In MyApp.pm, add a configuration item for the template include path:

 __PACKAGE__->config('View::PDF' => {
   INCLUDE_PATH => __PACKAGE__->path_to('root','pdf_templates')
 });

In your controller:

 $c->stash->{pdf_template} = 'hello_pdf.tt';
 $c->forward('View::PDF');

In F<root/templates/hello_pdf.tt>:

 [% pdf.corefont('Helvetica-Bold') %]

=head1 DESCRIPTION

Catalyst::View::PDF::API2 provides the facility to generate PDF files from
a Catalyst application by embedding L<PDF::API2> commands within a Template
Toolkit template.

=head2 Template Syntax

Within your template you will have access to a C<pdf> object which has
methods corresponding to all of L<PDF::API2>'s functions.

For example, to print the text I<Hello, World> at PDF coordinates 100,100,
use the following directive in your template:

 [% f1 = pdf->corefont('Helvetica') %]
 [% page = pdf.page %]
 [% page.mediabox(595,842) %]
 [% text = page.text %]
 [% text.textlabel(50,800,$f1,20,'Hello, World',-hspace=>75) %]


Data held in the stash can be printed as follows:

 $c->stash->{list} = ['one', 'two', 'three', 'four'];

 [% y = 500 %]
 [% FOREACH item IN list %]
   [% page.textlabel(100,y,$f1,20,item) %]  ###### to fix
   [% y = y - 13 %]
 [% END %]
dav
Formatting can be defined using the Template Toolkit format plugin:

 [% USE format %]
 [% currency = format('£%.2f') %]
 [% page.textlabel(100,100,$f1,20,currency(10)) %]

=head2 Using existing PDF documents

The key benefit of L<PDF::API2> is the ability to load an existing PDF
file and use this as the basis for a new document.

For example, to produce receipts or shipping labels you could create a
blank receipt in Microsoft Word, convert this to PDF, then use PDF::API2
to add in details such as the order number and customer address.

 [% page.textlabel(123,643,$f1,12,order.number) %]
 [% page.textlabel(299,643,$f1,12,order.date) %]

Note that the PDF document loaded by C<pdf.prForm> must be in the same
directory as your Template Toolkit template.

=head1 FUNCTIONS

=head2 process

Render the PDF file, places the contents in C<< $c->response->body >> and
sets appropriate HTTP headers.

You should normally not need to use this method directly, instead forward
to the PDF::API2 view from your controller:

 $c->forward('View::PDF::API2');

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
    my $pdf_filename = $c->stash->{pdf_filename} || (split '/',$c->req->path)[-1] || 'index.pdf';
    $pdf_filename .= '.pdf' unless ($pdf_filename =~ /\.pdf$/i);
    
    my $pdf_disposition = $c->stash->{pdf_disposition} || 'inline';
      
    $c->response->content_type('application/pdf');
    $c->response->headers->header("Content-Disposition" => qq{$pdf_disposition; filename="$pdf_filename"});
    $c->response->body($self->render_pdf($c));
}


=head2 render_pdf

Renders the PDF file and returns the raw PDF data.

If you need to capture the PDF data, e.g. to store in a database or for
emailing, call C<render_pdf> as follows:

 my $pdf = $c->view("PDF::API2")->render_pdf($c);

=cut

sub render_pdf {
    my ($self, $c) = @_;

    #my $tempfile = tmpnam();
    #$c->stash->{tempfile} = $tempfile;
    
    my $template = <<'EOT';
    [% USE Dumper %]
    [% USE pdf2 = Catalyst::View::PDF::API2 %]
    [% Catalyst.log.debug(Dumper.dump($pdf_template)) %]
    [% PROCESS $pdf_template %]
EOT

    $c->stash->{pdf} = PDF::API2->new();

    SEARCH: foreach my $path (@{$self->config->{INCLUDE_PATH}}) {
        if (-e catfile($path,$c->stash->{pdf_template})) {
            local $CWD = $path;
            my $output = $self->render($c,\$template);
	    $c->log->debug("render: $output") if ($self->config->{PDFAPI2_DEBUG});
            last SEARCH;
        }
	$DB::single=1;
	$c->log->debug("pdf_template non trovato") if ($self->config->{PDFAPI2_DEBUG});
    }

    my $pdfout = $c->stash->{pdf}->stringify;
    return $pdfout;
}

=head1 AUTHOR

Ferruccio Zamuner, L<nonsolosoft@diff.org>


=head1 BUGS

Please report any bugs or feature requests to C<bug-catalyst-view-pdf-api2 at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Catalyst-View-PDF-API2>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

 perldoc Catalyst::View::PDF::API2

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Catalyst-View-PDF-API2>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Catalyst-View-PDF-API2>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Catalyst-View-PDF-API2>

=item * Search CPAN

L<http://search.cpan.org/dist/Catalyst-View-PDF-API2>

=back


=head1 SEE ALSO

L<PDF::API|http://search.cpan.org/~areibens/PDF-API2/lib/PDF/API2.pm>

NonSoLoSoft - L<http://www.nonsolosoft.com/>

L<Catalyst::View::PDF::Reuse|http://search.cpan.org/~jonallen/Catalyst-View-PDF-Reuse/lib/Catalyst/View/PDF/Reuse.pm>

=ACKNOWLEDGEMENTS

To every Catalyst developer that has written this framework or its manuals and to any CPAN contributors.

=cut

=head1 COPYRIGHT & LICENSE

Copyright (C) 2009 NonSoLoSoft

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Catalyst::View::PDF::API2
