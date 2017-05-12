use strict;
use warnings;

use Test::More;
use ExtUtils::Installed;
use File::Find;
use File::ShareDir qw/dist_dir/;
use Acme::Alien::DontPanic;

plan skip_all => 'only for share install'
  if Acme::Alien::DontPanic->install_type eq 'system';

plan skip_all => 'dist appears to have been moved'
  if defined Acme::Alien::DontPanic->config('original_prefix')
  && Acme::Alien::DontPanic->config('original_prefix') ne Acme::Alien::DontPanic->dist_dir;

my $inst = ExtUtils::Installed->new;
my $packlist = eval { $inst->packlist('Acme::Alien::DontPanic') };

if($^O eq 'MSWin32') {
  %$packlist = map { $_ => undef } map { Win32::GetLongPathName($_) } keys %$packlist;
}

unless ( defined $packlist ) {
  plan skip_all => 'Packlist test not valid when Acme::Alien::DontPanic is not fully installed'; 
}

my $dir = dist_dir('Acme-Alien-DontPanic');

$dir =~ s{\\}{/}g if $^O eq 'MSWin32';

plan skip_all => 'appears to be a blib install'
  if $dir =~ m{/blib/};

my $test = sub {
  my $file = $File::Find::name;
  ok( exists $packlist->{$file}, "$file exists in packlist" );
};

find $test, $dir;

done_testing;

