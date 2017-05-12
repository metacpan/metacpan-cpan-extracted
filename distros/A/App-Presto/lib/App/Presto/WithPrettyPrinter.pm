package App::Presto::WithPrettyPrinter;
our $AUTHORITY = 'cpan:MPERRY';
$App::Presto::WithPrettyPrinter::VERSION = '0.010';
# ABSTRACT: Role that provides a pretty-printer

use strict;
use warnings;
use Moo::Role;
use App::Presto::PrettyPrinter;

requires 'config';

has pretty_printer => (
    is => 'lazy',
    handles => ['pretty_print'],
);

sub _build_pretty_printer {
    return App::Presto::PrettyPrinter->new( config => shift->config );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Presto::WithPrettyPrinter - Role that provides a pretty-printer

=head1 VERSION

version 0.010

=head1 AUTHORS

=over 4

=item *

Brian Phillips <bphillips@cpan.org>

=item *

Matt Perry <matt@mattperry.com> (current maintainer)

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Brian Phillips and Shutterstock Images (http://shutterstock.com).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
