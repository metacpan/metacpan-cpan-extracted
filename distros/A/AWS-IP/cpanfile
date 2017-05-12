requires "Cache::File" => "0";
requires "Carp" => "0";
requires "File::Temp" => "0";
requires "HTTP::Tiny" => "0";
requires "IO::Socket::SSL" => "1.56";
requires "JSON::XS" => "0";
requires "Net::CIDR::Set" => "0";
requires "Net::SSLeay" => "1.49";
requires "constant" => "0";
requires "strict" => "0";
requires "warnings" => "0";

on 'test' => sub {
  requires "File::Slurp" => "0";
  requires "Test::More" => "0";
};

on 'configure' => sub {
  requires "ExtUtils::MakeMaker" => "0";
};

on 'develop' => sub {
  requires "Pod::Coverage::TrustPod" => "0";
  requires "Test::Pod" => "1.41";
  requires "Test::Pod::Coverage" => "1.08";
};
