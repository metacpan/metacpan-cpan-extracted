use warnings;
use strict;

use Test::More;
use Test::Exception;
use File::Spec::Functions qw(catfile);

package Test::Bug;
    use Exporter qw(import);

    our @EXPORT = qw(test_null_operation_bug);

    use Crypt::OpenSSL::Verify;
    use File::Slurp qw(read_file);
    use Crypt::OpenSSL::X509;

    sub test_null_operation_bug {
        my ($ca, $cert) = @_;

        my $x = Crypt::OpenSSL::Verify->new($ca);
        my $x509 = Crypt::OpenSSL::X509->new_from_string(scalar read_file($cert));

        return $x->verify($x509);
    }

package main;
{
    my @warn;
    local $SIG{__WARN__} = sub { push(@warn, @_) };

    Test::Bug::test_null_operation_bug(
        catfile(qw(t cacert.pem)),
        catfile(qw(t cert.pem))
    );

    if (!is(@warn, 0, "No warnings emitted")) {
        diag explain \@warn;
    }

}

done_testing();

