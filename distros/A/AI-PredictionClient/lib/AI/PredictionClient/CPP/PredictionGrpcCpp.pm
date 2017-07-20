## no critic
package AI::PredictionClient::CPP::PredictionGrpcCpp;
$AI::PredictionClient::CPP::PredictionGrpcCpp::VERSION = '0.03';

# ABSTRACT: The C++ interface to gRPC and Protocol Buffers

use Cwd;
use Alien::Google::GRPC;
use AI::PredictionClient::Alien::TensorFlowServingProtos;
use Inline
  CPP => 'DATA',
  with => ['Alien::Google::GRPC', 'AI::PredictionClient::Alien::TensorFlowServingProtos'],
  version => '0.03',
  name => 'AI::PredictionClient::CPP::PredictionGrpcCpp',
  TYPEMAPS => getcwd . '/blib/lib/AI/PredictionClient/CPP/Typemaps/more_typemaps_STL_String.txt',
  LIBS => '-ldl',
  ccflags => '-std=c++11 -pthread';

use 5.010;
use strict;
use warnings;

1;

=pod

=encoding UTF-8

=head1 NAME

AI::PredictionClient::CPP::PredictionGrpcCpp - The C++ interface to gRPC and Protocol Buffers

=head1 VERSION

version 0.03

=head1 AUTHOR

Tom Stall <stall@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Tom Stall.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__
__CPP__

#undef New
#undef Copy
#undef seed
#undef Zero
#undef Move
#define std__string std::string

#include <iostream>
#include <memory>
#include <string>

#include <grpc++/grpc++.h>
#include <google/protobuf/util/json_util.h>

#include "tensorflow_serving/apis/prediction_service.grpc.pb.h"
#include "tds/base64.pb.h"

using grpc::Channel;
using grpc::ClientContext;
using grpc::Status;
using tensorflow::serving::PredictRequest;
using tensorflow::serving::PredictResponse;
using tensorflow::serving::PredictionService;

class PredictionClient {
public:
  PredictionClient(std::string server_port);
  std::string callPredict(std::string serialized_request_object);

private:
  std::unique_ptr<PredictionService::Stub> stub_;
  std::string to_base64(std::string text);
};

PredictionClient::PredictionClient(std::string server_port)
    : stub_(PredictionService::NewStub(grpc::CreateChannel(
          server_port, grpc::InsecureChannelCredentials()))) {}

std::string PredictionClient::callPredict(std::string serialized_request_object) {
  PredictRequest predictRequest;
  PredictResponse response;
  ClientContext context;
  std::string serialized_result_object;

  google::protobuf::util::JsonPrintOptions jprint_options;
  google::protobuf::util::JsonParseOptions jparse_options;

  google::protobuf::util::Status request_serialized_status =
      google::protobuf::util::JsonStringToMessage(
          serialized_request_object, &predictRequest, jparse_options);

  if (!request_serialized_status.ok()) {
    std::string error_result =
        "{\"Status\": \"Error:object:request_deserialization:protocol_buffers\", ";
    error_result += "\"StatusCode\": \"" +
                    std::to_string(request_serialized_status.error_code()) +
                    "\", ";
    error_result += "\"StatusMessage\":" +
                    to_base64(request_serialized_status.error_message()) +
                    "}";
    return error_result;
  }

  Status status = stub_->Predict(&context, predictRequest, &response);

  if (status.ok()) {
    google::protobuf::util::Status response_serialize_status =
        google::protobuf::util::MessageToJsonString(
            response, &serialized_result_object, jprint_options);

    if (!response_serialize_status.ok()) {
      std::string error_result =
          "{\"Status\": \"Error:object:response_serialization:protocol_buffers\", ";
      error_result += "\"StatusCode\": \"" +
                      std::to_string(response_serialize_status.error_code()) +
                      "\", ";
      error_result += "\"StatusMessage\":" +
                      to_base64(response_serialize_status.error_message()) +
                      "}";
      return error_result;
    }

    std::string success_result = "{\"Status\": \"OK\", ";
    success_result += "\"StatusCode\": \"\", ";
    success_result += "\"StatusMessage\": \"\", ";
    success_result += "\"Result\": " + serialized_result_object + "}";
    return success_result;

  } else {

    std::string error_result = "{\"Status\": \"Error:transport:grpc\", ";
    error_result +=
        "\"StatusCode\": \"" + std::to_string(status.error_code()) + "\", ";
    error_result += "\"StatusMessage\":" + to_base64(status.error_message()) + "}";
    return error_result;
  }
}

std::string PredictionClient::to_base64(std::string text) {

  base64::Base64Proto base64pb;
  std::string serialized_base64_message;
  google::protobuf::util::JsonPrintOptions jprint_options;

  base64pb.add_base64(text.c_str(), text.size());
  google::protobuf::util::MessageToJsonString(
      base64pb, &serialized_base64_message, jprint_options);

  return serialized_base64_message;
}
