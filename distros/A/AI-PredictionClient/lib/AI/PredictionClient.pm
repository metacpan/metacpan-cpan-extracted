use strict;
use warnings;
package AI::PredictionClient;
$AI::PredictionClient::VERSION = '0.01';

use AI::PredictionClient::Predict;
use AI::PredictionClient::InceptionClient;

# ABSTRACT: A Perl Prediction client for Google TensorFlow Serving.

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

AI::PredictionClient - A Perl Prediction client for Google TensorFlow Serving.

=head1 VERSION

version 0.01

=head1 DESCRIPTION

This is a package for creating Perl clients for TensorFlow Serving model servers. 
TensorFlow Serving is the system that allows TensorFlow neural network AI models 
to be moved from the research environment to your production environment. 

Currently this package implements a client for the Predict service and a model specific Inception client.

The Predict service 'Predict.pm' is the most versatile of the TensorFlow Serving Prediction services. 
A large portion of the model specific clients are implemented from this service.

The model specific client 'InceptionClient.pm'  is implemented. This is the most popular client. 

Additionally, a command line Inception client 'Inception.pl' is included 
as an example of a complete client built form this package.

=head2 Using the example client

The example client is installed in your local bin directory and 
will allow you to send an image to an Inception model server and display 
the classifications of what the Inception neural network model "thought" it saw.

This client implements a command line interface to the 
InceptionClient module 'AI::PredictionClient::InceptionClient', and provides 
a working example of using this module for building your own clients.

The commands for the Inception client can be displayed by running the Inception.pl client with no arguments.

 $ Inception.pl 
 image_file is missing
 USAGE: Inception.pl [-h] [long options ...]

    --debug_camel               Test using camel image
    --debug_loopback_interface  Test loopback through dummy server
    --debug_verbose             Verbose output
    --host=String               IP address of the server [Default:
                                127.0.0.1]
    --image_file=String         * Required: Path to image to be processed
    --model_name=String         Model to process image [Default: inception]
    --model_signature=String    API signature for model [Default:
                                predict_images]
    --port=String               Port number of the server [Default: 9000]
    -h                          show a compact help message

Some typical command line examples include:

 Inception.pl --image_file=anything --debug_camel --host=xx7.x11.xx3.x14 --port=9000
 Inception.pl --image_file=grace_hopper.jpg --host=xx7.x11.xx3.x14 --port=9000
 Inception.pl --image_file=anything --debug_camel --debug_loopback --port 2004 --host technologic

=head3 In the examples above, the following points are demonstrated:

If you don't have an image handy --debug_camel will provide a sample image to send to the server. 
The image file argument still needs to be provided to make the command line parser happy.

If you don't have a server to talk to, but want to see if most everything else is working use 
the --debug_loopback_interface. This will provide a sample response you can test the client with. 
The module can use the same loopback interface for debugging your bespoke clients.

The --debug_verbose option will dump the data structures of the request and response to allow
you to see what is going on.

=head3 The response from a live server to the camel image looks like this:

 Inception.pl --image_file=zzzzz --debug_camel --host=107.170.xx.xxx --port=9000    
 Sending image zzzzz to server at host:107.170.xx.xxx  port:9000
 .===========================================================================.
 | Class                                                     | Score         |
 |-----------------------------------------------------------+---------------|
 | Arabian camel, dromedary, Camelus dromedarius             | 11.968746     |
 | triumphal arch                                            |  4.0692205    |
 | panpipe, pandean pipe, syrinx                             |  3.4675434    |
 | thresher, thrasher, threshing machine                     |  3.4537551    |
 | sorrel                                                    |  3.1359406    |
 |===========================================================================|
 | Classification Results for zzzzz                                           |
 '==========================================================================='

=head2 SETTING UP A TEST SERVER 

You can set up a server by following the instructions on the TensorFlow Serving site:

 https://www.tensorflow.org/deploy/tfserve
 https://tensorflow.github.io/serving/setup
 https://tensorflow.github.io/serving/docker

I have a prebuilt Docker container available here:

 docker pull mountaintom/tensorflow-serving-inception-docker-swarm-demo

This container has the Inception model already loaded and ready to go.

Start this container and run the following commands within it to get the server running:

 $ cd /serving
 $ bazel-bin/tensorflow_serving/model_servers/tensorflow_model_server --port=9000 --model_name=inception --model_base_path=inception-export &> inception_log &

A longer article on setting up a server is here:

 https://www.tomstall.com/content/create-a-globally-distributed-tensorflow-serving-cluster-with-nearly-no-pain/

=head1 ADDITIONAL INFO

The design of this client is to be fairly easy for a developer to see how the data is formed and received. 
The TensorFlow interface is based on Protocol Buffers ad gRPC. 
That implementation is built on a complex architecture of nested protofiles.

In this design I flattened the architecture out and where the native data handling of Perl is best, 
the modules use plain old Perl data structures rather than creating another layer of accessors.

The Tensor interface is used repetitively so this package includes a simplified Tensor class 
to pack and unpack data to and from the models.

In the case of most clients, the Tensor class is simply sending and receiving rank one tensors - vectors. 
In the case of higher rank tensors, the tensor data is sent and received flattened. 
The size property would be used for importing/exporting the tensors in/out of a math package.   

The design takes advantage of the native JSON serialization capabilities built into the C++ Protocol Buffers. 
Serialization allows a much simpler more robust interface to be created between the Perl environment 
and the C++ environment. 
One of the biggest advantages is for the developer who would like to quickly extend what this package does. 
You can see how the data structures are built and directly manipulate them in Perl. 
Of course, if you can be more forward looking, building the proper roles and classes and contributing them would be great. 

=head1 DEPENDENCIES

The following dependencies need to be installed in order for gRPC to build:

 $ [sudo] apt-get install git
 $ [sudo] apt-get install build-essential autoconf libtool
 $ [sudo] apt-get install automake curl make g++ unzip pkg-config
 $ [sudo] apt-get install libgflags-dev libgtest-dev
 $ [sudo] apt-get install clang libc++-dev

If gRPC is already installed on your system, the dependencies should reduce to:

 $ [sudo] apt-get install build-essential make g++

If gRPC is going to be built (The module Alien::Google::GRPC will automatically build it if needed) 
be prepared for a long build, as gRPC is a big library.

At this time only Linux builds are supported.

=head2 NOTE

This is a complex package with a lot of moving parts. Please pardon if this first release has some minor bug or missing dependency that went undiscovered in my testing.

=head1 AUTHOR

Tom Stall <stall@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Tom Stall.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
