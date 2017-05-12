package Data::TreeValidator::Transformations;
{
  $Data::TreeValidator::Transformations::VERSION = '0.04';
}
# ABSTRACT: Common data transformations
use strict;
use warnings;

use Sub::Exporter -setup => {
    exports => [qw( boolean )],
};

sub boolean { \&_boolean }
sub _boolean {
    my ($input) = @_;
    return $input ? 1 : 0;
}

1;


__END__
=pod

=encoding utf-8

=head1 NAME

Data::TreeValidator::Transformations - Common data transformations

=head1 DESCRIPTION

Common transformations of data that you may find useful.

=head1 FUNCTIONS

=head2 boolean

Converts any true value to 1, or returns 0 otherwise. A true value is Perl's
definition of what true is.

=head1 AUTHOR

Oliver Charles

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Oliver Charles <oliver.g.charles@googlemail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

