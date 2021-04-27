use strict;
use warnings;
use File::Spec::Functions qw(rel2abs);
use File::Temp qw(tempdir);
use Test::More;

$ENV{TT_HOME} = tempdir;
$ENV{EDITOR}  = 't/bin/editor.pl';

plan skip_all => "Cannot load tt: $! ($@)" unless my $tt = do(rel2abs 'script/tt');
plan skip_all => "home is not a tempdir" if int $tt->home->list_tree;
plan skip_all => "EDITOR is not available" unless -x $ENV{EDITOR};

open my $STDERR, '>', \(my $stderr = '');
open my $STDOUT, '>', \(my $stdout = '');
@$tt{qw(stderr stdout)} = ($STDERR, $STDOUT);
$tt->project('edit');

subtest 'no previous' => sub {
  eval { $tt->command_edit };
  like $@, qr{Could not find file}, 'could not find file';
};

subtest 'register' => sub {
  $tt->command_register(qw(09:30:07 10:34:12));
  $tt->command_export;
  like $stdout, qr{"1\.1"}, 'export original';
};

subtest 'edit previous' => sub {
  $tt->command_edit;
  $tt->command_export;
  like $stdout, qr{"2\.1"}, 'export edited';
};

subtest 'edit file' => sub {
  my $file;
  App::tt::file->new($ENV{TT_HOME})->list_tree(sub { $_[0] =~ m!\.trc$! && ($file = $_[0]) });
  $tt->command_edit($file);
  $tt->command_export;
  like $stdout, qr{"3\.1"}, 'export edited';
};

done_testing;
