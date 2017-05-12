#!perl
use 5.010;
use strict;
use warnings;
use Acme::ReturnValue;

# ABSTRACT: run Acme::ReturnValue
# PODNAME: acme_returnvalue.pl

Acme::ReturnValue->new_with_options->run;

__END__

=pod

=head1 NAME

acme_returnvalue.pl - run Acme::ReturnValue

=head1 VERSION

version 1.001

=head1 AUTHOR

Thomas Klausner <domm@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Thomas Klausner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
