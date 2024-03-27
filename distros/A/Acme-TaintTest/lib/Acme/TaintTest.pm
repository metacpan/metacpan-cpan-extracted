package Acme::TaintTest;
require v5.14.0;
use strict;
use warnings;

our $VERSION = "0.0.3";

print "This is a dummy, it's all in the tests\n";

1;
__END__

=encoding utf-8

=head1 NAME

Acme::TaintTest - module for checking taint peculiarities on some CPAN testers

=head1 SYNOPSIS

    use Acme::TaintTest;

=head1 DESCRIPTION

Acme::TaintTest doesn't do anything.
It is only for looking for some taint related problems on some CPAN tester machines

=head1 LICENSE

Copyright (C) 2024 sidney.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

SIDNEY on CPAN

=cut

