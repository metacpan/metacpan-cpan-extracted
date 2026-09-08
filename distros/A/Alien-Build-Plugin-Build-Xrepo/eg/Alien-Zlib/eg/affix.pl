use v5.40;
use blib;
use Affix;
use Alien::Zlib;

# The Build::Xrepo plugin's FFI gathering makes dynamic_libs point at the real shared library; feed
# it straight to Affix
my $alien = Alien::Zlib->new;
my ($lib) = $alien->dynamic_libs;
die 'zlib not resolved; run `perl Makefile.PL && make` first' unless $lib;
say 'Loaded zlib from: ' . $lib;

# const char * zlibVersion(void);
affix $lib, 'zlibVersion' => [] => String;
say 'Platypus zlib version: ' . zlibVersion();
