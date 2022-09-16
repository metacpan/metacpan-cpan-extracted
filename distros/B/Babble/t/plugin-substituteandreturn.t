use strictures 2;
use Test::More;
use Babble::Plugin::SubstituteAndReturn;
use Babble::Match;

my $sr = Babble::Plugin::SubstituteAndReturn->new;

my @cand = (
  [ 'my $foo = $bar =~ s/baz/quux/r;',
    'my $foo = (map { (my $__B_001 = $_) =~ s/baz/quux/; $__B_001 } $bar)[0];', ],
  [ '$foo =~ s/foo/bar/gr =~ s/(bar)+/baz/gr',
    '(map { (my $__B_001 = $_) =~ s/foo/bar/g; for ($__B_001) { s/(bar)+/baz/g } $__B_001 } $foo)[0]', ],
  [ 'map { s/foo/bar/gr =~ s/(bar)+/baz/gr =~ s/xyzzy/ijk/gr } @list',
    'map { (map { (my $__B_001 = $_) =~ s/foo/bar/g; for ($__B_001) { s/(bar)+/baz/g; s/xyzzy/ijk/g } $__B_001 } $_)[0] } @list', ],
  [ 'my @new = map { s|foo|bar|gr } @old',
    'my @new = map { (map { (my $__B_001 = $_) =~ s|foo|bar|g; $__B_001 } $_)[0] } @old', ],
  [ 'while(<>) { print( s/aa/1/gr =~ s/bb/2/gr =~ s/cc/3/gr ); }',
    'while(<>) { print( (map { (my $__B_001 = $_) =~ s/aa/1/g; for ($__B_001) { s/bb/2/g; s/cc/3/g } $__B_001 } $_)[0] ); }', ],
  [ 'while(<>) {
       print( s/aa/1/gr =~ s/bb/2/gr =~ s/cc/3/gr );
       print( s/dd/4/gr =~ s/ee/5/gr =~ s/ff/6/gr );
     }',
    'while(<>) {
       print( (map { (my $__B_001 = $_) =~ s/aa/1/g; for ($__B_001) { s/bb/2/g; s/cc/3/g } $__B_001 } $_)[0] );
       print( (map { (my $__B_002 = $_) =~ s/dd/4/g; for ($__B_002) { s/ee/5/g; s/ff/6/g } $__B_002 } $_)[0] );
     }',
    ],
  [ 'my $foo = $bar =~ y/a-c/d/r;',
    'my $foo = (map { (my $__B_001 = $_) =~ y/a-c/d/; $__B_001 } $bar)[0];', ],
  [ q{
      while(<>) {
        print( y/a-c/d/r =~ tr/d/z/cr );
        print( y/a-c/d/r =~ s/d/foo/gr );
      }
    }, q{
      while(<>) {
        print( (map { (my $__B_001 = $_) =~ y/a-c/d/; for ($__B_001) { tr/d/z/c } $__B_001 } $_)[0] );
        print( (map { (my $__B_002 = $_) =~ y/a-c/d/; for ($__B_002) { s/d/foo/g } $__B_002 } $_)[0] );
      }
    }
  ],
);

foreach my $cand (@cand) {
  my ($from, $to) = @$cand;
  my $top = Babble::Match->new(top_rule => 'Document', text => $from);
  $sr->transform_to_plain($top);
  is($top->text, $to, "${from}");
}

done_testing;
