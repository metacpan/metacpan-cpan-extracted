use strict;
use warnings;
use Test::More;

BEGIN {
  plan skip_all => 'Test requires Alien::Base::ModuleBuild'
    unless eval q{ use Alien::Base::ModuleBuild; 1 };

  plan skip_all => 'Test requires Capture::Tiny'
    unless eval q{ use Capture::Tiny qw( capture ); 1 }
}

plan tests => 3;

my $builder = Alien::Base::ModuleBuild->new(
  module_name => 'Alien::Foo',
  dist_version => 0.01,
  alien_bin_requires => {
    'Alien::gmake' => 0.10,
  },
  alien_build_commands => [
    "%{gmake}",
  ],
  alien_install_commands => [
    "%{gmake} install",
  ],
);

isa_ok $builder, 'Alien::Base::ModuleBuild';

subtest 'alien_fakebuild' => sub {
  my($out, $err, $exception) =  capture { eval { $builder->ACTION_alien_fakebuild }; $@ };
  is $exception, '', 'ACTION_alien_fakebuild does not throw an exception';
  diag "[out]\n$out\n[err]\n" if $exception;
};

subtest 'alien_interpolate' => sub {
  my $command = eval { $builder->alien_interpolate("%{gmake}") };
  is $@, '', 'alien_interpolate does not throw an error';
  isnt $command, '', 'returns something for %{gmake}';
  note "command = $command";
};
