use Test::More tests => 1;
BEGIN { use_ok('Audio::TagLib') and diag 'Using taglib ', qx{taglib-config --version} };
