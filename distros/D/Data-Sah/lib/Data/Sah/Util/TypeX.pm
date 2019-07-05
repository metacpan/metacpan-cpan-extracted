package Data::Sah::Util::TypeX;

our $DATE = '2019-07-04'; # DATE
our $VERSION = '0.896'; # VERSION

use 5.010;
use strict;
use warnings;
#use Log::Any '$log';

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
                       add_clause
               );

sub add_clause {
    my ($type, $clause, %opts) = @_;
    # not yet implemented

    # * check duplicate

    # * call Data::Sah::Util::Role::has_clause
    # * install handlers to Data::Sah::Compiler::$Compiler::TH::$type
    # * push @{ $Data::Sah::Compiler::human::TypeX{$type} }, $clause;
}

1;
# ABSTRACT: Sah utility routines for type extensions

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Util::TypeX - Sah utility routines for type extensions

=head1 VERSION

This document describes version 0.896 of Data::Sah::Util::TypeX (from Perl distribution Data-Sah), released on 2019-07-04.

=head1 DESCRIPTION

This module provides some utility routines to be used by type extension modules
(C<Data::Sah::TypeX::*>).

=head1 FUNCTIONS

=head2 add_clause($type, $clause, %opts)

Add a clause. Used when wanting to add a clause to an existing type.

Options:

=over 4

=item * definition => HASH

Will be passed to L<Data::Sah::Util::Role>'s C<has_clause>.

=item * handlers => HASH

A mapping of compiler name and coderefs. Coderef will be installed as
C<clause_$clause> in the C<Data::Sah::Compiler::$Compiler::TH::>.

=item * prio => $priority

Optional. Default is 50. The higher the priority, the earlier the clause will be
processed.

=item * aliases => \@aliases OR $alias

Define aliases. Optional.

=item * code => $code

Optional. Define implementation for the clause. The code will be installed as
'clause_$name'.

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Sah>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Sah>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Sah>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2018, 2017, 2016, 2015, 2014, 2013, 2012 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
