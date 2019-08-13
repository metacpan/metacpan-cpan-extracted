requires "Archive::Any" => "0";
requires "Data::Dumper" => "0";
requires "Encode" => "0";
requires "File::Copy" => "0";
requires "File::Find" => "0";
requires "File::Path" => "0";
requires "File::Temp" => "0";
requires "JSON" => "0";
requires "Moose" => "0";
requires "MooseX::Getopt" => "0";
requires "MooseX::Types::Path::Class" => "0";
requires "PPI" => "0";
requires "Parse::CPAN::Packages" => "0";
requires "Path::Class" => "0";
requires "URI::Escape" => "0";
requires "perl" => "5.010";
requires "strict" => "0";
requires "warnings" => "0";

on 'build' => sub {
  requires "Module::Build" => "0.28";
};

on 'test' => sub {
  requires "Acme::CPANAuthors::Register" => "0";
  requires "Any::Moose" => "0";
  requires "Carp" => "0";
  requires "Digest::HMAC_SHA1" => "0";
  requires "Exporter" => "0";
  requires "MIME::Base64" => "0";
  requires "Test::More" => "0";
  requires "Test::Most" => "0";
  requires "Time::Piece" => "0";
  requires "URI::file" => "0";
  requires "WWW::Shorten::_dead" => "0";
  requires "XML::LibXML" => "0";
  requires "utf8" => "0";
};

on 'configure' => sub {
  requires "Module::Build" => "0.28";
};

on 'develop' => sub {
  requires "Test::More" => "0";
};
