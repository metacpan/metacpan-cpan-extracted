package Antispam::Toolkit::Types::Internal;
BEGIN {
  $Antispam::Toolkit::Types::Internal::VERSION = '0.08';
}

use strict;
use warnings;

use Archive::Zip qw( AZ_OK );
use File::Temp qw( tempdir );
use Path::Class qw( dir file );

use MooseX::Types -declare => [
    qw(
        DataFile
        Details
        NonNegativeNum
        )
];

use MooseX::Types::Common::String qw( NonEmptyStr );
use MooseX::Types::Moose qw( ArrayRef Num );
use MooseX::Types::Path::Class qw( File );

subtype DataFile,
    as File,
    where { -f $_ && -s _ },
    message { "The filename you provided ($_) is either empty or does not exist" };

subtype Details,
    as ArrayRef[NonEmptyStr];

coerce Details,
    from NonEmptyStr,
    via { [$_] };

subtype NonNegativeNum,
    as Num,
    where { $_ >= 0 },
    message { "The number you provided ($_) was not greater than or equal to zero" };
