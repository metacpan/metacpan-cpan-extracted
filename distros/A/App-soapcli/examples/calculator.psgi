#!/usr/bin/perl -c

# Sample server which provides calculator webservice.
#
# Start server:
#   lwp-mirror http://soaptest.parasoft.com/calculator.wsdl calculator.wsdl
#   plackup calculator.psgi

use warnings;
use strict;

use XML::Compile::SOAP::Daemon::PSGI;
use XML::Compile::WSDL11;
use XML::Compile::SOAP11;

use XML::Compile::Util       'pack_type';
use XML::Compile::SOAP::Util 'SOAP11ENV';

use Log::Report;

dispatcher PERL => 'default', mode => 'VERBOSE';

my $wsdl_filename = 'calculator.wsdl';

my $wsdl = XML::Compile::WSDL11->new($wsdl_filename);

my $daemon = XML::Compile::SOAP::Daemon::PSGI->new(
    preprocess => sub {
        my ($req) = @_;
        notice sprintf "Request\n---\n%s %s %s\n%s\n%s---",
            $req->method, $req->request_uri, $req->protocol,
            $req->headers->as_string,
            $req->content;
    },
    postprocess => sub {
        my ($req, $res) = @_;
        notice sprintf "Response\n---\n%s %s\n%s\n%s---",
            $res->status, HTTP::Status::status_message($res->status),
            $res->headers->as_string,
            $res->body;
    },
);


$daemon->operationsFromWSDL(
    $wsdl,
    callbacks => {
        add => sub {
            my ($soap, $data) = @_;
            return +{
                Result => $data->{parameters}->{x} + $data->{parameters}->{y},
            };
        },
        subtract => sub {
            my ($soap, $data) = @_;
            return +{
                Result => $data->{parameters}->{x} - $data->{parameters}->{y},
            };
        },
        multiply => sub {
            my ($soap, $data) = @_;
            return +{
                Result => $data->{parameters}->{x} * $data->{parameters}->{y},
            };
        },
        divide => sub {
            my ($soap, $data) = @_;

            my $result = eval {
                $data->{parameters}->{numerator} / $data->{parameters}->{denominator};
            };
            if (my $e = $@) {
                mistake $e;
                while ($e =~ s/\t\.\.\.propagated at (?!.*\bat\b.*).* line \d+( thread \d+)?\.\n$//s) { }
                $e =~ s/( at (?!.*\bat\b.*).* line \d+( thread \d+)?\.?)?\n$//s;
                return +{
                    Fault => {
                        faultcode => pack_type(SOAP11ENV, 'Client'),
                        faultstring => $e,
                        faultactor => $soap->role,
                    }
                };
            };

            return +{
                Result => $result,
            };
        },
    },
);

$daemon->setWsdlResponse($wsdl_filename);

# Set up PSGI app finally
$daemon->to_app;
