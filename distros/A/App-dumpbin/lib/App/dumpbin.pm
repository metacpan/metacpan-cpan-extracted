package App::dumpbin 0.02 {
    use 5.008001;
    use strict;
    use warnings;
    use Path::Tiny;
    #
    my %sections;

    sub exports {
        my $file = shift;
        my $raw  = Path::Tiny->new($file)->slurp_raw;
        #
        exit 99 if 0x5A4D != unpack 'v', substr $raw, 0, 2;    # check signature
        my $peo = unpack 'V', substr $raw, 0x3C, 4;
        exit 99 if "PE\0\0" ne substr $raw, $peo, 4;
        #
        my ( $sizeOfOptionalHeader, undef, $magic ) = unpack 'vvv', substr $raw, $peo + 20, 8;
        return if !$sizeOfOptionalHeader;    # No optional COFF and thus no exports
        my $pe32plus   = $magic == 0x20b;    # 32bit: Ox10b 64bit: 0x20b ROM?: 0x107
        my $opt_header = substr $raw, $peo + 24, $sizeOfOptionalHeader;

        # COFF header
        my $numberOfSections = unpack 'v', substr $raw, $peo + 6, 2;

        # Windows "optional" header
        my $imageBase = $pe32plus ? unpack 'Q', substr $opt_header, 24, 8 : unpack 'V',
            substr $opt_header, 28, 4;
        my $numberOfRVAandSizes = unpack 'V', substr $opt_header, ( $pe32plus ? 108 : 112 ), 4;
        {
            %sections = ();
            my $sec_begin = $peo + 24 + $sizeOfOptionalHeader;
            my $sec_data  = substr $raw, $sec_begin, $numberOfSections * 40;
            for my $x ( 0 .. $numberOfSections - 1 ) {
                my $sec_head = $sec_begin + ( $x * 40 );
                my $sec_name = unpack 'Z*', substr $raw, $sec_head, 8;
                $sections{$sec_name} = [ unpack 'VV VVVV vv V', substr $raw, $sec_head + 8 ];
            }
        }

        # dig into directory
        my ( $edata_pos, $edata_len ) = unpack 'VV', substr $opt_header, $pe32plus ? 112 : 96, 8;
        my @fields = unpack 'V10', substr $raw, rva2offset($edata_pos), 40;
        my ( $ptr_func, $ptr_name, $ptr_ord ) = map { rva2offset( $fields[$_] ) } 7 .. 9;
        my %retval = ( name => unpack 'Z*', substr $raw, rva2offset( $fields[3] ), 256 );
        my @ord    = unpack 'V' x $fields[5], substr $raw, $ptr_func, 4 * $fields[5];
        for my $idx ( 0 .. $fields[5] ) {
            my $ord_cur  = unpack 'v', substr $raw, $ptr_ord + ( 2 * $idx ), 2;
            my $func_cur = $ord[$ord_cur];    # Match the ordinal to the function RVA
            next if $idx > ( $fields[6] - 1 );
            my $name_cur = unpack 'V',  substr $raw, $ptr_name + ( 4 * $idx ), 4;
            my $name_str = unpack 'Z*', substr $raw, rva2offset($name_cur), 512;
            $ord_cur += $fields[4];           # Add the ordinal base value
            $retval{exports}{$name_str} = [ $func_cur + $imageBase, $ord_cur ];
        }
        %retval;
    }

    sub rva2offset {
        my ($virtual) = @_;
        for my $section ( values %sections ) {
            if ( ( $virtual >= $section->[1] ) and ( $virtual < $section->[1] + $section->[0] ) ) {
                return $virtual - ( $section->[1] - $section->[3] );
            }
        }
    }
};
1;
__END__

=encoding utf-8

=head1 NAME

App::dumpbin - It's a PE Parser!

=head1 SYNOPSIS

    use App::dumpbin;
    my $exports = App::dumpbin::exports( 'some.dll' );

=head1 DESCRIPTION

App::dumpbin is a pure Perl PE parser with just enough functionality to make
L<FFI::ExtractSymbols::Windows> work without installing Visual Studio for
C<dumpbin>.

Both 32bit (PE32) and 64bit (PE32+) libraries are supported.

The functionality of this may grow in the future but my goal right now is very
narrow.

=head1 See Also

=over

=item L<https://docs.microsoft.com/en-us/windows/win32/debug/pe-format>

=item L<Win32::PEFile>

=item L<Win32::Exe>

=back

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the terms found in the Artistic License 2. Other copyrights, terms, and
conditions may apply to data transmitted through this module.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=begin stopwords


=end stopwords

=cut
