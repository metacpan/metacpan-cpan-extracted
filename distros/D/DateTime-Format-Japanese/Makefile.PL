use strict;
use inc::Module::Install;

name('DateTime-Format-Japanese');
all_from('lib/DateTime/Format/Japanese.pm');
requires('DateTime' => 0);
requires('DateTime::Format::Builder' => 0);
requires('DateTime::Calendar::Japanese::Era' => '0.08001');
requires('DateTime::Calendar::Japanese' => '0.05');
requires('Encode' => 0);
requires('Params::Validate' => 0);

auto_include;
WriteAll;
