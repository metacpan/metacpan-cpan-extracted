package Test::Crypt::OpenSSL::PKCS10;
use strict;
use warnings;
#use namespace::autoclean ();

use Test::Lib;

# ABSTRACT: Test module for Crypt::OpenSSL::PKCS10

use Import::Into;

use Test::More ();
use Test::Crypt::OpenSSL::PKCS10::Util ();

sub import {

    my $caller_level = 1;

    my @imports = qw(
        Test::More
        Test::Crypt::OpenSSL::PKCS10::Util
        strict
        warnings
    );

    $_->import::into($caller_level) for @imports;
}

1;

__END__


=head1 DESCRIPTION

Main test module for Crypt::OpenSSL::PKCS10

=head1 SYNOPSIS

  use Test::Lib;
  use Test::Crypt::OpenSSL::PKCS10;

  # tests here

  ...;

  done_testing();
