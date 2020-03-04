package Acme::CPANModulesUtil::Misc;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-03-01'; # DATE
our $DIST = 'Acme-CPANModulesUtil-Misc'; # DIST
our $VERSION = '0.001'; # VERSION

use strict 'subs', 'vars';
use warnings;

our %SPEC;

use Exporter qw(import);
our @EXPORT_OK = qw(populate_entries_from_module_links_in_description);

sub populate_entries_from_module_links_in_description {
    my $list;
    if (@_) {
        $list = $_[0];
    } else {
        my $caller = caller;
        $list = ${"$caller\::LIST"};
    }
    die 'Please specify list (either in argument or in caller\'s $LIST'
        unless $list;

    $list->{entries} ||= [];
    for my $mod (
        do { my %seen; grep { !$seen{$_}++ }
                 ($list->{description} =~ /<pm:(\w+(?:::\w+)*)>/g)
             }) {
        next if grep { $_->{module} eq $mod } @{ $list->{entries} };
        push @{ $list->{entries} }, {module=>$mod};
    }
    $list;
}

1;
# ABSTRACT: Various utility functions related to Acme::CPANModules

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModulesUtil::Misc - Various utility functions related to Acme::CPANModules

=head1 VERSION

This document describes version 0.001 of Acme::CPANModulesUtil::Misc (from Perl distribution Acme-CPANModulesUtil-Misc), released on 2020-03-01.

=head1 FUNCTIONS

=head2 populate_entries_from_module_links_in_description

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModulesUtil-Misc>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModulesUtil-Misc>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModulesUtil-Misc>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

C<Acme::CPANModules>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
