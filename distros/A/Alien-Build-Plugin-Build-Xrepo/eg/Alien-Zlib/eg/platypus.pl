use v5.40;
use blib;
use FFI::Platypus 2.00;
use Alien::Zlib;

# The Build::Xrepo plugin's FFI gathering makes dynamic_libs point at the real shared library; feed
# it straight to FFI::Platypus
my $alien = Alien::Zlib->new;
my ($lib) = $alien->dynamic_libs;
die 'zlib not resolved; run `perl Makefile.PL && make` first' unless $lib;
say 'Loaded zlib from: ' . $lib;
my $ffi = FFI::Platypus->new( api => 2, lib => $lib );

# const char * zlibVersion(void);
$ffi->attach( 'zlibVersion' => [] => 'string' );
say 'Platypus zlib version: ' . zlibVersion();
