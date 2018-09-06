package App::NDTools::Util;

use strict;
use warnings FATAL => 'all';
use parent 'Exporter';

use B qw(SVp_IOK SVp_NOK svref_2object);

our @EXPORT_OK = qw(
    chomp_evaled_error
    is_number
);

sub chomp_evaled_error($) {
    $_[0] =~ s/ at .+ line \d+\.*//;
    chomp $_[0];

    return $_[0];
}

sub is_number($) {
    return svref_2object(\$_[0])->FLAGS & (SVp_IOK | SVp_NOK);
}

1; # End of App::NDTools::Util
