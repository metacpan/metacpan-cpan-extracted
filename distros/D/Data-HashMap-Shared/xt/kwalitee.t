use strict; use warnings; use Test::More;
plan skip_all => 'author test' unless $ENV{AUTHOR_TESTING};
eval { require Test::Kwalitee; Test::Kwalitee->import('kwalitee_ok'); 1 }
    or plan skip_all => 'Test::Kwalitee required';

# META.yml comes from `make dist`, not the source tree: has_meta_yml is a false
# negative here.
kwalitee_ok('-has_meta_yml');
done_testing;
