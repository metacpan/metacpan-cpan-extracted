package Acme::Image::Stb 0.01 {
    use v5.40;
    use Affix qw[:all];
    use Carp  qw[croak];
    use Config;
    use Acme::Image::Stb::ConfigData;
    use parent 'Exporter';
    our %EXPORT_TAGS = ( internals => [qw[stbi_load stbi_write_png stbir_resize_uint8_linear]], core => [qw[load_and_resize]] );
    $EXPORT_TAGS{all} = [ our @EXPORT_OK = sort map {@$_} values %EXPORT_TAGS ];

    # Locate Library
    # We look for: .../auto/Image/Stb/stb.so (or .dll)
    my $lib_name = Acme::Image::Stb::ConfigData->config('lib');
    my $lib_path;
    for my $dir (@INC) {
        my $check = "$dir/auto/Acme/Image/Stb/$lib_name";
        if ( -e $check ) {
            $lib_path = $check;
            last;
        }
    }
    croak "Could not find compiled library '$lib_name' in \@INC" unless $lib_path;
    my $lib = Affix::load_library($lib_path);

    # Bindings
    use constant STBIR_RGBA => 4;
    affix $lib, 'stbi_load',                 [ String, Pointer [Int], Pointer [Int], Pointer [Int], Int ] => Buffer;
    affix $lib, 'stbi_write_png',            [ String, Int, Int, Int, Buffer, Int ]                       => Int;
    affix $lib, 'stbir_resize_uint8_linear', [ Buffer, Int, Int, Int, Buffer, Int, Int, Int, Int ]        => Buffer;

    # API
    sub load_and_resize ( $input, $output, $scale ) {
        my ( $w, $h, $ch ) = ( 0, 0, 0 );

        # Load
        my $img = stbi_load( $input, \$w, \$h, \$ch, 4 );
        return undef if is_null($img);

        # Calculate
        my $nw      = int( $w * $scale );
        my $nh      = int( $h * $scale );
        my $out_buf = "\0" x ( $nw * $nh * 4 );

        # Resize
        my $res = stbir_resize_uint8_linear( $img, $w, $h, 0, $out_buf, $nw, $nh, 0, STBIR_RGBA );
        return undef if is_null($res);

        # Save
        stbi_write_png( $output, $nw, $nh, 4, $out_buf, 0 );
    }
}
1;
__END__

=pod

=encoding utf-8

=head1 NAME

Acme::Image::Stb - Demo of Affix::Build

=head1 SYNOPSIS

    use Acme::Image::Stb;
    load_and_resize( 'input.png', 'output.png', .25 );

=head1 DESCRIPTION

Acme::Image::Stb is a quick demo to go along with the cookbook recipe found here: https://github.com/sanko/Affix.pm/discussions/93

=head1 FUNCTIONS

There's just one.

=head2 C<load_and_resize( $input, $output, $scale )>

Resizes an input image by a given scale.

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library might be free software; you may or may not be able to redistribute it
and/or modify it under... some terms.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=cut
