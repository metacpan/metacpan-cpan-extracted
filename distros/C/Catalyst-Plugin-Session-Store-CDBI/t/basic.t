#!/usr/bin/perl

use strict;
use warnings;
use Test::More;

BEGIN {
    plan skip_all =>
      "please set the environment variables CDBI_CLASS, IDROW, STORAGEROW, and EXPIRESROW to run this test"
      unless exists $ENV{CDBI_CLASS} && exists $ENV{IDROW} && exists $ENV{STORAGEROW} && exists $ENV{EXPIRESROW};
}

use Catalyst::Plugin::Session::Test::Store (
    backend => "CDBI",
    config  => {
      storage_class => $ENV{CDBI_CLASS},
      id_field      => $ENV{IDROW},
      storage_field => $ENV{STORAGEROW},
      expires_field => $ENV{EXPIRESROW},
      expires       => 3600,
    },
);

