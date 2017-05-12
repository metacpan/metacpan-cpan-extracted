requires "MetaCPAN::API" => "0";
requires "Moose::Role" => "0";
requires "Moose::Util::TypeConstraints" => "0";
requires "MooseX::AttributeShortcuts" => "0";
requires "MooseX::RelatedClasses" => "0";
requires "common::sense" => "0";
requires "namespace::autoclean" => "0";
requires "perl" => "5.010";

on 'test' => sub {
  requires "File::Find" => "0";
  requires "File::Temp" => "0";
  requires "Test::Moose::More" => "0";
  requires "Test::More" => "0.88";
  requires "aliased" => "0";
  requires "strict" => "0";
  requires "warnings" => "0";
};

on 'configure' => sub {
  requires "ExtUtils::MakeMaker" => "6.30";
};

on 'develop' => sub {
  requires "Pod::Coverage::TrustPod" => "0";
  requires "Test::Pod" => "1.41";
  requires "Test::Pod::Coverage" => "1.08";
  requires "version" => "0.9901";
};
