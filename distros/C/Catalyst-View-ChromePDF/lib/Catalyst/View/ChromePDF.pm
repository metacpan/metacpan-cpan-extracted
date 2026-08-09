package Catalyst::View::ChromePDF;

use v5.24;

use Moose;
extends 'Catalyst::View';

use File::Spec;
use IO::File::WithPath;
use Log::Log4perl ':easy';
use MooseX::Aliases;
use Path::Tiny qw( path );
use Scalar::Util qw( blessed );
use Types::Common qw( Enum HashRef InstanceOf NonEmptySimpleStr StrMatch );
use WWW::Mechanize::Chrome;

# RECOMMEND PREREQ: Catalyst::View::TT
# RECOMMEND PREREQ: Type::Tiny::XS

use namespace::autoclean;

use experimental qw( signatures try );

our $VERSION = 'v0.1.1';

Log::Log4perl->easy_init($WARN);

# ABSTRACT: convert HTML (or TT) content to PDF using Chrome


has tmpdir => (
    is         => 'ro',
    isa        => InstanceOf['Path::Tiny'],
    lazy_build => 1,
    builder    => '_build_tmpdir',
);

sub _build_tmpdir($self) {
    return path( File::Spec->tmpdir )->mkdir
}


has tt_view => (
    is      => 'ro',
    isa     => StrMatch[ qr/^[A-Z]\w*(::\w+)*$/a ],
    default => 'TT',
);


has stash_key => (
    is      => 'ro',
    isa     => NonEmptySimpleStr,
    default => 'pdf',
);


has chrome_args => (
    is      => 'ro',
    isa     => HashRef,
    default => sub($self) { {} },
);


my $PageSizes = Enum [ keys %WWW::Mechanize::Chrome::PaperFormats ];

has format => (
    is         => 'ro',
    isa        => $PageSizes,
    alias      => 'page_size',
    default    => 'a4',
);


my $Orientations = Enum [qw( portrait landscape )];

has orientation => (
    is         => 'ro',
    isa        => $Orientations,
    default    => 'portrait',
);


my $Dispositions = Enum[ qw( inline attachment ) ];

has 'disposition' => (
    is      => 'rw',
    isa     => $Dispositions,
    default => 'inline',
);


has 'filename' => (
    is      => 'rw',
    isa     => NonEmptySimpleStr,
    default => 'output.pdf',
);


sub process( $self, $c ) {

    my $args = $c->stash->{ $self->stash_key };

    $c->res->body( $self->render( $c, $args // { } ) );

    my $disposition = $Dispositions->assert_return( $args->{disposition} // $self->disposition );
    my $filename    = $args->{filename} // $self->filename;

    $c->res->header(
        "Content-Disposition" => "${disposition}; filename*=UTF-8''${filename}",
        "Content-Type" => "application/pdf",
    );

    return 1;
}


sub render( $self, $c, $args ) {

    my $html;
    my $template = $args->{template} // $c->stash->{template};
    if ( defined $template ) {
        $html = $c->view( $self->tt_view )->render( $c, $template );
    }
    else {
        $html = $args->{html} // $c->res->body;
        if ( blessed($html) && $html->isa("IO::File") ) {
            die "Filehandles are not supported";
        }
    }
    die 'Void-input' unless defined $html;

    my $file = Path::Tiny->tempfile(
        DIR    => $self->tmpdir->stringify,
        SUFFIX => ".html",
        UNLINK => 1,
    );

    $c->log->debug("Saving the HTML to ${file}");
    $file->spew_raw($html);

    my $mech = $args->{mech} // WWW::Mechanize::Chrome->new(
        headless         => 1,
        separate_session => 1,
        $self->chrome_args->%*
    );

    try {
        my $res = $mech->get_local( $file->stringify );

        if ( $res->is_success ) {

            my $out = Path::Tiny->tempfile(
                DIR    => $self->tmpdir,
                SUFFIX => ".pdf",
                UNLINK => 0,
            );

            my $res;

            my %opts = $self->_build_pdf_options( $c, $args );

            if ( $args->{send_filehandle} ) {

                $c->log->debug("Saving the PDF to ${out}");

                $mech->content_as_pdf( %opts, filename => $out->stringify );
                $res = IO::File::WithPath->new( $out, '<:raw' );

            }
            else {

                $res = $mech->content_as_pdf(%opts);

            }

            return $res;

        }

    }
    catch ($e) {

        $c->log->error("$e");
        $c->error("$e");

    }

    return 0;
}


sub _build_pdf_options( $self, $, $args ) {

    my $size = $PageSizes->assert_return( $args->{page_size} // $args->{format} // $self->format );
    my ( $width, $height ) = map { $WWW::Mechanize::Chrome::PaperFormats{$size}{$_} } qw( width height );

    my $orientation = $Orientations->assert_return( $args->{orientation} // $self->orientation );
    if ( $orientation eq "landscape" ) {
        ( $width, $height ) = ( $height, $width );
    }

    my %opts = (
        paperWidth  => $args->{paper_width}  // $width,
        paperHeight => $args->{paper_height} // $height,
    );

    return %opts;
}


__PACKAGE__->meta->make_immutable();

__END__

=pod

=encoding UTF-8

=for stopwords PDFs TT html mech pdf tmpdir wkhtmltopdf

=head1 NAME

Catalyst::View::ChromePDF - convert HTML (or TT) content to PDF using Chrome

=head1 VERSION

version v0.1.1

=head1 SYNOPSIS

In your application, create a view, e.g. F<lib/MyApp/View/ChromePDF.pm>:

    package MyApp::View::ChromePDF;

    use Moose;
    extends 'Catalyst::View::ChromePDF';

    __PACKAGE__->meta->make_immutable();

In the application, e.g. F<lib/MyApp.pm> specify the L</CONFIGURATION>:

    __PACKAGE__->config(

        # Configure Template-Toolkit

        'View::TT' => {
            INCLUDE_PATH       => [ __PACKAGE__->path_to('root'), ],
            ENCODING           => 'utf-8',
            TIMER              => 0,
            TEMPLATE_EXTENSION => '.tt',
            ABSOLUTE           => 1,
            render_die         => 1
        },

        # Configure View::ChromePDF

        'View::ChromePDF' => {
            stash_key => 'pdf',
            page_size => 'a4',
        },

    );

In a controller method, specify L</PARAMETERS>:

    $c->stash->{pdf} = {
      template  => 'base.tt',
      page_size => 'a5',      # override default
    };

    $c->forward('View::ChromePDF');

=head1 DESCRIPTION

This is a L<Catalyst> view for rendering web pages of PDFs using Chrome or a Chrome-compatible browser with
L<WWW::Mechanize::Chrome>.

It is intended as a successor to L<Catalyst::View::Wkhtmltopdf>.

=head1 CONFIGURATION

=head2 tmpdir

This is the temporary directory.

It defaults to the L<File::Spec> C<tmpdir>.

See L</SECURITY CONSIDERATIONS> below.

=head2 tt_view

This is the template view. It defaults to "TT" for L<Catalyst::View::TT>.

=head2 stash_key

It defaults to "pdf".

Note: for L<Catalyst::View::Wkhtmltopdf> compatibility, use "wk".

=head2 chrome_args

This contains additional arguments to pass to the constructor of L<WWW::Mechanize::Chrome>.

This will be ignored if a separate L</mech> argument is passed in the stash.

=head2 format

This is the paper format. It defaults to C<undef>.

=head2 page_size

This is an alias for L</format>, for compatibility with L<Catalyst::View::Wkhtmltopdf>.

=head2 orientation

The is the orientation, it defaults to "portrait".

Acceptable values are "portrait" or "landscape".

=head2 disposition

This is the download disposition. It defaults to "inline".

Acceptable values are "inline" or "attachment".

=head2 filename

This is the attachment filename. It defaults to F<output.pdf>.

=head1 METHODS

=head2 process

=head2 render

=head1 PARAMETERS

=head2 template

This this is not specified, then it will default to using C<$c->stash->{template}>.

=head2 html

This is the raw HTML to render, if no L</template> is specified.

Otherwise, it will render the L<Catalyst::Response> body.

=head2 mech

This is a L<WWW::Mechanize::Chrome> instance.

If omitted, a new instance will be created and then closed, using the L</chrome_args>.

=head2 send_filehandle

=head2 format

This is the format or paper size.

=head2 page_size

This is the same as C<format>, but is added for compatibility with L<Catalyst::View::Wkhtmltopodf>.

=head2 paper_width

=head2 paper_height

Specify the paper width and height as an alternative to specifying the L</format>.

These are in inches, as that is what L<WWW::Mechanize::Chrome> uses.

=head2 orientation

=head1 COMPATIBILITY

=head2 Differences from Catalyst::View::Wkhtmltopdf

=over 4

=item *

There is no C<command> attribute.

Instead, you need to specify the C<launch_exe> path in L</chrome_args>, e.g.

    <View::ChromePDF>
      <chrome_args>
        launch_exe /opt/chrome/bin/chrome
      </chrome_args>
    </View::ChromePDF>

Additional command-line switches should be specified using C<launch_arg>.

=item *

C<orientation> must be lowercase, e.g. "portrait" instead of "Portrait".

=item *

L</stash_key> has a different default.

=item *

Margins, DPI, and image quality options are not supported.

Some of these options may be added in the future.

=back

=head1 SECURITY CONSIDERATIONS

=head2 HTML

It is assumed that the content of the rendered HTML that as saved as a PDF is controlled and trusted by the developer.

The default configuration of L</mech> does not block C<file:> URLs.
That is a feature, not a bug or oversight.

=head2 Temporary Files

Temporary HTML and PDF files are saved in L</tmpdir>.
They may be left in the directory on failure.

When returning a filehandle instead of the PDF content, the PDF files are not removed when L</send_filehandle> is true.

A separate process will need to purge files, to prevent them from filling the disk, as well as to remove sensitive information.

=head1 SOURCE

The development version is on github at L<https://github.com/robrwo/perl-Catalyst-View-ChromePDF>
and may be cloned from L<https://github.com/robrwo/perl-Catalyst-View-ChromePDF.git>

=head1 SUPPORT

Only the latest version of this module will be supported.

This module requires Perl v5.24 or later.
Future releases may only support Perl versions released in the last ten (10) years.

=head2 Reporting Bugs and Submitting Feature Requests

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/robrwo/perl-Catalyst-View-ChromePDF/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head2 Reporting Security Vulnerabilities

Security issues should not be reported on the bugtracker website.
Please see F<SECURITY.md> for instructions how to report security vulnerabilities

=head1 AUTHOR

Robert Rothenberg <perl@rhizomnic.com>

The initial development of this module was sponsored in part by Science Photo Library L<https://www.sciencephoto.com>.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Robert Rothenberg <perl@rhizomnic.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
