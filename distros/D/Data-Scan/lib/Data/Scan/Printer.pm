use strict;
use warnings FATAL => 'all';

package Data::Scan::Printer;

# ABSTRACT: Example of a printer consumer for Data::Scan

our $VERSION = '0.009'; # VERSION

our $AUTHORITY = 'cpan:JDDPAUSE'; # AUTHORITY

use Exporter qw/import/;
use vars qw/@EXPORT %Option/;
use Data::Scan::Impl::Printer;
use Moo;
extends 'Data::Scan';
#
# Using this module intentionaly means caller is ok to pollute its namespace
#
@EXPORT = qw/dspp/;
#
# User is advised to localized that
#
%Option = ();


sub dspp {
  __PACKAGE__->new(consumer => Data::Scan::Impl::Printer->new(%Option))->process(@_)
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Scan::Printer - Example of a printer consumer for Data::Scan

=head1 VERSION

version 0.009

=head1 SYNOPSIS

    use strict;
    use warnings FATAL => 'all';
    use Data::Scan::Printer;

    my $this = bless([ 'var1', 'var2', {'a' => 'b', 'c' => 'd'}, \undef, \\undef, [], sub { return 'something' } ], 'TEST');
    local %Data::Scan::Printer::Option = (with_deparse => 1);
    dspp($this);

=head1 DESCRIPTION

Data::Scan::Printer is polluting user's namespace with a dspp() method, showing how Data::Scan can be used to dump an arbitrary structure. This is a sort of L<Data::Printer> alternative.

=head1 SUBROUTINES/METHODS

=head2 dspp(@arguments)

Print to Data::Scan::Impl::Printer's handle a dumped vision of @arguments. An instance of Data::Scan::Impl::Printer is created automatically, using parameters that have to be available in %Data::Scan::Printer::Option. Please refer to L<Data::Scan::Impl::Printer> documentation for the available options.

=head1 SEE ALSO

L<Data::Scan>, L<Data::Scan::Impl::Printer>

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
