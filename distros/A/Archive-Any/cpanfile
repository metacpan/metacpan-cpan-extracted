requires "Archive::Tar" => "0";
requires "Archive::Zip" => "0";
requires "Cwd" => "0";
requires "File::MMagic" => "0";
requires "File::Spec::Functions" => "0";
requires "MIME::Types" => "0";
requires "Module::Find" => "0";
requires "base" => "0";
requires "strict" => "0";
requires "warnings" => "0";

on 'build' => sub {
  requires "Module::Build" => "0.28";
};

on 'test' => sub {
  requires "Test::More" => "0";
  requires "Test::Warn" => "0";
};

on 'configure' => sub {
  requires "ExtUtils::MakeMaker" => "0";
  requires "Module::Build" => "0.28";
};

on 'develop' => sub {
  requires "Test::CPAN::Changes" => "0.19";
};
