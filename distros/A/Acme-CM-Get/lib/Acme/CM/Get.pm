package Acme::CM::Get;

our $DATE = '2019-01-15'; # DATE
our $VERSION = '0.001'; # VERSION

use strict 'subs', 'vars';
use warnings;

sub import {
    my $pkg  = shift;

    my $mod = shift or die "import(): Please supply module name";
    $mod = "Acme::CPANModules::$mod" unless $mod =~ /\AAcme::CPANModules::/;
    (my $mod_pm = "$mod.pm") =~ s!::!/!g;
    require $mod_pm;

    my $caller = caller();
    {
        no warnings 'once';
        # export $LIST
        *{"$caller\::LIST"} = \${"$mod\::LIST"};
    }
}

1;
# ABSTRACT: Shortcut to retrieve Acme::CPANModules list

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CM::Get - Shortcut to retrieve Acme::CPANModules list

=head1 VERSION

This document describes version 0.001 of Acme::CM::Get (from Perl distribution Acme-CM-Get), released on 2019-01-15.

=head1 SYNOPSIS

Load L<Acme::CPANModules::XSVersions> then import
C<$Acme::CPANModules::XSVersions::LIST>:

% perl -MAcme::CM::Get=XSVersions -E'# do something with $LIST ...'

=head1 DESCRIPTION

=for Pod::Coverage ^(.+)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CM-Get>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CM-Get>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CM-Get>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Acme::CPANModules>

L<cpanmodules> from L<App::cpanmodules>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
