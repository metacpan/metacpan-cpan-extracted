#! perl

use Test2::V0;
use Astro::FITS::CFITSIO::FileName;

sub FileName {
    Astro::FITS::CFITSIO::FileName->new( @_ );
}

sub _dumper {
    require Data::Dump;
    Data::Dump::pp( @_ );
}

subtest api => sub {

    my $err;
    my %args;
    like( dies {  FileName( \%args ) },
          qr/missing required arguments/i,
          'no arguments'
        ) or note $err;

    like( dies {  FileName( undef ) },
          qr/can't parse filename/i,
          'undef filename',
        ) or note $err;

};

subtest 'new from string' => sub {

    my %Test = (

        'foo.tar.gz' => object {
            call base_filename => 'foo.tar.gz';
            call filename      => 'foo.tar.gz';
        },

        'foo.tar.gz(output)' => object {
            call base_filename => 'foo.tar.gz';
            call output_name   => 'output';
            call filename      => 'foo.tar.gz(output)';
        },

        'file://foo.tar.gz(output)[compress stuff]' => object {
            call file_type     => 'file://';
            call base_filename => 'foo.tar.gz';
            call output_name   => 'output';
            call compress_spec => 'stuff';
            call filename      => 'file://foo.tar.gz(output)[compress stuff]';
        },

        'file://foo.tar.gz(output)[1:512, 1:256]' => object {
            call file_type     => 'file://';
            call base_filename => 'foo.tar.gz';
            call output_name   => 'output';
            call image_section => [ '1:512', '1:256' ];
            call filename      => 'file://foo.tar.gz(output)[1:512,1:256]';
        },

        'file://foo.tar.gz(output)[events]' => object {
            call file_type     => 'file://';
            call base_filename => 'foo.tar.gz';
            call output_name   => 'output';
            call extname       => 'events';
            call filename      => 'file://foo.tar.gz(output)[events]';
        },

        'file://foo.tar.gz[events]' => object {
            call file_type     => 'file://';
            call base_filename => 'foo.tar.gz';
            call extname       => 'events';
            call filename      => 'file://foo.tar.gz[events]';
        },

        'file://foo.tar.gz[events, 2]' => object {
            call file_type     => 'file://';
            call base_filename => 'foo.tar.gz';
            call extname       => 'events';
            call extver        => 2;
            call filename      => 'file://foo.tar.gz[events,2]';
        },

        'file://foo.tar.gz[events, 2, b]' => object {
            call file_type     => 'file://';
            call base_filename => 'foo.tar.gz';
            call extname       => 'events';
            call extver        => 2;
            call xtension      => 'b';
            call filename      => 'file://foo.tar.gz[events,2,b]';
        },

        'file://foo.tar.gz[events, 2, b; image()]' => object {
            call file_type       => 'file://';
            call base_filename   => 'foo.tar.gz';
            call extname         => 'events';
            call extver          => 2;
            call xtension        => 'b';
            call image_cell_spec => 'image()';
            call filename        => 'file://foo.tar.gz[events,2,b;image()]';
        },

        'file://foo.tar.gz[events][binr foo][bin bar]' => object {
            call file_type     => 'file://';
            call base_filename => 'foo.tar.gz';
            call extname       => 'events';
            call bin_spec      => array {
                item hash {
                    field datatype => 'r';
                    field expr     => 'foo';
                    end;
                };
                item hash {
                    field expr     => 'bar';
                    end;
                };
                end;
            };
            call filename      => 'file://foo.tar.gz[events][binr foo][bin bar]';
        },

        'file://foo.tar.gz[events][bin]' => object {
            call file_type     => 'file://';
            call base_filename => 'foo.tar.gz';
            call extname       => 'events';
            call bin_spec      => array {
                item hash {
                    end;
                };
                end;
            };
            call filename      => 'file://foo.tar.gz[events][bin]';
        },

        'file://foo.tar.gz[events][rowfilter1][rowfilter2]' => object {
            call file_type     => 'file://';
            call base_filename => 'foo.tar.gz';
            call extname       => 'events';
            call row_filter    => array {
                item 'rowfilter1';
                item 'rowfilter2';
                end;
            };
            call filename      => 'file://foo.tar.gz[events][rowfilter1][rowfilter2]';
        },

        'file://foo.tar.gz[2]' => object {
            call file_type     => 'file://';
            call base_filename => 'foo.tar.gz';
            call hdunum        => '2';
            call filename      => 'file://foo.tar.gz[2]';
        },

        'file://foo.tar.gz[2; image() ]' => object {
            call file_type       => 'file://';
            call base_filename   => 'foo.tar.gz';
            call hdunum          => '2';
            call image_cell_spec => 'image()';
            call filename        => 'file://foo.tar.gz[2;image()]';
        },

        'file://foo.tar.gz[2; image() ][pixr1 expr(ffo)]' => object {
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
        },

    );

    for my $filename ( keys %Test ) {

        my $check = $Test{$filename};
        my $object;

        subtest $filename => sub {
            ok(
                lives {
                    $object = FileName( $filename )
                },
                'creation'
            ) or diag $@;

            is( $object, $check, 'contents' )
              or note _dumper( $object->to_hash );
        };
    }

    todo "properly parse row filters. this isn't a row filter" => sub {
        my $object;
        like( dies { $object = FileName( 'foo.tar.gz[1:512]' ) },
          qr/foo/
        ) or note _dumper( $object->to_hash );
    };

};

subtest 'round trip' => sub {

    my $filename = 'file://foo.tar.gz[2; image() ][pixr1 expr(ffo)]';
    my $check = object {
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


    my $obj1 = FileName( $filename );
    is ( $obj1, $check, 'first object' );

    my $attr = $obj1->to_hash;
    my $obj2 = FileName( $attr );
    is ( $obj2, $check, 'second object' );
};

subtest 'overload' => sub {

    my $obj = FileName('file://foo.tar.gz[2; image() ][pixr1 expr(ffo)]');

    is ( "$obj", $obj->filename );

};

done_testing;

1;
