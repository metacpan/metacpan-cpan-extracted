package Catalyst::View::Wkhtmltopdf;
use Moose;

extends 'Catalyst::View';

use version;
our $VERSION = qv('0.5.2');

use File::Temp;
use URI::Escape;
use Path::Class;
use File::Spec;

has 'stash_key' => (
    is      => 'rw',
    isa     => 'Str',
    lazy    => 1,
    default => sub { 'wk' }
);
has 'tmpdir' => (
    is      => 'rw',
    isa     => 'Str',
    lazy    => 1,
    default => sub { File::Spec->tmpdir() }
);
has 'command' => (
    is      => 'rw',
    isa     => 'Str',
    lazy    => 1,
    default => sub { '/usr/bin/wkhtmltopdf' }
);
has 'tt_view' => (
    is      => 'rw',
    isa     => 'Str',
    lazy    => 1,
    default => sub { 'TT' }
);
has 'page_size' => (
    is      => 'rw',
    isa     => 'Str',
    lazy    => 1,
    default => sub { 'a4' }
);
has 'orientation' => (
    is      => 'rw',
    isa     => 'Str',
    lazy    => 1,
    default => sub { 'Portrait' }
);
has 'disposition' => (
    is      => 'rw',
    isa     => 'Str',
    lazy    => 1,
    default => sub { 'inline' }
);
has 'filename' => (
    is      => 'rw',
    isa     => 'Str',
    lazy    => 1,
    default => sub { 'output.pdf' }
);
has 'allows' => (
    is      => 'rw',
    isa     => 'ArrayRef',
    lazy    => 1,
    default => sub { [] }
);

sub process {
    my ( $self, $c ) = @_;

    my $wk = $c->stash->{ $self->stash_key };

    my $pdfcontent = $self->render($c, $wk);

    my $disposition = $wk->{disposition} || $self->disposition;
    my $filename = uri_escape_utf8( $wk->{filename} || $self->filename );
    $c->res->header(
        'Content-Disposition' => "$disposition; filename*=UTF-8''$filename",
        'Content-type'        => 'application/pdf',
    );
    $c->res->body($pdfcontent);
}

sub render {
    my ( $self, $c, $args ) = @_;
    
    # Arguments for TT view - if not defined those will be the stash
    # as per C::V::TT documentation
    if (!$args->{template_args}) { $args->{template_args} = undef }
    
    my $html;
    if ( defined $args->{template} ) {
        $html = $c->view( $self->tt_view )->render( $c, $args->{template} ) or die;
    } else {
        $html = $args->{html};
    }
    die 'Void-input' if !defined $html;

    # Usual page size A4, but labels would need a smaller one so we leave it
    my $page_size = '--page-size ' . ( $args->{page_size} || $self->page_size );

    # Page Orientation
    my $orientation = '--orientation ' . ( $args->{orientation} || $self->orientation );

    # Custom page size will override the previous
    if ( defined $args->{page_width} && defined $args->{page_height} ) {
        $page_size = "--page-width $args->{page_width} --page-height $args->{page_height} ";
    }

    # Create a temporary file
    use File::Temp;
    my $htmlf = File::Temp->new(
        DIR     => $self->tmpdir,
        SUFFIX  => '.html',
        UNLINK  => 1,
    );
    binmode $htmlf, ':utf8';
    my $htmlfn = $htmlf->filename;
    my $pdffn  = $htmlfn;
    $pdffn =~ s/\.html/.pdf/;

    print $htmlf $html;

    # Build wkhtmltopdf command line
    my $hcmd = $self->command . ' ' . $page_size . ' ' . $orientation . " ";
    $hcmd .= "--allow " . $self->tmpdir . " ";

    for my $allow ( @{ $self->allows } ) {
        $hcmd .= '--allow ' . $allow . ' ';
    }
    $hcmd .= "--margin-top $args->{margin_top} "       if exists $args->{margin_top};
    $hcmd .= "--margin-left $args->{margin_left} "     if exists $args->{margin_left};
    $hcmd .= "--margin-bottom $args->{margin_bottom} " if exists $args->{margin_bottom};
    $hcmd .= "--margin-right $args->{margin_right} "   if exists $args->{margin_right};
    $hcmd .= " $htmlfn $pdffn";

    # Create the PDF file
    my $output = `$hcmd`;
    die "$! [likely can't find wkhtmltopdf command!]" if $output;

    # Read the output and return it
    my $pdffc      = Path::Class::File->new($pdffn);
    my $pdfcontent = $pdffc->slurp();
    $pdffc->remove();
    
    return $pdfcontent;
}

__PACKAGE__->meta->make_immutable();

1;

__END__

=head1 NAME

Catalyst::View::Wkhtmltopdf - Catalyst view to convert HTML (or TT) content to PDF using wkhtmltopdf

=head1 SYNOPSIS

    # lib/MyApp/View/Wkhtmltopdf.pm
    package MyApp::View::Wkhtmltopdf;
    use Moose;
    extends qw/Catalyst::View::Wkhtmltopdf/;
    __PACKAGE__->meta->make_immutable();
    1;
    
    # configure in lib/MyApp.pm
    MyApp->config({
      ...
      'View::Wkhtmltopdf' => {
          command   => '/usr/local/bin/wkhtmltopdf',
          # Guessed via File::Spec by default
          tmpdir    => '/usr/tmp',
          # Name of the Template view, "TT" by default
          tt_view   => 'Template',
      },
    });
    
    sub ciao : Local {
        my($self, $c) = @_;
        
        # Pass some HTML...
        $c->stash->{wk} = {
            html    => $web_page,
        };
        
        # ..or a TT template
        $c->stash->{wk} = {
            template    => 'hello.tt',
            page_size   => 'a5',
        };

        # More parameters...
        $c->stash->{wk} = {
            html        => $web_page,
            disposition => 'attachment',
            filename    => 'mydocument.pdf',
        };
        
        $c->forward('View::Wkhtmltopdf');
    }

=head1 DESCRIPTION

I<Catalyst::View::Wkhtmltopdf> is a L<Catalyst> view handler that
converts HTML data to PDF using wkhtmltopdf (which must be installed
on your system). It can also handle direct conversion of TT templates
(via L<Catalyst::View::TT>).

=head1 CONFIG VARIABLES

All configuration parameters are optional as they have a default.

=over 4

=item stash_key

The stash key which contains data and optional runtime configuration
to pass to the view. Default is I<wk>.

=item tmpdir

Default: guessed via C<File::Spec::tmpdir()>.

Name of URI parameter to specify JSON callback function name. Defaults
to C<callback>. Only effective when C<allow_callback> is turned on.

=item command

Default: C</usr/bin/wkhtmltopdf>.

The full path and filename to the wkhtmltopdf command. Defaults to
I</usr/bin/wkhtmltopdf>.

=item allows

Default: the temporary directory.

An arrayref of allowed paths where wkhtmltopdf can find images and
other linked content. The temporary directory is added by default.
See wkhtmltopdf documentation for more information.

=item disposition

Default: I<inline>.

The I<content-disposition> to set when sending the PDF file to the
client. Can be either I<inline> or (default) I<attachment>.

=item filename

Default: I<output.pdf>.

The filename to send to the client.

=item page_size

Default: I<A4>.

Page size option.
See wkhtmltopdf documentation for more information.

=item orientation

Default: I<portrait>.

Orientation option.
See wkhtmltopdf documentation for more information.

=back

=head1 PARAMETERS

Parameters are passed fvia the stash:

    $c->stash->{wkhtmltopdf} = {
        html    => $web_page,
    };

You can pass the following configuration options here, which will
override the global configuration: I<disposition>, I<filename>,
I<page_size>.

Other options currently supported are:

=over 4

=item page-width, page-height

Width and height of the page, overrides I<page_size>.

=item margin-top, margin-right, margin-bottom, margin-left

Margins, specified as I<3mm>, I<0.7in>, ...

=back

Have a look at I<wkhtmltopdf> documentation for more information
regarding these options.

=head1 METHODS

=over 4

=item process()

Generated the PDF as epr parameters in $c->stash->{wkhtmltopdf} or other
configured stash key. Calls C<render()> to perform actual rendering.
Output is stored in C<$c->response->body>.

It is possible to forward to the process method of the view from inside
L<Catalyst>:

    $c->forward('View::Wkhtmltopdf');

However, this is usually done automatically by L<Catalyst::Action::RenderView>.

=item render($c, \%args)

Generates a PDF from the arguments in I<\%args> and returns it.
Arguments are the same one would place in the stash key for
rendering + output via C<process()>, but the following are
(of course) ignored: I<disposition>, I<filename> (as they
only apply when outputting the content to the client).

You can pass a I<template_args> key inside the arguments
hashref, which will be passed to L<Catalyst::View::TT>'s
C<render()> method. If not supplied, undef will be passed,
so the TT view method will behave as per its documentation.

=back

=head1 CHARACTER ENCODING

At present time this library just uses UTF-8, which means it should
work in most circumstances. Patches are welcome for support of
different character sets.

=head1 REQUIREMENTS

I<wkhtmltopdf> command should be available on your system.

=head1 TODO

More configuration options (all the ones which I<wkhtmltopdf>
supports, likely) should be added. Also, we'll wanto to allow
to override them all at runtime.

We might want to use pipes (L<IPC::Open2>) instead of relying
on temp files.

And yes... we need to write tests!

=head1 CONTRIBUTE

Project in on GitHub:

L<https://github.com/lordarthas/Catalyst-View-Wkhtmltopdf>

=head1 AUTHOR

Michele Beltrame E<lt>arthas@cpan.orgE<gt>

=head1 CONTRIBUTORS

jegade

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Catalyst>, L<Catalyst::View::TT>

L<http://code.google.com/p/wkhtmltopdf/>

=cut
