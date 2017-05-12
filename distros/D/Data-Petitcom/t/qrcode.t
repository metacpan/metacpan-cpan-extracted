use strict;
use warnings;

use Test::More tests => 4;
use Test::Exception;

use Term::ANSIColor ();
use Path::Class;
require( file(__FILE__)->dir->file('util.pl')->absolute->stringify );

BEGIN { use_ok 'Data::Petitcom::QRCode' }

subtest 'new' => sub {
    my $qr = new_ok 'Data::Petitcom::QRCode';
    is $qr->type,    'text';
    is $qr->ecc,     'M';
    is $qr->version, 20;
};

subtest 'version/ecc options' => sub {
    subtest 'version' => sub {
        dies_ok { Data::Petitcom::QRCode::_max_qr_data_size(-1) };
        ok Data::Petitcom::QRCode::_max_qr_data_size(0); # version => 20
        ok Data::Petitcom::QRCode::_max_qr_data_size(24);
        dies_ok { Data::Petitcom::QRCode::_max_qr_data_size(25) };
    };
    subtest 'ecc' => sub {
        for my $ecc (qw/L M H Q/) {
            ok Data::Petitcom::QRCode::_max_qr_data_size(
                20,
                Data::Petitcom::QRCode::QR_ECC->{$ecc}
            );
        }
        ok Data::Petitcom::QRCode::_max_qr_data_size(
            20,
            undef,
        ), 'undefined ecc (default ecc => M)';
        ok Data::Petitcom::QRCode::_max_qr_data_size(
            20,
            Data::Petitcom::QRCode::QR_ECC->{'UNKNOWN_ECC'}
        ), 'unknown ecc (default ecc => M)';
    };
    subtest 'version x ecc' => sub {
        ok Data::Petitcom::QRCode::_max_qr_data_size(4), 'data_size > PTC_OFFSET_DATA';
        dies_ok {
            Data::Petitcom::QRCode::_max_qr_data_size(
                4,
                Data::Petitcom::QRCode::QR_ECC->{'H'},
            );
        }, 'data_size <= PTC_OFFSET_DATA ';
    };
};

subtest 'plot' => sub {
    my $ptc_raw = LoadData('PRG.ptc');

    my $types = {
        text  => sub { $_[0] =~ /^[01]+$/m },
        term  => sub { Term::ANSIColor::colorstrip( $_[0] ) =~ /^ +$/m },
        image => sub {
            # PNG signature
            join( '', unpack( 'H16', $_[0] ) ) =~ /^89504E470D0A1A0A$/i;
        },
    };
    for my $type ( keys %$types ) {
        subtest $type => sub {
            if ( $type eq 'image' && ( $^O eq 'MSWin32' || $^O eq 'cygwin') ) {
                plan skip_all => 'skip the test of GD.dll in Windows';
            }
            my $qr = Data::Petitcom::QRCode->new( type => $type );
            my $qrcode = $qr->plot($ptc_raw);
            cmp_ok @$qrcode, '==', 1;
            ok $types->{$type}->( $qrcode->[0] );
        };
    }

    subtest 'plot_qrcode' => sub {
        my $qrcode = Data::Petitcom::QRCode::plot_qrcode($ptc_raw, version => 4);
        cmp_ok @$qrcode, '==', 3;
    };
};
