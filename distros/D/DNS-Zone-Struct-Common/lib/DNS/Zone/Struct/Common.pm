package DNS::Zone::Struct::Common;

our $DATE = '2019-09-17'; # DATE
our $VERSION = '0.004'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

our %arg_workaround_convert_underscore_in_host = (
    workaround_underscore_in_host => {
        summary => "Whether to convert underscores in hostname to dashes",
        description => <<'_',

Underscore is not a valid character in hostname. This workaround can help a bit
by automatically converting underscores to dashes. Note that it does not ensure
hostnames like `foo_.example.com` to become valid as `foo-.example.com` is also
not a valid hostname.

_
        schema => 'bool*',
        default => 1,
        tags => ['category:workaround'],
    },
);

sub _workaround_convert_underscore_in_host {
    my $recs = shift;

    for (@$recs) {
        if ($_->{host}) {
            my $orig_host = $_->{host};
            if ($_->{host} =~ s/_/-/g) {
                log_warn "There is a host containing underscore '$orig_host'; converting the underscores to dashes";
            }
        }
    }
}

1;
# ABSTRACT: Common routines related to DNS zone structure

__END__

=pod

=encoding UTF-8

=head1 NAME

DNS::Zone::Struct::Common - Common routines related to DNS zone structure

=head1 VERSION

This document describes version 0.004 of DNS::Zone::Struct::Common (from Perl distribution DNS-Zone-Struct-Common), released on 2019-09-17.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/DNS-Zone-Struct-Common>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-DNS-Zone-Struct-Common>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=DNS-Zone-Struct-Common>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
