#!/usr/bin/env perl
use v5.24;
use warnings;
use experimental 'signatures';
no warnings 'experimental::signatures';
use Test::More;
use Test::Exception;
use Data::Dumper;

eval { require Path::Tiny; 1 }
   or plan skip_all => 'Path::Tiny needed for these tests';

use Data::Resolver qw< resolver_from_tar >;

my $tar_path = __FILE__ . 'ar'; # '.t' => '.tar'
my @exp_list = qw< ./ciao.txt ./foo/bar.txt >;

subtest list => sub {
   my $resolver = resolver_from_tar(archive => $tar_path);

   {
      my $list = $resolver->(undef, 'list');
      isa_ok $list, 'ARRAY';
      is_deeply sorted($list), \@exp_list, 'directory contents'
         or diag(Dumper($list));
   }

   {
      my ($list, $type) = $resolver->(undef, 'list');
      isa_ok $list, 'ARRAY';
      is_deeply sorted($list), \@exp_list, 'directory contents'
         or diag(Dumper($list));
   }

};

subtest content => sub {
   my $resolver = resolver_from_tar(archive => $tar_path);

   {
      my $file = $resolver->('ciao.txt', 'file');
      ok -f $file, 'got a file back';
      ok -r $file, 'it is a readable filename';
   }

   {
      my $data = $resolver->('ciao.txt', 'data');
      is $data, "ciao\n", 'file contents are correct';
   }

   {
      my $fh = $resolver->('ciao.txt', 'filehandle');
      isa_ok $fh, 'GLOB', 'got a filehandle back';
      my $data = <$fh>;
      is $data, "ciao\n", 'data from filehandle are correct';
   }
};

subtest 'errors (quiet setting, no exception thrown)' => sub {
   my $resolver = resolver_from_tar(archive => $tar_path);
   my $stuff;

   lives_ok { my $stuff = $resolver->('inexistent', 'list') }
      'looking for inexistent dir to list';
   is $stuff, undef, 'nothing came out';

   lives_ok { my $stuff = $resolver->('ciao.txt', 'list') }
      'looking for list a file instead of a dir';
   is $stuff, undef, 'nothing came out';

   lives_ok { my $stuff = $resolver->('inexistent.txt') }
      'looking for inexistent file';
   is $stuff, undef, 'nothing came out';

   lives_ok { my $stuff = $resolver->('foo', 'data') }
      'looking for data from a directory';
   is $stuff, undef, 'nothing came out';

   lives_ok { my $stuff = $resolver->('ciao.txt', 'i-dont-know!') }
      'looking to get an unsupported type';
   is $stuff, undef, 'nothing came out';
};

subtest 'errors (loud setting, errors thrown as exceptions)' => sub {
   my $resolver = resolver_from_tar(archive => $tar_path, throw => 1);
   my $stuff;

   dies_ok { my $stuff = $resolver->('inexistent', 'list') }
      'looking for inexistent dir to list';
   isa_ok $@, 'HASH';
   is $@->{code}, 400, 'it has the right code';
   is $@->{message}, 'Unsupported listing in sub-directory', 'it has the right message';
   is $stuff, undef, 'nothing came out';

   dies_ok { my $stuff = $resolver->('ciao.txt', 'list') }
      'looking for list a file instead of a dir';
   isa_ok $@, 'HASH';
   is $@->{code}, 400, 'it has the right code';
   is $@->{message}, 'Unsupported listing in sub-directory', 'it has the right message';
   is $stuff, undef, 'nothing came out';

   dies_ok { my $stuff = $resolver->('inexistent.txt') }
      'looking for inexistent file';
   isa_ok $@, 'HASH';
   is $@->{code}, 404, 'it has the right code';
   is $@->{message}, 'Not Found', 'it has the right message';
   is $stuff, undef, 'nothing came out';

   dies_ok { my $stuff = $resolver->('foo', 'data') }
      'looking for data from a directory';
   isa_ok $@, 'HASH';
   is $@->{code}, 404, 'it has the right code';
   is $@->{message}, 'Not Found', 'it has the right message';
   is $stuff, undef, 'nothing came out';

   dies_ok { my $stuff = $resolver->('ciao.txt', 'x!') }
      'looking to get an unsupported type';
   isa_ok $@, 'HASH';
   is $@->{code}, 400, 'it has the right code';
   is $@->{message}, "Invalid request type 'x!'",
      'it has the right message';
   is $stuff, undef, 'nothing came out';
};

done_testing();

sub sorted ($aref) { [ sort { $a cmp $b } $aref->@* ] }
