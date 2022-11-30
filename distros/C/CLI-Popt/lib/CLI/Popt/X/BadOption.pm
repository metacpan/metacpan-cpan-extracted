package CLI::Popt::X::BadOption;

use strict;
use warnings;

use parent 'CLI::Popt::X::Base';

sub _new {
    my ($class, $errnum, $errdesc, $opt) = @_;

    my $self = $class->SUPER::_new(
        "$errdesc ($errnum): $opt",
        option => $opt,
        error_code => $errnum,
        error_desc => $errdesc,
    );

    return bless $self, $class;
}

1;
