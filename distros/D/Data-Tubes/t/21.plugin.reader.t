use strict;

# vim: ts=3 sts=3 sw=3 et ai :

use Test::More;
use Data::Dumper;

use Data::Tubes qw< summon >;
summon(
   'Plumbing::sequence',
   [
      qw<
         Reader
         read_by_line
         read_by_paragraph
         read_by_separator
         >
   ],
   [
      qw<
         Source
         iterate_array
         iterate_files
         open_file
         >
   ],
);
ok __PACKAGE__->can('read_by_line'),      'summoned by_line';
ok __PACKAGE__->can('read_by_paragraph'), 'summoned by_paragraph';
ok __PACKAGE__->can('read_by_separator'), 'summoned by_separator';
ok __PACKAGE__->can('open_file'),         'summoned open_file';
ok __PACKAGE__->can('iterate_files'),     'summoned iterate_files';
ok __PACKAGE__->can('iterate_array'),     'summoned iterate_array';
ok __PACKAGE__->can('sequence'),          'summoned sequence';

my $fakefile = <<'END';
first line
second line

fourth line
fifth line
END

{
   my $files = iterate_files();
   my ($type, $it) = $files->([\$fakefile, \*STDIN, __FILE__]);
   is $type, 'iterator', 'outcome is a hash';
   is ref($it), 'CODE', 'outcome contains an iterator';

   my $first = $it->();
   is ref($first), 'HASH', 'first item from files is a HASH';
   ok exists($first->{source}), 'default sub-key is source';
   {
      local $/;    # slurp
      my $fh = $first->{source}{fh};
      is ref($fh), 'GLOB', 'fh is a glob';
      my $got = <$fh>;
      is $got, $fakefile, 'slurped content is fine';
   }
   like $first->{source}{name}, qr{(?mxs:\Ascalar:SCALAR)},
     'name is sound';

   # let's try list context here
   my ($second) = $it->();
   is ref($second), 'HASH', 'second item from files is a HASH';
   ok exists($second->{source}), 'default sub-key is source';
   is fileno($second->{source}{fh}), fileno(\*STDIN), 'it is STDIN';
   is $second->{source}{name}, 'handle:STDIN', 'name is set correctly';

   my $third = $it->();
   is ref($third), 'HASH', 'third item from files is a HASH';
   ok exists($third->{source}), 'default sub-key is source';
   is $third->{source}{input}, __FILE__, 'it is this test file';
   is $third->{source}{name}, 'file:' . __FILE__, 'name is set correctly';

   my @rest = $it->();
   ok !@rest, 'nothing more left';
}

{
   my $sequence = sequence(tubes => [open_file(), read_by_line()]);
   my ($type, $it) = $sequence->(\$fakefile);
   is $type, 'iterator', 'outcome is a hash';
   is ref($it), 'CODE', 'outcome contains an iterator';
   my @lines = split /\n/, $fakefile;
   for my $expected (@lines) {
      my $got = $it->();
      is ref($got), 'HASH', 'iterator returns a hash';
      ok exists($got->{raw}), 'hash contains a "raw" key';
      is $got->{raw}, $expected, 'content of line';
   } ## end for my $expected (@lines)
   my @rest = $it->();
   ok !@rest, 'nothing more left';
}

{
   my $sequence = sequence(tubes => [open_file(), read_by_paragraph()]);
   my ($type, $it) = $sequence->(\$fakefile);
   is $type, 'iterator', 'outcome is a hash';
   is ref($it), 'CODE', 'outcome contains an iterator';
   my @pars = map { s{\n+\z}{}mxs; $_ } split /\n\n/, $fakefile;
   for my $expected (@pars) {
      my $got = $it->();
      is ref($got), 'HASH', 'iterator returns a hash';
      ok exists($got->{raw}), 'hash contains a "raw" key';
      is $got->{raw}, $expected, 'content of paragraph';
   } ## end for my $expected (@pars)
   my @rest = $it->();
   ok !@rest, 'nothing more left';
}

{
   my $sequence = sequence(
      tubes => [
         iterate_array(array => [\$fakefile]), open_file(),
         read_by_paragraph()
      ]
   );
   {
      my ($type, $it) = $sequence->();
      is $type, 'iterator', 'outcome is a hash';
      is ref($it), 'CODE', 'outcome contains an iterator';
      my @pars = map { s{\n+\z}{}mxs; $_ } split /\n\n/, $fakefile;
      for my $expected (@pars) {
         my $got = $it->();
         is ref($got), 'HASH', 'iterator returns a hash';
         ok exists($got->{raw}), 'hash contains a "raw" key';
         is $got->{raw}, $expected, 'content of paragraph';
      } ## end for my $expected (@pars)
      my @rest = $it->();
      ok !@rest, 'nothing more left';
   }
   {
      my ($type, $it) = $sequence->([]);
      is $type, 'iterator', 'outcome is a hash';
      is ref($it), 'CODE', 'outcome contains an iterator';
      my @pars = map { s{\n+\z}{}mxs; $_ } split /\n\n/, $fakefile;
      for my $expected (@pars) {
         my $got = $it->();
         is ref($got), 'HASH', 'iterator returns a hash';
         ok exists($got->{raw}), 'hash contains a "raw" key';
         is $got->{raw}, $expected, 'content of paragraph';
      } ## end for my $expected (@pars)
      my @rest = $it->();
      ok !@rest, 'nothing more left';
   }
}

{
   my $sequence =
     sequence(
      tubes => [open_file(), read_by_separator(separator => '---')]);
   my $fakefile = 'ciao---a---tutti';
   my ($type, $it) = $sequence->(\$fakefile);
   is $type, 'iterator', 'outcome is a hash';
   is ref($it), 'CODE', 'outcome contains an iterator';
   my @lines = split /---/, $fakefile;
   for my $expected (@lines) {
      my $got = $it->();
      is ref($got), 'HASH', 'iterator returns a hash';
      ok exists($got->{raw}), 'hash contains a "raw" key';
      is $got->{raw}, $expected, 'content of line';
   } ## end for my $expected (@lines)
   my @rest = $it->();
   ok !@rest, 'nothing more left';
}

{
   my $sequence = sequence(
      tubes => [
         open_file(), read_by_separator(separator => '---', emit_eof => 1)
      ]
   );
   my $fakefile = 'ciao---a---tutti';
   my ($type, $it) = $sequence->(\$fakefile);
   is $type, 'iterator', 'outcome is a hash';
   is ref($it), 'CODE', 'outcome contains an iterator';
   my @lines = split /---/, $fakefile;
   for my $expected (@lines) {
      my $got = $it->();
      is ref($got), 'HASH', 'iterator returns a hash';
      ok exists($got->{raw}), 'hash contains a "raw" key';
      is $got->{raw}, $expected, 'content of line';
   } ## end for my $expected (@lines)

   my $eof = $it->();
   is ref($eof), 'HASH', 'iterator returns a hash';
   ok exists($eof->{raw}), 'hash contains a "raw" key';
   is $eof->{raw}, undef, 'content of line is undefined (EOF was hit)';

   # EOF MUST be emitted only once
   my @rest = $it->();
   ok !@rest, 'nothing more left';
}

done_testing();
