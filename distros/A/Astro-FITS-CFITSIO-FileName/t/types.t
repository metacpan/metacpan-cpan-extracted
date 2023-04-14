#! perl

use Test2::V0;

use Astro::FITS::CFITSIO::FileName::Types 'FitsFileName';

# this is from new.t. should stick it somewhere common
my $filename = 'file://foo.tar.gz[2; image() ][pixr1 expr(ffo)]';
my $check    = object {
    call file_type       => 'file://';
    call base_filename   => 'foo.tar.gz';
    call hdunum          => '2';
    call image_cell_spec => 'image()';
    call pix_filter      => hash {
        field datatype     => 'r';
        field discard_hdus => T();
        field expr         => 'expr(ffo)';
        end;
    };
    call filename => 'file://foo.tar.gz[2;image()][pixr1 expr(ffo)]';
};


subtest 'string' => sub {
    my $obj;
    ok( lives { $obj = FitsFileName->assert_coerce( $filename ) }, 'coerce' );
    is( $obj, $check, 'object' );
};

subtest 'hash' => sub {
    my $obj;
    my $mod_filename = $filename =~ s/\Q[2; image() ]\E//r;
    my %hash         = ( filename => $mod_filename, hdunum => 2, image_cell_spec => 'image()' );

    ok( lives { $obj = FitsFileName->assert_coerce( \%hash ) }, 'coerce' );
    is( $obj, $check, 'attrs' );
};



done_testing;
