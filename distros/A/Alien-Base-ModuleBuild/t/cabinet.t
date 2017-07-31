use Test2::V0 -no_srand => 1;
use Alien::Base::ModuleBuild::File;
use Alien::Base::ModuleBuild::Cabinet;

subtest 'basic' => sub {

  my $cab = Alien::Base::ModuleBuild::Cabinet->new();
  isa_ok( $cab, 'Alien::Base::ModuleBuild::Cabinet');

  # make some fake file objects
  my @fake_files = map { bless {}, 'Alien::Base::ModuleBuild::File' } (1..3);

  is( $cab->add_files( @fake_files ), \@fake_files, "add_files the files" );
  is( $cab->files, \@fake_files, "add_files, well ... adds files");

};

subtest 'sort' => sub {

  my $cb = Alien::Base::ModuleBuild::Cabinet->new;
  
  $cb->add_files(
    map {
      Alien::Base::ModuleBuild::File->new(@$_)
    } ( [ filename => 'foo-2' ], 
        [ filename => 'foo-1' ], 
        [ filename => 'foo-3' ], 
        [ filename => 'foo', version => 1 ], 
        [ filename => 'bar', version => 2 ],
        [ filename => 'baz', version => 3 ],
      )
  );
  
  $cb->sort_files;

  is(
    $cb->files,
    array sub {
      item object sub { field filename => 'baz'; field version => 3 };
      item object sub { field filename => 'bar'; field version => 2 };
      item object sub { field filename => 'foo'; field version => 1 };
      item object sub { field filename => 'foo-3' };
      item object sub { field filename => 'foo-2' };
      item object sub { field filename => 'foo-1' };
    },
  );

};

done_testing;
