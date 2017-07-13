use strict;
use warnings;
package AI::PredictionClient::Alien::TensorFlowServingProtos;
$AI::PredictionClient::Alien::TensorFlowServingProtos::VERSION = '0.01';
use base qw( Alien::Base );

=head1 NAME

AI::PredictionClient::Alien::TensorFlowServingProtos - Builds C++ client library for TensorFlow Serving.

=cut

=head1 SYNOPSIS

In your Build.PL:

 use Module::Build;
 use AI::PredictionClient::Alien::TensorFlowServingProtos;
 my $builder = Module::Build->new(
   ...
   configure_requires => {
     'AI::PredictionClient::Alien::TensorFlowServingProtos' => '0',
     ...
   },
   extra_compiler_flags => AI::PredictionClient::Alien::TensorFlowServingProtos->cflags,
   extra_linker_flags   => AI::PredictionClient::Alien::TensorFlowServingProtos->libs,
   ...
 );
 
 $build->create_build_script;

In your Makefile.PL:

 use ExtUtils::MakeMaker;
 use Config;
 use AI::PredictionClient::Alien::TensorFlowServingProtos;
 
 WriteMakefile(
   ...
   CONFIGURE_REQUIRES => {
     'AI::PredictionClient::Alien::TensorFlowServingProtos' => '0',
   },
   CCFLAGS => AI::PredictionClient::Alien::TensorFlowServingProtos->cflags . " $Config{ccflags}",
   LIBS    => [ AI::PredictionClient::Alien::TensorFlowServingProtos->libs ],
   ...
 );

=cut

=head1 DESCRIPTION

This distribution builds a C++ library for use by other Perl XS modules to 
communicate with Google TensorFlow Serving model servers. It is primarily intended to be used 
with the cpan AI::PredictionClient module.

This module builds a library 'tensorflow_serving_protos_so' that provides the protos for the 
Predict, Classify, Regress and MultiInference prediction services.

The built library is installed in a private share location within this module
for use by other modules.

=cut

=head1  DEPENDENCIES

This module is dependent on gRPC. This module will use the cpan module Alien::Google::GRPC to 
either use an existing gRPC installed on your system or if not found, the Alien::Google::GRPC
module will download and build a private copy.

Additional, the following dependencies need to be installed in order for this module to build.

 $ [sudo] apt-get install build-essential make g++

See the Alien::Google::GRPC for potential additional build dependencies.

At this time only Linux builds are supported.

=cut

=head1 AUTHOR

Tom Stall stall@cpan.org

=cut

=head1 SEE ALSO

L<Alien>, L<Alien::Base>, L<Alien::Build::Manual::AlienUser>

=cut

1;
