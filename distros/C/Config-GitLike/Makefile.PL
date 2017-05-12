use inc::Module::Install;
name('Config-GitLike');
all_from('lib/Config/GitLike.pm');
repository('http://github.com/bestpractical/config-gitlike');

perl_version '5.008';
requires 'Moo';
requires 'MooX::Types::MooseLike';  # MooX::Types::MooseLike::Base
build_requires 'Test::Exception';
extra_tests();
sign();
WriteAll();
