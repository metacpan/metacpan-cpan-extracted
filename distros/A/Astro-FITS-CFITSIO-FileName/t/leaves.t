#! perl

use Test2::V0;
use vars '$GRAMMAR';

use Astro::FITS::CFITSIO::FileName::Regexp;

our $GRAMMAR = qr{
(?(DEFINE)

  (?<HDUlocation>
      $Astro::FITS::CFITSIO::FileName::Regexp::HDUlocation
   )

  (?<CompressSpec>
      $Astro::FITS::CFITSIO::FileName::Regexp::CompressSpec
  )

  (?<ImageSection>
      $Astro::FITS::CFITSIO::FileName::Regexp::ImageSection
  )

  (?<PixelRange>
      $Astro::FITS::CFITSIO::FileName::Regexp::PixelRange
  )

  (?<colFilter>
      $Astro::FITS::CFITSIO::FileName::Regexp::colFilter
  )

  (?<rowFilter>
      $Astro::FITS::CFITSIO::FileName::Regexp::rowFilter
  )

  (?<pixFilter>
      $Astro::FITS::CFITSIO::FileName::Regexp::pixFilter
  )

  (?<TemplateName>
      $Astro::FITS::CFITSIO::FileName::Regexp::TemplateName
  )

  (?<OutputName>
      $Astro::FITS::CFITSIO::FileName::Regexp::OutputName
  )

)
$Astro::FITS::CFITSIO::FileName::Regexp::ATOMS
}x;


# quiet complaints about using # and , in qw
no warnings qw( qw );

my @Tests = (

    HDUNUM => {
        pass => [qw{ 0 22 }],
        fail => [qw{ a }],
    },

    EXTVER => {
        pass => [qw{ 22 }],
        fail => [qw{ 0 a }],
    },

    EXTNAME => {
        pass => [qw{ a a# }],
        fail => [qw{ [a] [a a] ] [ b,c #a a:b }],
    },

    XTENSION => {
        pass => [qw{ A a ASCII ascii I i IMAGE image T t TABLE table B b BINTABLE bintable }],
        fail => [qw{ foo }],
    },

    HDUlocation => {
        pass => [
            qw{ +3 [PRIMARY] [P] [3] [0] [EVENTS] },
            '[ EVENTS, 2]', '[EVENTS, 2, b ]',
            '[EVENTS, b ]',
            '[3; images(17)]',
            '[3; images(exposure > 100)]',
        ],
        fail => [ '[EVENTS[,]', '[bin foo]' ],
    },

    TemplateName => {
        pass => [qw{ (Foo) (Foo[) }],
        fail => [qw{ (Foo)) }],
    },

    OutputName => {
        pass => [qw{ (Foo) (Foo[) (Foo.bar.gz) }],
        fail => [qw{ (Foo)) }],
    },

    BaseFileName => {
        pass => [qw{ Foo Foo.bar.gz }],
        fail => [qw{ Foo( Foo[ }],
    },

    FileType => {
        pass => [qw{ file:// ftp:// http:// https:// ftps:// stream:// gsiftp:// root:// shmem:// mem:// }],
        fail => [qw{ ssh:// }],
    },

    CompressSpec => {
        pass => [
            '[compress]',
            '[compress GZIP]',
            '[compress Rice]',
            '[compress PLIO]',
            '[compress Rice 100,100]',
            '[compress Rice 100,100;2]',
            '[compress]',
            '[ compress foo ]',
            '[compress foo]',
            '[compress foo]',
        ],
        fail => [qw{ depress }],
    },

    PositiveInt => {
        pass => [qw{ 001 01 1 2 10 11 }],
        fail => [qw{ 0 00 -1 }],
    },

    PositiveOrZeroInt => {
        pass => [qw{ 0 001 01 1 2 10 11 }],
        fail => [qw{ -1 }],
    },

    PixelRange => {
        pass => [qw{ * -* 1:512:2 * *:2 -* -1:2 }],
    },

    ImageSection => {
        pass => [ '[1:512:2, 2:512:2]', '[*, 512:256]', '[*:2, 512:256:2]', '[-*, *]', ],
    },

    pixFilter => {
        pass => [
            '[pix X * 2.0]',
            '[pix sqrt(X)]',
            '[pix X + #ZEROPT]',
            '[pix X>0 ? log10(X) : -99.]',
            '[pix  (x{-1} + x + x{+1}) / 3]',
            '[pix (x{-#NAXIS1} + x + x{#NAXIS1}) / 3]',
            '[pix (X + X{-1} + X{+1}
      + X{-#NAXIS1} + X{-#NAXIS1 - 1} + X{-#NAXIS1 + 1}
      + X{#NAXIS1} + X{#NAXIS1 - 1} + X{#NAXIS1 + 1}) / 9. ]',
            '[pixr1 sqrt(x)]',

        ],
    },

    colFilter => {
        pass => [
            '[col *]',
            '[col -Y]',
            '[col Z=X+1]',
            '[col Time, rate]',
            '[col -TIME, Good == STATUS]',
            "[col PI=PHA * 1.1 + 0.2; #TUNIT#(column units) = 'counts';*]",
            "[col rate = rate/exposure; TUNIT#(&) = 'counts/s';*]",
        ],
    },

    rowFilter => {
        pass => [ '[#ROW > 5]', '[X.gt.7]', '[(#ROW > 5)&&(X.gt.7)]' ],
    },

);

while ( my ( $label, $test ) = splice( @Tests, 0, 2 ) ) {

    subtest $label => sub {

        my $re = qr{ \A(?&$label)\Z $GRAMMAR }mxsi;

        if ( exists $test->{pass} && $test->{pass}->@* ) {
            subtest pass => sub {
                is( $_, match( $re ), $_ ) for $test->{pass}->@*;
            };
        }

        if ( exists $test->{fail} && $test->{fail}->@* ) {
            subtest fail => sub {
                isnt( $_, match( $re ), $_ ) for $test->{fail}->@*;
            };
        }
    };

}

done_testing;

1;
