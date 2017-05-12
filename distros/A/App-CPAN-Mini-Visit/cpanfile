requires "Archive::Extract" => "0.28";
requires "CPAN::Mini" => "0.572";
requires "Exception::Class::TryCatch" => "1.12";
requires "File::Basename" => "0";
requires "File::Find" => "0";
requires "File::pushd" => "0";
requires "Getopt::Lucid" => "0.16";
requires "Path::Class" => "0";
requires "Pod::Usage" => "1.35";
requires "perl" => "5.006";
requires "strict" => "0";
requires "warnings" => "0";

on 'test' => sub {
  requires "CPAN::Checksums" => "0";
  requires "ExtUtils::MakeMaker" => "0";
  requires "File::Spec::Functions" => "0";
  requires "File::Temp" => "0.20";
  requires "IO::CaptureOutput" => "1.0801";
  requires "IO::File" => "0";
  requires "List::Util" => "0";
  requires "Test::More" => "0.62";
  requires "version" => "0";
};

on 'test' => sub {
  recommends "CPAN::Meta" => "0";
  recommends "CPAN::Meta::Requirements" => "2.120900";
};

on 'configure' => sub {
  requires "ExtUtils::MakeMaker" => "6.17";
};

on 'develop' => sub {
  requires "Dist::Zilla" => "5.013";
  requires "Dist::Zilla::Plugin::Encoding" => "0";
  requires "Dist::Zilla::PluginBundle::DAGOLDEN" => "0.060";
  requires "File::Spec" => "0";
  requires "File::Temp" => "0";
  requires "IO::Handle" => "0";
  requires "IPC::Open3" => "0";
  requires "Pod::Coverage::TrustPod" => "0";
  requires "Test::CPAN::Meta" => "0";
  requires "Test::More" => "0";
  requires "Test::Pod" => "1.41";
  requires "Test::Pod::Coverage" => "1.08";
};
