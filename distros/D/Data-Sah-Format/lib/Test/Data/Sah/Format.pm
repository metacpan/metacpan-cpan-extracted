package Test::Data::Sah::Format;

use 5.010001;
use strict 'subs', 'vars';
use warnings;

use Data::Sah::Format;
use Test::Exception;
use Test::More 0.98;

use Exporter qw(import);
our @EXPORT = qw(test_format);

sub test_format {
    my %args = @_;

    my $compiler = $args{compiler} // 'perl';
    my $module;
    if ($compiler eq 'perl') {
        $module = "Data::Sah::Format";
    } elsif ($compiler eq 'js') {
        $module = "Data::Sah::FormatJS";
    } else {
        die "Unknown compiler '$compiler'";
    }
    eval "use $module"; die if $@;

    my $formatter;
    subtest +($args{name} // $args{format}) => sub {

        lives_ok {
            $formatter = &{"$module\::gen_formatter"}(
                format => $args{format},
                formatter_args => $args{formatter_args},
            );
        };
        if (exists $args{data}) {
            for my $i (0..$#{ $args{data} }) {
                my $data  = $args{data}[$i];
                my $fdata = $formatter->($data);
                is_deeply($fdata, $args{fdata}[$i]);
            }
        }
    };
}

1;
# ABSTRACT: Test routines for testing Data::Sah::Format::* modules

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Data::Sah::Format - Test routines for testing Data::Sah::Format::* modules

=head1 VERSION

This document describes version 0.003 of Test::Data::Sah::Format (from Perl distribution Data-Sah-Format), released on 2017-07-10.

=head1 FUNCTIONS

=head2 test_format(%args)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Sah-Format>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Sah-Format>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Sah-Format>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
