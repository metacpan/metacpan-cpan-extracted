use Test::More tests => 12;

BEGIN {
  use_ok('CAD::Drawing');
  use_ok('CAD::Drawing::Calculate');
  use_ok('CAD::Drawing::IO');
  use_ok('CAD::Drawing::Manipulate');
  use_ok('CAD::Drawing::Defined');
  use_ok('CAD::Drawing::IO::Compressed');
  use_ok('CAD::Drawing::IO::FlatYAML');
  use_ok('CAD::Drawing::IO::Split');
  use_ok('CAD::Drawing::IO::Circ');
  use_ok('CAD::Drawing::Manipulate::Transform');
  use_ok('CAD::Drawing::Manipulate::Graphics');
  use_ok('CAD::Drawing::Calculate::Finite');
}

diag( "Testing CAD::Drawing $CAD::Drawing::VERSION" );
