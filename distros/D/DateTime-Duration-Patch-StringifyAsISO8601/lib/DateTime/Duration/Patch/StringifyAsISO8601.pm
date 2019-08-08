package DateTime::Duration::Patch::StringifyAsISO8601;

our $DATE = '2019-06-19'; # DATE
our $VERSION = '0.001'; # VERSION

use strict;
use warnings;

require DateTime::Duration;

package # hide from PAUSE
    DateTime::Duration;

use overload (
    q{""} => 'stringify',
);

sub stringify {
    require DateTime::Format::Duration::ISO8601;
    my $self = shift;
    DateTime::Format::Duration::ISO8601->new->format_duration($self);
}

1;
# ABSTRACT: Make DateTime::Duration objects stringify to ISO8601 duration

__END__

=pod

=encoding UTF-8

=head1 NAME

DateTime::Duration::Patch::StringifyAsISO8601 - Make DateTime::Duration objects stringify to ISO8601 duration

=head1 VERSION

This document describes version 0.001 of DateTime::Duration::Patch::StringifyAsISO8601 (from Perl distribution DateTime-Duration-Patch-StringifyAsISO8601), released on 2019-06-19.

=head1 SYNOPSIS

 use DateTime::Duration;
 use DateTime::Duration::Patch::StringifyAsISO8601;

 my $dur = DateTime::Duration->new(years => 1, months => 2);
 say $dur; # => "P1Y2M"

=head1 DESCRIPTION

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/DateTime-Duration-Patch-StringifyAsISO8601>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-DateTime-Duration-Patch-StringifyAsISO8601>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=DateTime-Duration-Patch-StringifyAsISO8601>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<DateTime::Duration>

L<DateTime::Format::Duration::ISO8601>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
