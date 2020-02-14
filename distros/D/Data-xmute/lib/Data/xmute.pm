## no critic: Modules::ProhibitAutomaticExportation

package Data::xmute;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-02-13'; # DATE
our $DIST = 'Data-xmute'; # DIST
our $VERSION = '0.001'; # VERSION

use strict;
use warnings;

use Data::Transmute ();

use Exporter qw(import);
our @EXPORT = qw(xmute);

sub xmute {
    my $data = shift;
    for (@_) {
        $data = Data::Transmute::transmute_data(
            data => $data, rules_module=>$_);
    }
    $data;
}

1;
# ABSTRACT: Transmute (transform) data structure using rules modules

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::xmute - Transmute (transform) data structure using rules modules

=head1 VERSION

This document describes version 0.001 of Data::xmute (from Perl distribution Data-xmute), released on 2020-02-13.

=head1 SYNOPSIS

 use Data::xmute; # exports xmute()

 my $xmuted = xmute($data, "Rule1", "Rule2", ...);

=head1 DESCRIPTION

EXPERIMENTAL.

This is a thin wrapper for L<Data::Transmute> to offer a more concise interface.

=head1 FUNCTIONS

=head2 xmute

Usage:

 my $xmuted = xmute($data, $rule_module_name1, ...);

Transmute data using one or more rule modules (modules in the
C<Data::Transmute::Rules::*> namespace, sans prefix).

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-xmute>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-xmute>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-xmute>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Data::Transmute>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
