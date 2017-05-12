
use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
  module_name   => 'Data::DPath::Validator',
  license       => 'perl',
  dist_abstract => "Validate\ data\ based\ on\ Perl\ data\ structure\ templates",
  dist_name     => "Data\-DPath\-Validator",
  dist_author   => [
"Nicholas\ Perez\ \<nperez\@cpan\.org\>",
  ],
  requires      => {
    "Test::More" => '0.92',
    "MooseX::Role::BuildInstanceOf" => '0.02',
    "Scalar::Util" => '1.22',
    "namespace::autoclean" => '0.09',
    "MooseX::Types" => '0.20',
    "Data::DPath" => '0.32',
    "Data::Visitor" => '0.26',
    "Moose" => '0.93',
  },
  script_files => [ qw() ],
);

$build->create_build_script;
