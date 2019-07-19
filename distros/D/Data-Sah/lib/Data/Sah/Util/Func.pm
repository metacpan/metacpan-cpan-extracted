package Data::Sah::Util::Func;

our $DATE = '2019-07-19'; # DATE
our $VERSION = '0.897'; # VERSION

use 5.010;
use strict;
use warnings;
#use Log::Any '$log';

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
                       add_func
               );

sub add_func {
    my ($funcset, $func, %opts) = @_;
    # not yet implemented
}

1;
# ABSTRACT: Sah utility routines for adding function

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Util::Func - Sah utility routines for adding function

=head1 VERSION

This document describes version 0.897 of Data::Sah::Util::Func (from Perl distribution Data-Sah), released on 2019-07-19.

=head1 DESCRIPTION

This module provides some utility routines to be used by modules that add Sah
functions.

=head1 FUNCTIONS

=head2 add_func($funcset, $func, %opts)

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
