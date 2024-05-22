requires "Compress::Raw::Zlib" => "2.048";
requires "List::Util" => "1.45";
requires "Path::Tiny" => "0.119";
requires "String::CityHash" => ">= 0.06, <= 0.10";

on 'test' => sub {
  requires "Feature::Compat::Defer" => "0";
  requires "Feature::Compat::Try" => "0";
  requires "IPC::Run3" => "0";
};

on 'configure' => sub {
  requires "ExtUtils::MakeMaker::CPANfile" => "0.08";
  requires "Path::Tiny" => "0.062";
};
