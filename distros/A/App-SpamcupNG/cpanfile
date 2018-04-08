requires "Getopt::Std" => "0";
requires "HTML::Entities" => "3.69";
requires "HTML::Form" => "6.03";
requires "HTTP::Cookies" => "6.01";
requires "LWP::UserAgent" => "6.05";
requires "YAML::XS" => "0.62";

on 'test' => sub {
  requires "ExtUtils::MakeMaker" => "0";
  requires "File::Spec" => "0";
  requires "Test::More" => "0";
};

on 'test' => sub {
  recommends "CPAN::Meta" => "2.120900";
};

on 'configure' => sub {
  requires "ExtUtils::MakeMaker" => "0";
};

on 'develop' => sub {
  requires "Devel::CheckOS" => "0";
  requires "File::Spec" => "0";
  requires "IO::Handle" => "0";
  requires "IPC::Open3" => "0";
  requires "Test::Kwalitee" => "1.21";
  requires "Test::More" => "0.88";
  requires "Test::Pod" => "1.41";
  requires "blib" => "1.01";
  requires "lib" => "0";
  requires "perl" => "5.006";
};
