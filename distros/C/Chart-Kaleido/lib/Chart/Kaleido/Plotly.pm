package Chart::Kaleido::Plotly;

# ABSTRACT: Export static images of Plotly charts using Kaleido

use 5.010;
use strict;
use warnings;

our $VERSION = '0.014'; # VERSION

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


my $default_plotlyjs = sub {
    my $plotlyjs;
    eval {
        $plotlyjs = File::ShareDir::dist_file( 'Chart-Plotly',
            'plotly.js/plotly.min.js' );
    };  
    return $plotlyjs;
};

has plotlyjs => (
    is      => 'ro',
    isa     => ( Str->plus_coercions( Undef, $default_plotlyjs ) | Undef ),
    default => $default_plotlyjs,
    coerce  => 1,
);

has [qw(mathjax topojson)] => (
    is     => 'ro',
    isa    => ( Str | Undef ),
    coerce => 1,
);

has mapbox_access_token => (
    is  => 'ro',
    isa => ( Str | Undef ),
);


my $PositiveInt = Int->where( sub { $_ > 0 } );

has default_format => (
    is      => 'ro',
    isa     => Str,
    default => 'png',
);

has default_width => (
    is      => 'ro',
    isa     => $PositiveInt,
    default => 700,
);

has default_height => (
    is      => 'ro',
    isa     => $PositiveInt,
    default => 500,
);

has '+base_args' => (
    default => sub {
        my $self = shift;
        [ "plotly", @{ $self->_default_chromium_args }, "--no-sandbox" ];
    }
);

sub all_formats { [qw(png jpg jpeg webp svg pdf eps json)] }
sub scope_name  { 'plotly' }
sub scope_flags { [qw(plotlyjs mathjax topojson mapbox_access_token)] }


sub transform {
    my $self = shift;
    state $check = compile_named_oo(
    #<<< no perltidy
        plot   => ( HashRef | InstanceOf["Chart::Plotly::Plot"] ),
        format => Optional[Str], { default => sub { $self->default_format } },
        width  => $PositiveInt, { default => sub { $self->default_width } },
        height => $PositiveInt, { default => sub { $self->default_height} },
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

    local *PDL::TO_JSON = sub { $_[0]->unpdl };
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
        width  => $PositiveInt, { default => sub { $self->default_width } },
        height => $PositiveInt, { default => sub { $self->default_height} },
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
    path($file)->append_raw( { truncate => 1 }, $img );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Chart::Kaleido::Plotly - Export static images of Plotly charts using Kaleido

=head1 VERSION

version 0.014

=head1 SYNOPSIS

    use Chart::Kaleido::Plotly;
    use JSON;

    my $kaleido = Chart::Kaleido::Plotly->new();

    # convert a hashref
    my $data = decode_json(<<'END_OF_TEXT');
    { "data": [{"y": [1,2,1]}] }
    END_OF_TEXT
    $kaleido->save( file => "foo.png", plot => $data,
                    width => 1024, height => 768 );

    # convert a Chart::Plotly::Plot object
    use Chart::Plotly::Plot;
    my $plot = Chart::Plotly::Plot->new(
        traces => [
            Chart::Plotly::Trace::Scatter->new( x => [ 1 .. 5 ], y => [ 1 .. 5 ] )
        ]
    );
    $kaleido->save( file => "foo.png", plot => $plot,
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

=head2 default_format

Default is "png".

=head2 default_width

Default is 700.

=head2 default_height

Default is 500.

=head1 METHODS

=head2 transform

    transform(( HashRef | InstanceOf["Chart::Plotly::Plot"] ) :$plot,
              Str :$format=$self->default_format,
              PositiveInt :$width=$self->default_width,
              PositiveInt :$height=$self->default_height,
              Num :$scale=1)

Returns raw image data.

=head2 save

    save(:$file,
         ( HashRef | InstanceOf["Chart::Plotly::Plot"] ) :$plot,
         Optional[Str] :$format,
         PositiveInt :$width=$self->default_width,
         PositiveInt :$height=$self->default_height,
         Num :$scale=1)

Save static image to file.

=head1 SEE ALSO

L<https://github.com/plotly/Kaleido>

L<Chart::Plotly>,
L<Chart::Kaleido>,
L<Alien::Plotly::Kaleido>

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020-2023 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
