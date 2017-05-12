requires "DBI" => "0";
requires "List::MoreUtils" => "0";
requires "MRO::Compat" => "0";
requires "Message::String" => "0";
requires "Params::Callbacks" => "0";
requires "Sub::Util" => "0";
requires "namespace::clean" => "0";
requires "perl" => "v5.8.8";

on 'test' => sub {
  requires "DBD::CSV" => "0";
  requires "DBD::SQLite" => "0";
  requires "DBD::mysql" => "0";
  requires "Data::Dumper::Concise" => "0";
  requires "JSON" => "0";
  requires "perl" => "v5.8.8";
};

on 'configure' => sub {
  requires "ExtUtils::MakeMaker" => "0";
};

on 'develop' => sub {
  requires "Test::Pod" => "1.41";
};
