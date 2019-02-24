package Bencher::Formatter::RenderAsTextTable;

our $DATE = '2019-02-24'; # DATE
our $VERSION = '1.043'; # VERSION

use 5.010001;
use strict;
use warnings;
#use Log::Any::IfLOG '$log';

use parent qw(Bencher::Formatter);

use Perinci::Result::Format::Lite;

use Role::Tiny::With;
with 'Bencher::Role::ResultRenderer';

sub render_result {
    my ($self, $envres) = @_;

    my $rres = ""; # render result

    $rres .= $envres->[3]{'table.title'}.":\n" if $envres->[3]{'table.title'};
    $rres .= Perinci::Result::Format::Lite::format($envres, 'text-pretty');

    $rres;
}

1;
# ABSTRACT: Scale time to make it convenient

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Formatter::RenderAsTextTable - Scale time to make it convenient

=head1 VERSION

This document describes version 1.043 of Bencher::Formatter::RenderAsTextTable (from Perl distribution Bencher-Backend), released on 2019-02-24.

=for Pod::Coverage .*

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Backend>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Backend>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Backend>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2018, 2017, 2016, 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
