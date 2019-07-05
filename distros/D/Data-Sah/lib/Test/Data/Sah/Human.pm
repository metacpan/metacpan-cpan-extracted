package Test::Data::Sah::Human;

our $DATE = '2019-07-04'; # DATE
our $VERSION = '0.896'; # VERSION

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;

use Data::Sah;

use Exporter qw(import);
our @EXPORT_OK = qw(test_human);

sub test_human {
    my %args = @_;
    subtest $args{name} // $args{result}, sub {
        my $sah = Data::Sah->new;
        my $hc = $sah->get_compiler("human");
        my %hargs = (
            schema => $args{schema},
            lang => $args{lang},
            %{ $args{compile_opts} // {} },
        );
        $hargs{format} //= "inline_text";
        my $cd = $hc->compile(%hargs);

        if (defined $args{result}) {
            if (ref($args{result}) eq 'Regexp') {
                like($cd->{result}, $args{result}, 'result');
            } else {
                is($cd->{result}, $args{result}, 'result');
            }
        }
    };
}

1;
# ABSTRACT: Routines to test Data::Sah (human compiler)

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Data::Sah::Human - Routines to test Data::Sah (human compiler)

=head1 VERSION

This document describes version 0.896 of Test::Data::Sah::Human (from Perl distribution Data-Sah), released on 2019-07-04.

=head1 FUNCTIONS

=head2 test_human(%args)

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
