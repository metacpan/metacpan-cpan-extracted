package Complete::TZ;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-02-27'; # DATE
our $DIST = 'Complete-TZ'; # DIST
our $VERSION = '0.081'; # VERSION

use 5.010001;
use strict;
use warnings;

use Complete::Common qw(:all);
use Complete::Util qw(hashify_answer);
use Sah::Schema::date::tz_offset;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
                       complete_tz_name
                       complete_tz_offset
                       complete_tz
                );

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Timezone-related completion routines',
};

$SPEC{complete_tz_name} = {
    v => 1.1,
    summary => 'Complete from list of timezone names',
    description => <<'_',

Currently implemented via looking at `/usr/share/zoneinfo`, so this only works
on systems that have that.

_
    args => {
        %arg_word,
    },
    result_naked => 1,
    result => {
        schema => 'array',
    },
};
sub complete_tz_name {
    require Complete::File;

    my %args  = @_;
    my $word  = $args{word} // "";

    my $res = hashify_answer(Complete::File::complete_file(
        starting_path => '/usr/share/zoneinfo',
        handle_tilde => 0,
        allow_dot => 0,
        filter => sub {
            return 0 if $_[0] =~ /\.tab$/;
            1;
        },

        word => $word,
    ));
    $res->{path_sep} = '/';
    $res;
}

# old name
*complete_tz = \&complete_tz_name;

$SPEC{complete_tz_offset} = {
    v => 1.1,
    summary => 'Complete from list of existing timezone offsets (in the form of -HH:MM(:SS)? or +HH:MM(:SS)?)',
    description => <<'_',

_
    args => {
        %arg_word,
    },
    result_naked => 1,
    result => {
        schema => 'array',
    },
};
sub complete_tz_offset {
    require Complete::Util;

    my %args  = @_;
    my $word  = $args{word} // "";

    Complete::Util::complete_array_elem(
        word => $word,
        array => \@Sah::Schema::date::tz_offset::TZ_STRING_OFFSETS,
    );
}

1;
# ABSTRACT: Timezone-related completion routines

__END__

=pod

=encoding UTF-8

=head1 NAME

Complete::TZ - Timezone-related completion routines

=head1 VERSION

This document describes version 0.081 of Complete::TZ (from Perl distribution Complete-TZ), released on 2020-02-27.

=head1 DESCRIPTION

=head1 FUNCTIONS


=head2 complete_tz_name

Usage:

 complete_tz_name(%args) -> array

Complete from list of timezone names.

Currently implemented via looking at C</usr/share/zoneinfo>, so this only works
on systems that have that.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<word>* => I<str> (default: "")

Word to complete.


=back

Return value:  (array)



=head2 complete_tz_offset

Usage:

 complete_tz_offset(%args) -> array

Complete from list of existing timezone offsets (in the form of -HH:MM(:SS)? or +HH:MM(:SS)?).

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<word>* => I<str> (default: "")

Word to complete.


=back

Return value:  (array)

=for Pod::Coverage ^(complete_tz)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Complete-TZ>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Complete-TZ>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Complete-TZ>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
