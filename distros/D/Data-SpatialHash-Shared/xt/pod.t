use strict; use warnings; use Test::More;
plan skip_all => 'author test' unless $ENV{AUTHOR_TESTING};
eval { require Test::Pod; Test::Pod->import; 1 } or plan skip_all => 'Test::Pod required';
all_pod_files_ok();
