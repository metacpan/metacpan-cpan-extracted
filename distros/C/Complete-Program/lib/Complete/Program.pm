package Complete::Program;

our $DATE = '2016-02-06'; # DATE
our $VERSION = '0.39'; # VERSION

use 5.010001;
use strict;
use warnings;

use Complete::Common qw(:all);

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
                       complete_program
               );

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Completion routines related to program names',
};

$SPEC{complete_program} = {
    v => 1.1,
    summary => 'Complete program name found in PATH',
    description => <<'_',

Windows is supported, on Windows PATH will be split using /;/ instead of /:/.

_
    args => {
        word     => { schema=>[str=>{default=>''}], pos=>0, req=>1 },
    },
    result_naked => 1,
    result => {
        schema => 'array',
    },
};
sub complete_program {
    require Complete::Util;

    my %args = @_;
    my $word     = $args{word} // "";

    my @dirs = split(($^O =~ /Win32/ ? qr/;/ : qr/:/), $ENV{PATH});
    my @all_progs;
    for my $dir (@dirs) {
        opendir my($dh), $dir or next;
        for (readdir($dh)) {
            push @all_progs, $_ if !(-d "$dir/$_") && (-x _);
        }
    }

    Complete::Util::complete_array_elem(
        word => $word, array => \@all_progs,
    );
}

1;
# ABSTRACT: Completion routines related to program names

__END__

=pod

=encoding UTF-8

=head1 NAME

Complete::Program - Completion routines related to program names

=head1 VERSION

This document describes version 0.39 of Complete::Program (from Perl distribution Complete-Program), released on 2016-02-06.

=head1 DESCRIPTION

=head1 FUNCTIONS


=head2 complete_program(%args) -> array

Complete program name found in PATH.

Windows is supported, on Windows PATH will be split using /;/ instead of /:/.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<word>* => I<str> (default: "")

=back

Return value:  (array)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Complete-Program>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Complete-Program>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Complete-Program>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Complete>

Other C<Complete::*> modules.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
