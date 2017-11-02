use Test2::V0;
use Test::Alien::Build;
use Alien::Build::Plugin::Build::Premake5;
use Path::Tiny qw( path );

subtest 'basic' => sub {
  my $plugin = Alien::Build::Plugin::Build::Premake5->new;
  isa_ok $plugin, 'Alien::Build::Plugin';
  isa_ok $plugin, 'Alien::Build::Plugin::Build::Premake5';

  my $build = alienfile_ok q{ use alienfile };
  my $meta = $build->meta;

  $plugin->init($meta);

  my $premake = $meta->interpolator->interpolate('%{premake}');
  like $premake, qr{^premake[0-9]$}, "\%{premake} = $premake";

  foreach (
      [qw( haiku haiku )],
      [qw( darwin macosx )],
      [qw( MSWin32 windows )],
      [qw( hurd hurd )],
      [qw( aix aix )],
      [qw( freebsd bsd )],
      [qw( openbsd bsd )],
      [qw( linux linux )],
      [qw( solaris solaris )],
    ) {

    my ($os, $string) = @{$_};
    local $^O = $os;
    is $plugin->os_string, $string, $os;
  }
};

subtest 'options' => sub {
  my $plugin = Alien::Build::Plugin::Build::Premake5->new(
    cc           => 'gcc',
    dc           => 'gdc',
    dotnet       => 'mono',
    file         => 'foo',
    scripts      => 'bar',
    systemscript => 'baz',
    fatal        => 1,
    insecure     => 1,
  );

  my $build = alienfile_ok q{ use alienfile };
  my $meta = $build->meta;
  $plugin->init($meta);

  my $premake = $meta->interpolator->interpolate('%{premake}');
  like $premake, qr{--file         = foo}x, "file";
  like $premake, qr{--scripts      = bar}x, "scripts";
  like $premake, qr{--systemscript = baz}x, "systemscript";

  like $premake, qr{--fatal\b},    "fatal";
  like $premake, qr{--insecure\b}, "insecure";
};

done_testing();
