use strict;
use warnings;
use Test::More;

# idx accepts exactly type, options and pg => { where, using, with, expression }.
# Anything else used to be stored and never read, so `using => 'gin'` or
# `unique => 1` on top level silently produced a plain non-unique btree index.
# The declaration has to fail when the class loads, naming the key.

my $n = 0;
sub declare {
  my ($body) = @_;
  my $pkg = 'TestIdxKeys::Result::R' . ++$n;
  eval "package $pkg; use DBIO::Cake; table 'r$n'; col id => integer; "
     . "col tags => text; primary_key 'id'; $body; 1";
  return ($@, $pkg);
}

for my $key (qw(using where with expression)) {
  my ($err) = declare("idx t => ['tags'], $key => 'x'");
  like $err, qr/unknown key '$key'/, "top-level $key is refused";
  like $err, qr/pg => \{ \.\.\. \}/, "message points to pg for $key";
}

{
  my ($err) = declare("idx t => ['tags'], unique => 1");
  like $err, qr/unknown key 'unique'/, 'unique => 1 is refused';
  like $err, qr/type => 'unique'/, 'message points to type => unique';
}

{
  my ($err) = declare("idx t => ['tags'], tpye => 'unique'");
  like $err, qr/unknown key 'tpye'/, 'typo in top-level key is refused';
  like $err, qr/index 't'/, 'message names the index';
}

{
  my ($err) = declare("idx t => ['tags'], pg => { usnig => 'gin' }");
  like $err, qr/unknown key 'usnig' in pg/, 'typo inside pg block is refused';
  like $err, qr/using/, 'message lists the valid pg keys';
}

{
  my ($err) = declare("idx t => ['tags'], pg => 'gin'");
  like $err, qr/pg.*hashref/i, 'non-hashref pg is refused';
}

{
  my ($err, $pkg) = declare(
    "idx t => ['tags'], type => 'unique', options => [{}], "
  . "pg => { using => 'gin', where => 'tags IS NOT NULL', with => { fillfactor => 70 }, expression => 'lower(tags)' }");
  is $err, '', 'all known keys are accepted';
  is scalar @{ $pkg->result_source_instance->{_index_declarations} }, 1, 'index registered';
}

{
  my ($err) = declare("idx t => ['tags']; idx u => ['tags'], tpye => 'unique'");
  isnt $err, '', 'a refused declaration among valid ones fails the load';
}

done_testing;
