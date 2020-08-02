package App::perlmv::scriptlet::remove_common_suffix;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-08-02'; # DATE
our $DIST = 'App-perlmv'; # DIST
our $VERSION = '0.600'; # VERSION

use 5.010001;
use strict;
use warnings;

our $SCRIPTLET = {
    summary => q[Remove suffix that are common to all args, while preserving extension, e.g. (1-radiolab.mp3, 2-radiolab.mp3) -> (1.mp3, 2.mp3)],
    code => sub {
        package
            App::perlmv::code;
        use vars qw($COMMON_SUFFIX $TESTING $FILES $EXT);

        if (!defined($COMMON_SUFFIX) && !$TESTING) {
            for (@$FILES) { $_ = reverse };
            my $i;
            for ($i=0; $i<length($FILES->[0]); $i++) {
                last if grep { substr($_, $i, 1) ne substr($FILES->[0], $i, 1) } @{$FILES}[1..@$FILES-1];
            }
            $COMMON_SUFFIX = reverse substr($FILES->[0], 0, $i);
            for (@$FILES) { $_ = reverse };
            # don't wipe extension, if exists
            $EXT = $COMMON_SUFFIX =~ /.(\.\w+)$/ ? $1 : "";
        }
        s/\Q$COMMON_SUFFIX\E$/$EXT/;
        $_;
    },
};

1;

# ABSTRACT:

__END__

=pod

=encoding UTF-8

=head1 NAME

App::perlmv::scriptlet::remove_common_suffix

=head1 VERSION

This document describes version 0.600 of App::perlmv::scriptlet::remove_common_suffix (from Perl distribution App-perlmv), released on 2020-08-02.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-perlmv>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-perlmv>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-perlmv>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2015, 2014, 2013, 2012, 2011, 2010 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
