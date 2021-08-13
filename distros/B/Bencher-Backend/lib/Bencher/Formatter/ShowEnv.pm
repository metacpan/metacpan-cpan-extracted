package Bencher::Formatter::ShowEnv;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-08-13'; # DATE
our $DIST = 'Bencher-Backend'; # DIST
our $VERSION = '1.060'; # VERSION

use 5.010001;
use strict;
use warnings;
#use Log::Any::IfLOG '$log';

use parent qw(Bencher::Formatter);

use Role::Tiny::With;
with 'Bencher::Role::FieldMunger';
with 'Bencher::Role::ResultMunger';

sub munge_result {
    my ($self, $envres) = @_;

    return unless @{$envres->[2]};
    return unless exists $envres->[2][0]{env_hash};

    $self->add_field(
        $envres,
        'env',
        {after=>'env_hash'},
        sub {
            for my $rit (@{$envres->[2]}) {
                my $env_hash = $envres->[3]{'func.scenario_env_hashes'}[ $rit->{env_hash} ];
                $rit->{env} = join(" ", map {"$_=$env_hash->{$_}"} sort keys %$env_hash);
            }
        }
    );
    $self->delete_fields($envres, 'env_hash');
}

1;
# ABSTRACT: Replace 'env_hash' field (numeric) with 'env' (string)

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Formatter::ShowEnv - Replace 'env_hash' field (numeric) with 'env' (string)

=head1 VERSION

This document describes version 1.060 of Bencher::Formatter::ShowEnv (from Perl distribution Bencher-Backend), released on 2021-08-13.

=head1 DESCRIPTION

The C<env_hash> field only contains the index to the C<env_hashes> array
(scenario property). This formatter replaces the field with C<env> showing the
contents of the environment hash. This makes it clearer to the viewer what
environment variables are being set for an item.

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

This software is copyright (c) 2021, 2020, 2019, 2018, 2017, 2016, 2015 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
