requires "perl" => "v5.34";

requires "builtin::Backport" => "0";
requires "stable" => "0.031";
requires "Compress::Raw::Zlib" => "2.070";
requires "IO::Compress::Zip" => "0";
requires "IO::Uncompress::Unzip" => "0";
requires "List::Util" => "1.45";
requires "Object::Pad" => "0.73";
requires "Path::Tiny" => "0.125";

on 'test' => sub {
  requires "IPC::Run3" => "0";
  requires "Feature::Compat::Defer" => "0";
  requires "Feature::Compat::Try" => "0";
  requires "Test2::V0" => "0";
};

on 'configure' => sub {
  requires "ExtUtils::CppGuess" => "0";
  requires "ExtUtils::MakeMaker" => "7.12";
  requires "ExtUtils::MakeMaker::CPANfile" => "0.08";
  requires "Path::Tiny" => "0.062";
};

on 'develop' => sub {
  suggests "Data::Hexdumper" => "3.00";
};
