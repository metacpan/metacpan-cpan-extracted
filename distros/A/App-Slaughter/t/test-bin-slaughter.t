#!/usr/bin/perl -w -I../lib -I./lib/
#

use strict;
use Test::More tests => 15;
use Test::Script;
use Test::File::Contents;
use Test::Exception;

use Cwd;
use Capture::Tiny qw(capture);

my $cwd = getcwd;

my $prefix = "--prefix=$cwd/t/example1";
my @args = qw(--verbose --skip-cfgfile --allow-nonroot
                --lockfile=/tmp/slaug.lck --transport=local
                --role=some_role --hostname=foohost --fqdn=barhost.baz.bam
                --outfile=GENERATED.pl);

push @args, $prefix;

diag "Running slaughter with args: " . join(' ', @args);

script_compiles('bin/slaughter', 'bin/slaughter compiles OK');

my ($stdout1, $stderr1, @result1);
lives_ok { ($stdout1, $stderr1, @result1) = capture { system( 'bin/slaughter', @args ) } } 'bin/slaughter runs OK';

like($stdout1, qr/Policy written to: GENERATED.pl\n/, 'Found expected output file name');

file_contents_unlike 'GENERATED.pl',  qr/Policy inclusion failed/,  'All policy files included OK';
file_contents_unlike 'GENERATED.pl',  qr/Module inclusion failed/,  'All module files included OK';

file_contents_like 'GENERATED.pl',  qr/our \$hostname = 'foohost';/,      'hostname spoofed OK';
file_contents_like 'GENERATED.pl',  qr/hostname => 'foohost',/,           'hostname spoofed OK';
file_contents_like 'GENERATED.pl',  qr/our \$fqdn = 'barhost.baz.bam';/,  'fqdn spoofed OK';
file_contents_like 'GENERATED.pl',  qr/fqdn => 'barhost.baz.bam',/,       'fqdn spoofed OK';
file_contents_like 'GENERATED.pl',  qr/our \$role = 'some_role';/,        'role spoofed OK';
file_contents_like 'GENERATED.pl',  qr/role => 'some_role',/,             'role spoofed OK';
file_contents_like 'GENERATED.pl',  qr/our \$noexecute = '1';/,           'noexecute set OK';
file_contents_like 'GENERATED.pl',  qr/noexecute => '1',/,                'noexecute set OK';

script_compiles('GENERATED.pl', 'generated script compiles OK');

# Check that re-declaring 'my' variables in multiple policy files does not raise warnings
my ($stdout2, $stderr2, @result2) = capture {
  system( 'perl', qw(-Ilib -c GENERATED.pl) );
};

chomp($stderr2);
is($stderr2, "GENERATED.pl syntax OK", 'generated script compiles with no warnings');
diag "Compilation generated warning: $stderr2" if $stderr2 ne 'GENERATED.pl syntax OK';



unlink('GENERATED.pl');
