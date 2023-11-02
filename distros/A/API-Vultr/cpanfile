use strict;
use warnings;

on "configure" => sub {
   requires "ExtUtils::MakeMaker";
};

on "runtime" => sub {
   requires "LWP::UserAgent" => "6.72";
};

on "test" => sub {
   requires "Test::Simple";
   requires "Test::LWP::UserAgent";
};
