package Module::Example;

use warnings;
use strict;

sub initials {
    my $class = shift;
    unshift (@_, $class)
        unless $class eq __PACKAGE__;
    my ($column, $header_line, $data_line) = @_;
    my $doc = '';
    foreach my $data (@$data_line) {
        $doc .= substr ($data, 0, 1)
            if length ($data) > 0;
    }
    return $doc;
}

1;
__END__
