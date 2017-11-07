requires "Encode" => "0";
requires "Getopt::Long" => "0";
requires "Module::Runtime" => "0";
requires "PPI" => "0";
requires "Path::Tiny" => "0";
requires "Pod::Elemental" => "0";
requires "Pod::Text" => "0";
requires "Pod::Usage" => "0";
requires "Pod::Weaver" => "0";
requires "Scalar::Util" => "0";
requires "Software::LicenseUtils" => "0";
requires "perl" => "5.014";
requires "warnings" => "0";

on 'test' => sub {
  requires "ExtUtils::MakeMaker" => "0";
  requires "File::Spec" => "0";
  requires "IO::Handle" => "0";
  requires "IPC::Open3" => "0";
  requires "Test::More" => "0";
};

on 'test' => sub {
  recommends "CPAN::Meta" => "2.120900";
};

on 'configure' => sub {
  requires "ExtUtils::MakeMaker" => "0";
};
