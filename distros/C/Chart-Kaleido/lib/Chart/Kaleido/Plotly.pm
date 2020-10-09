package Chart::Kaleido::Plotly;

# ABSTRACT: Export static images of Plotly charts using Kaleido

use 5.010;
use strict;
use warnings;

our $VERSION = '0.004'; # VERSION

use Moo;
extends 'Chart::Kaleido';

use File::ShareDir;
use JSON;
use MIME::Base64 qw(decode_base64);
use Path::Tiny;
use Safe::Isa;
use Type::Params 1.004000 qw(compile_named_oo);
use Types::Path::Tiny qw(File Path);
use Types::Standard qw(Int Str Num HashRef InstanceOf Optional Undef);
use namespace::autoclean;


my @text_formats = qw(svg json eps);


has plotlyjs => (
    is      => 'ro',
    isa     => (Str | Undef),
    coerce  => 1,
    builder => sub {
        my $plotlyjs;
        eval {
            $plotlyjs = File::ShareDir::dist_file( 'Chart-Plotly',
                'plotly.js/plotly.min.js' );
        };
        return $plotlyjs;
    },
);

has [qw(mathjax topojson)] => (
    is     => 'ro',
    isa    => (Str | Undef),
    coerce => 1,
);

has mapbox_access_token => (
    is  => 'ro',
    isa => (Str | Undef),
);


has '+all_formats' =>
  ( default => sub { [qw(png jpg jpeg webp svg pdf eps json)] } );

has '+scope_name' => ( default => 'plotly' );

has '+scope_flags' =>
  ( default => sub { [qw(plotlyjs mathjax topojson mapbox_access_token)] }, );

has '+base_args' =>
  ( default => sub { [ qw(plotly --disable-gpu) ] } );



sub transform {
    my $self = shift;
    state $check = compile_named_oo(
    #<<< no perltidy
        plot   => ( HashRef | InstanceOf["Chart::Plotly::Plot"] ),
        format => Optional[Str],
        width  => Int,
        height => Int,
        scale  => Num, { default => 1 },
    #>>>
    );
    my $arg = $check->(@_);
    my $plot =
        $arg->plot->$_isa('Chart::Plotly::Plot')
      ? $arg->plot->TO_JSON
      : $arg->plot;
    my $format = lc( $arg->format );

    unless ( grep { $_ eq $format } @{ $self->all_formats } ) {
        die "Invalid format '$format'. Supported formats: "
          . join( ' ', @{ $self->all_formats } );
    }

    my $data = {
        format => $format,
        width  => $arg->width,
        height => $arg->height,
        scale  => $arg->scale,
        data   => $plot,
    };
    my $resp = $self->do_transform($data);
    if ( $resp->{code} != 0 ) {
        die $resp->{message};
    }
    my $img = $resp->{result};
    return ( grep { $_ eq $format } @text_formats )
      ? $img
      : decode_base64($img);
}


sub save {
    my $self = shift;
    state $check = compile_named_oo(
    #<<< no perltidy
        file   => Path,
        plot   => ( HashRef | InstanceOf["Chart::Plotly::Plot"] ),
        format => Optional[Str],
        width  => Int,
        height => Int,
        scale  => Num, { default => 1 },
    #>>>
    );
    my $arg    = $check->(@_);
    my $format = $arg->format;
    my $file   = $arg->file;
    unless ($format) {
        if ( $file =~ /\.([^\.]+)$/ ) {
            $format = $1;
        }
    }
    $format = lc($format);

    my $img = $self->transform(
        plot   => $arg->plot,
        format => $format,
        width  => $arg->width,
        height => $arg->height,
        scale  => $arg->scale
    );
    path($file)->spew_raw($img);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Chart::Kaleido::Plotly - Export static images of Plotly charts using Kaleido

=head1 VERSION

version 0.004

=head1 SYNOPSIS

    use Chart::Kaleido::Plotly;
    use JSON;

    my $data = decode_json(<<'END_OF_TEXT');
    { "data": [{"y": [1,2,1]}] }
    END_OF_TEXT

    my $kaleido = Chart::Kaleido::Plotly->new();
    $kaleido->save( file => "foo.png", plot => $data,
                    width => 1024, height => 768 );

=head1 DESCRIPTION

This class wraps the "plotly" scope of plotly's kaleido command.

=head1 ATTRIBUTES

=head2 timeout

=head2 plotlyjs

Path to plotly js file.
Default value is plotly js bundled with L<Chart::Ploly>.

=head2 mathjax

=head2 topojson

=head2 mapbox_access_token

=head2 all_formats

Read-only class attribute. All supported formats.

=head1 METHODS

=head2 transform

    transform(( HashRef | InstanceOf["Chart::Plotly::Plot"] ) :$plot,
              Optional[Str] :$format,
              Int :$width, Int :$height, Num :$scale=1)

Returns raw image data.

=head2 save

    save(:$file,
         ( HashRef | InstanceOf["Chart::Plotly::Plot"] ) :$plot,
         Optional[Str] :$format,
         Int :$width, Int :$height, Num :$scale=1)

Save static image to file.

=head1 SEE ALSO

L<https://github.com/plotly/Kaleido>

L<Chart::Plotly>,
L<Chart::Kaleido>,
L<Alien::Plotly::Kaleido>

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
