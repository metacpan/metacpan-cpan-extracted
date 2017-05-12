package Acme::MetaSyntactic::WordList;

our $DATE = '2016-06-12'; # DATE
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict 'subs', 'vars';
use warnings;

use parent 'Acme::MetaSyntactic::List';

sub init_data {
    my ($self, $wl_module) = @_;
    (my $wl_module_pm = "$wl_module.pm") =~ s!::!/!g;
    require $wl_module_pm;
    my $class = caller(0);
    my $data = {
        # this is silly, really. converting data unnecessarily
        names => join(" ", $wl_module->new->all_words),
    };
    # sigh, can't do this because AM:List uses caller(0)
    #$self->SUPER::init($data);
    return $data;
}

1;
# ABSTRACT: Get meta names from WordList::*

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::MetaSyntactic::WordList - Get meta names from WordList::*

=head1 VERSION

This document describes version 0.002 of Acme::MetaSyntactic::WordList (from Perl distribution Acme-MetaSyntactic-WordList), released on 2016-06-12.

=head1 DESCRIPTION

This is a base class for C<Acme::MetaSyntactic::*> module that wants to get
their meta names for a wordlist in corresponding C<WordList::*> module. An
example of such module is L<Acme::MetaSyntactic::countries>.

=for Pod::Coverage ^(.+)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-MetaSyntactic-WordList>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-MetaSyntactic-WordList>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-MetaSyntactic-WordList>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
