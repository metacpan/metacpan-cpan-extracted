package Complete::Locale;

our $DATE = '2016-10-15'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;
#use Log::Any '$log';

our %SPEC;
require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(complete_locale);

$SPEC{complete_locale} = {
    v => 1.1,
    summary => 'Complete from list of supported locales on the system',
    args => {
        word => {
            schema => 'str*',
            req => 1,
            pos => 0,
        },
    },
    result_naked => 1,
};
sub complete_locale {
    my %args = @_;

    my @res;

    require File::Which;
  GET:
    {
        if (File::Which::which('locale')) {
            @res = `locale -a`;
            unless ($?) {
                chomp @res;
                last GET;
            }
        }

        if (File::Which::which('localectl')) {
            @res = `localectl list-locales`;
            unless ($?) {
                chomp @res;
                last GET;
            }
        }
    }

    require Complete::Util;
    Complete::Util::complete_array_elem(
        word => $args{word},
        array => \@res,
    );
}

1;
# ABSTRACT: Complete from list of supported locales on the system

__END__

=pod

=encoding UTF-8

=head1 NAME

Complete::Locale - Complete from list of supported locales on the system

=head1 VERSION

This document describes version 0.001 of Complete::Locale (from Perl distribution Complete-Locale), released on 2016-10-15.

=head1 SYNOPSIS

 use Complete::Locale qw(complete_locale);

 my $res = complete_locale(word => 'id');
 # -> ['id_ID.utf8']

=head1 FUNCTIONS


=head2 complete_locale(%args) -> any

Complete from list of supported locales on the system.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<word>* => I<str>

=back

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Complete-Locale>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Complete-Locale>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Complete-Locale>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Complete>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
