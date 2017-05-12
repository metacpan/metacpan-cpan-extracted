package Complete::TZ;

our $DATE = '2015-11-29'; # DATE
our $VERSION = '0.07'; # VERSION

use 5.010001;
use strict;
use warnings;
#use Log::Any '$log';

use Complete::Common qw(:all);
use Complete::Util qw(hashify_answer);

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
                       complete_tz
                );

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Timezone-related completion routines',
};

$SPEC{complete_tz} = {
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
sub complete_tz {
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

1;
# ABSTRACT: Timezone-related completion routines

__END__

=pod

=encoding UTF-8

=head1 NAME

Complete::TZ - Timezone-related completion routines

=head1 VERSION

This document describes version 0.07 of Complete::TZ (from Perl distribution Complete-TZ), released on 2015-11-29.

=head1 DESCRIPTION

=head1 FUNCTIONS


=head2 complete_tz(%args) -> array

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

=head1 SEE ALSO

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Complete-TZ>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Complete-TZ>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Complete-TZ>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
