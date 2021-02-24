package Authen::NZRealMe::Asserts;
$Authen::NZRealMe::Asserts::VERSION = '1.22'; # TRIAL
use 5.014;
use strict;
use warnings;
use autodie;

use Exporter qw(import);

our @EXPORT = qw();

our @EXPORT_OK = qw(
    assert_is_base64
);

sub _get_assert_caller {
    my(undef, $filename, $line) = caller(1);
    return "at $filename line $line\n";
}

sub assert_is_base64 {
    my($string, $name) = @_;

    if(my($char) = $string =~ m{([^\s=a-zA-Z0-9+/_-])}) {
        my $caller = _get_assert_caller();
        die "Unexpected character '$char' in $name - expected base64 $caller";
    }
}

1;

__END__

=head1 NAME

Authen::NZRealMe::Asserts - a collection of assertion functions for data safety

=head1 DESCRIPTION

The functions exported by this module are intended to allow code to assert
things about supplied data values.  If the assertion is valid then the function
will simply return, otherwise an exception will be thrown.

Note: It is unfortunate that the word 'assertion' is used to describe both a
thing you are assuming is true and a key element of SAML.  This module is an
implementation of the former within a set of modules that implement the latter.

=head1 SYNOPSIS

  use Authen::NZRealMe::Asserts  qw(assert_is_base64);

  assert_is_base64($post_param, '$args{saml_response}');

=head1 EXPORTED FUNCTIONS

=head2 assert_is_base64( $value, $description )

Checks that the supplied C<$value> contains only valid characters for a
Base64-encoded value.  If invalid characters are found, an exception will be
thrown.  The exception message will include C<$description> to aid in
identifying where the bad data came from.

=cut

