package Catalyst::View::Wkhtmltopdf;
use Moose;

# ABSTRACT: Catalyst view to convert HTML (or TT) content to PDF using wkhtmltopdf

extends 'Catalyst::View';

use version 0.77;
our $VERSION = 'v0.6.1';

use B;
use File::Temp;
use URI::Escape;
use File::Spec;
use File::Which qw( which );
use IO::File::WithPath;
use IPC::Run3 qw( run3 );

use namespace::autoclean;

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
    default => sub { which('wkhtmltopdf') }
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

    # Create a temporary file
    use File::Temp;
    my $htmlf = File::Temp->new(
        DIR     => $self->tmpdir,
        SUFFIX  => '.html',
        UNLINK  => 1,
    );
    binmode $htmlf, ':raw';
    my $htmlfn = $htmlf->filename;
    my $pdffn  = $htmlfn;
    $pdffn =~ s/\.html/.pdf/;

    print $htmlf $html;

    my @args;

    if ( defined $args->{page_width} && defined $args->{page_height} ) {
        # Custom page size overrides page_size
        push @args, '--page-width', B::perlstring( $args->{page_width} ),
                    '--page-height', B::perlstring( $args->{page_height} );
    }
    else {
        # Usual page size A4, but labels would need a smaller one
        push @args, '--page-size', B::perlstring( $args->{page_size} || $self->page_size );
    }
    push @args, '--orientation', B::perlstring( $args->{orientation} || $self->orientation );

    push @args, '--allow', B::perlstring( $self->tmpdir );
    for my $allow ( @{ $self->allows } ) {
        push @args, '--allow', B::perlstring($allow);
    }

    for my $name ( qw( margin_top margin_left margin_bottom margin_right dpi image_dpi image_quality title ) ) {
        my $arg = $args->{$name};
        next unless defined $arg;
        die "${name} cannot contain newlines or control characters" if $arg =~ /[\N{U+00}-\N{U+1f}\#\|;\&]/;
        my $param = $name;
        $param =~ s/_/-/g;
        push @args, "--${param}", B::perlstring($arg)
    }

    for my $name ( qw( greyscale lowquality quiet no_background no_images disable_javascript print_media_type ) ) {
        my $arg = $args->{$name} or next;
        my $param = $name;
        $param =~ s/_/-/g;
        push @args, "--${param}";
    }

    push @args, $htmlfn, $pdffn;

    my $input = join(" ", @args);

    my @cmd = split /\s+/, $self->command;

    my %opt = map +( "binmode_std$_" => ":raw" ), "in", "out", "err";
    run3 [ @cmd, '--read-args-from-stdin' ], \ $input, \my $output, \my $err, \%opt;

    $c->log->debug($err) if $err;

    # Read the output and return it
    return IO::File::WithPath->new( $pdffn, '<:raw' );
}

__PACKAGE__->meta->make_immutable();

1;

__END__

=pod

=encoding UTF-8

=for stopwords QtWebKit epr greyscale lowquality pdf tmpdir TT wkhtmltopdf

=head1 NAME

Catalyst::View::Wkhtmltopdf - Catalyst view to convert HTML (or TT) content to PDF using wkhtmltopdf

=head1 VERSION

version v0.6.1

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

=head1 STATUS

The wkhtmltopdf project is no longer being maintained, and this module will be deprecated in a later release.

See L</SECURITY CONSIDERATIONS>.

=head1 DESCRIPTION

C<Catalyst::View::Wkhtmltopdf> is a L<Catalyst> view handler that
converts HTML data to PDF using C<wkhtmltopdf>.
It can also handle direct conversion of L<Template-Toolkit|Template> templates via L<Catalyst::View::TT>.

=head1 CONFIG VARIABLES

All configuration parameters are optional as they have a default.

=head2 stash_key

The stash key which contains data and optional runtime configuration
to pass to the view. Default is C<wk>.

=head2 tmpdir

Default: guessed via C<File::Spec::tmpdir()>.

Name of URI parameter to specify JSON callback function name. Defaults
to C<callback>. Only effective when C<allow_callback> is turned on.

=head2 command

Default: C</usr/bin/wkhtmltopdf>.

The full path and filename to the wkhtmltopdf command. Defaults to
I</usr/bin/wkhtmltopdf>.

=head2 allows

Default: the temporary directory.

An arrayref of allowed paths where wkhtmltopdf can find images and
other linked content. The temporary directory is added by default.
See wkhtmltopdf documentation for more information.

=head2 disposition

Default: C<inline>.

The I<content-disposition> to set when sending the PDF file to the
client. Can be either I<inline> or (default) I<attachment>.

=head2 filename

Default: F<output.pdf>.

The filename to send to the client.

=head2 page_size

Default: C<A4>.

Page size option.
See wkhtmltopdf documentation for more information.

=head2 orientation

Default: C<portrait>.

Orientation option.
See wkhtmltopdf documentation for more information.

=head1 PARAMETERS

Parameters are passed via the stash:

    $c->stash->{wkhtmltopdf} = {
        html    => $web_page,
    };

You can pass the following configuration options here, which will
override the global configuration: I<disposition>, I<filename>,
I<page_size>.

=head2 page_width

=head2 page_height

Width and height of the page, overrides I<page_size>.

=head2 margin_top

=head2 margin_right

=head2 margin_ bottom

=head2 margin_left

Margins, specified as I<3mm>, I<0.7in>, ...

=head2 dpi

=head2 image_dpi

=head2 image_quality

=head2 title

=head2 greyscale

=head2 lowquality

=head2 quiet

=head2 no_background

=head2 no_images

=head2 disable_javascript

=head2 print_media_type

Have a look at wkhtmltopdf documentation for more information regarding these options.

Other options can be added to the L</command>.

=head1 METHODS

=head2 process

Generated the PDF as epr parameters in `$c->stash->{wkhtmltopdf}` or other
configured stash key. Calls L</render> to perform actual rendering.
Output is stored in C<$c->response->body>.

It is possible to forward to the process method of the view from inside
L<Catalyst>:

    $c->forward('View::Wkhtmltopdf');

However, this is usually done automatically by L<Catalyst::Action::RenderView>.

=head2 render

Generates a PDF from the arguments in I<\%args> and returns it.
Arguments are the same one would place in the stash key for
rendering + output via C<process()>, but the following are
(of course) ignored: I<disposition>, I<filename> (as they
only apply when outputting the content to the client).

You can pass a I<template_args> key inside the arguments
hashref, which will be passed to L<Catalyst::View::TT>'s
C<render> method. If not supplied, undef will be passed,
so the TT view method will behave as per its documentation.

=head1 SECURITY CONSIDERATIONS

B<Do not use wkhtmltopdf with untrusted HTML.>

The wkhtmltopdf project L<is no longer being maintained|https://wkhtmltopdf.org/status.html>,
and the underlying QtWebKit libraries that it uses have been unsupported since 2015.

The L<git repository|https://github.com/wkhtmltopdf/wkhtmltopdf> was archived as read-only in 2023.

You should consider migrating to alternative solutions.

It is assumed that the L</command> attribute is configured by a trusted source (developer or operator).

The options are sent to wkhtmltopdf via stdin, using the C<--read-args-from-stdin> option.
However, any options configured through the web application should be considered untrusted and validated.

=begin :readme

=head1 prepend:REQUIREMENTS

L<wkhtmltopdf|https://wkhtmltopdf.org> must be installed.

=end :readme

=head1 SEE ALSO

L<Catalyst>

L<Catalyst::View::TT>

L<https://wkhtmltopdf.org>

=head1 SOURCE

The development version is on github at L<https://github.com/robrwo/Catalyst-View-Wkhtmltopdf>
and may be cloned from L<https://github.com/robrwo/Catalyst-View-Wkhtmltopdf.git>

Note that the git repository has changed since version v0.6.0.

=head1 SUPPORT

Only the latest version of this module will be supported.

Future releases may only support Perl versions released in the last ten (10) years.

Please report any bugs or feature requests on the bugtracker website
L<https://rt.cpan.org/Public/Dist/Display.html?Name=Catalyst-View-Wkhtmltopdf>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head2 Reporting Security Vulnerabilities

If the bug you are reporting has security implications which make it inappropriate to send to a public issue tracker,
then see F<SECURITY.md> for instructions how to report security vulnerabilities.

=head1 AUTHOR

Michele Beltrame <mb@italpro.net>

This module is currently maintained by Robert Rothenberg <perl@rhizomnic.com>.

=head1 CONTRIBUTORS

=for stopwords Jens Gassmann Robert Rothenberg

=over 4

=item *

Jens Gassmann <jens.gassmann@atomix.de>

=item *

Robert Rothenberg <perl@rhizomnic.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011-2018, 2026 by Michele Beltrame <mb@italpro.net>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
