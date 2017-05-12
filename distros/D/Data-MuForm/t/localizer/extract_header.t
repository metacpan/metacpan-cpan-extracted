use strict;
use warnings;

use Test::More;
use Test::Exception;
use Test::Differences;

use_ok ( 'Data::MuForm::Localizer' );

my $class = 'Data::MuForm::Localizer';

eq_or_diff
    my $extract_ref = $class->extract_header_msgstr(<<'EOT'),
Content-Type: text/plain; charset=UTF-8
Plural-Forms: nplurals=2; plural=n != 1
EOT
    {
        charset     => 'UTF-8',
        nplurals    => 2,
        plural      => 'n != 1',
        plural_code => sub {},
    },
    'extract_ok';

eq_or_diff
    {
        map {
            $_ => $extract_ref->{plural_code}->($_);
        } qw( 0 1 2 )
    },
    {
        0 => 1,
        1 => 0,
        2 => 1,
    },
    'run plural_code';

throws_ok
    sub { $class->extract_header_msgstr },
    qr{ \A \QHeader is not defined\E \b }xms,
    'no header';

throws_ok
    sub { $class->extract_header_msgstr(<<'EOT') },
Content-Type: text/plain; charset=UTF-8
EOT
    qr{ \A \QPlural-Forms not found in header\E \b }xms,
    'no plural forms';

throws_ok
    sub { $class->extract_header_msgstr(<<'EOT') },
Plural-Forms: nplurals=2; plural=n != 1;
EOT
    qr{ \A \QContent-Type with charset not found in header\E \b }xms,
    'no charset';

done_testing;
