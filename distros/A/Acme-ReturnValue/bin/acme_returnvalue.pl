#!perl
use 5.010;
use strict;
use warnings;
use Acme::ReturnValue;

# ABSTRACT: run Acme::ReturnValue
# PODNAME: acme_returnvalue.pl
our $VERSION = '1.004'; # VERSION

Acme::ReturnValue->new_with_options->run;

__END__

=pod

=encoding UTF-8

=head1 NAME

acme_returnvalue.pl - run Acme::ReturnValue

=head1 VERSION

version 1.004

=head1 AUTHOR

Thomas Klausner <domm@plix.at>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 - 2021 by Thomas Klausner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
