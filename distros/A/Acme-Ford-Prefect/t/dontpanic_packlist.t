use Test2::V0;
use ExtUtils::Installed;
use File::Find;
use Acme::Alien::DontPanic;

skip_all 'only for share install'
  if Acme::Alien::DontPanic->install_type eq 'system';

skip_all 'dist appears to have been moved'
  if defined Acme::Alien::DontPanic->config('original_prefix')
  && Acme::Alien::DontPanic->config('original_prefix') ne Acme::Alien::DontPanic->dist_dir;

my $inst = ExtUtils::Installed->new;
my $packlist = eval { $inst->packlist('Acme::Alien::DontPanic') };

if($^O eq 'MSWin32') {
  %$packlist = map { $_ => undef } map { Win32::GetLongPathName($_) } keys %$packlist;
}

skip_all 'Packlist test not valid when Acme::Alien::DontPanic is not fully installed' unless defined $packlist;

my $dir = Acme::Alien::DontPanic->dist_dir;

$dir =~ s{\\}{/}g if $^O eq 'MSWin32';

skip_all 'appears to be a blib install'
  if $dir =~ m{/blib/};

my $test = sub {
  my $file = $File::Find::name;
  ok( exists $packlist->{$file}, "$file exists in packlist" );
};

find $test, $dir;

done_testing;

