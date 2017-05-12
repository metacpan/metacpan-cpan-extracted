#!/user/local/bin/perl

use strict;
use warnings;

use lib "lib";
use lib "tools/lib";

use DateTimeX::Lite::Tool::Locale::Generator;
DateTimeX::Lite::Tool::Locale::Generator->new_with_options->run();