requires "Alien::Base" => "0.005";
requires "File::ShareDir" => "1.03";
requires "parent" => "0";
requires "strict" => "0";
requires "warnings" => "0";

on 'test' => sub {
  requires "ExtUtils::MakeMaker" => "0";
  requires "File::Spec" => "0";
  requires "IO::Handle" => "0";
  requires "IPC::Open3" => "0";
  requires "Test::More" => "0";
  requires "perl" => "5.006";
};

on 'test' => sub {
  recommends "CPAN::Meta" => "2.120900";
};

on 'configure' => sub {
  requires "Alien::Base::ModuleBuild" => "0.005";
  requires "File::ShareDir" => "1.03";
};

on 'develop' => sub {
  requires "Test::More" => "0.96";
  requires "Test::Vars" => "0";
};
