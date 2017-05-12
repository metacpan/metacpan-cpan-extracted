package NeedsOpenSSL;

use strict;
use warnings;

use Test::More;

use File::Which ();

use OpenSSL_Control ();

sub SKIP_CLASS {
    my ($self) = @_;

    return 'No OpenSSL binary!' if !$self->_get_openssl();

    return;
}

sub _get_openssl {
    my ($self) = @_;

    return $self->{'_ossl_bin'} ||= do {
        my $bin = OpenSSL_Control::openssl_bin();

        if ($bin) {
            note "Using OpenSSL binary: $bin";
            note `$bin version -a`;
        }

        $bin;
    };
}

1;
