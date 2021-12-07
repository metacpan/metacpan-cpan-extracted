package Data::Sah::Util::TypeX;

use 5.010;
use strict;
use warnings;
#use Log::Any '$log';

require Exporter;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-12-01'; # DATE
our $DIST = 'Data-Sah'; # DIST
our $VERSION = '0.911'; # VERSION

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

This document describes version 0.911 of Data::Sah::Util::TypeX (from Perl distribution Data-Sah), released on 2021-12-01.

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

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2020, 2019, 2018, 2017, 2016, 2015, 2014, 2013, 2012 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Sah>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
