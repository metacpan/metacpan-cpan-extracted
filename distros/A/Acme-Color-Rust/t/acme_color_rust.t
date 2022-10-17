use Test2::V0 -no_srand => 1;
use Acme::Color::Rust;
use YAML ();

subtest 'basic' => sub {
  my $color = Acme::Color::Rust->new("red", 0xff, 0x00, 0x00);
  is
    $color,
    object {
      call [ isa => 'Acme::Color::Rust' ] => T();
      call name  => 'red';
      call red   => 0xff;
      call green => 0x00;
      call blue  => 0x00;
    },
    'red';

  note YAML::Dump($color);
};

done_testing;
