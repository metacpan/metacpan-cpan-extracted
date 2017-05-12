package Complete::Riap;

our $DATE = '2015-11-29'; # DATE
our $VERSION = '0.07'; # VERSION

use 5.010001;
use strict;
use warnings;

use Complete::Common qw(:all);

our %SPEC;
require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(complete_riap_url);

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Riap-related completion routines',
};

$SPEC{complete_riap_url} = {
    v => 1.1,
    summary => 'Complete Riap URL',
    description => <<'_',

Currently only support local Perl schemes (e.g. `/Pkg/Subpkg/function` or
`pl:/Pkg/Subpkg/`).

_
    args => {
        %arg_word,
        type => {
            schema => ['str*', in=>['function','package']], # XXX other types?
            summary => 'Filter by entity type',
        },
        riap_client => {
            schema => 'obj*',
        },
    },
    result_naked => 1,
};
sub complete_riap_url {
    require Complete::Path;

    my %args = @_;

    my $word = $args{word} // ''; $word = '/' if !length($word);
    $word = "/$word" unless $word =~ m!\A/!;
    my $type = $args{type} // '';

    my $starting_path;
    my $result_prefix = '';
    if ($word =~ s!\A/!!) {
        $starting_path = '/';
        $result_prefix = '/';
    } elsif ($word =~ s!\Apl:/!/!) {
        $starting_path = 'pl:';
        $result_prefix = 'pl:';
    } else {
        return [];
    }

    my $res = Complete::Path::complete_path(
        word => $word,
        list_func => sub {
            my ($path, $intdir, $isint) = @_;

            state $default_pa = do {
                require Perinci::Access;
                Perinci::Access->new;
            };
            my $pa = $args{riap_client} // $default_pa;

            $path = "/$path" unless $path =~ m!\A/!;
            my $riap_res = $pa->request(list => $path, {detail=>1});
            return [] unless $riap_res->[0] == 200;
            my @res;
            for my $ent (@{ $riap_res->[2] }) {
                next unless $ent->{type} eq 'package' ||
                    (!$type || $type eq $ent->{type});
                push @res, $ent->{uri};
            }
            \@res;
        },
        starting_path => $starting_path,
        result_prefix => $result_prefix,
        is_dir_func => sub { }, # not needed, we already suffixed "dir" with /
    );

    {words=>$res, path_sep=>'/'};
}

1;
# ABSTRACT: Riap-related completion routines

__END__

=pod

=encoding UTF-8

=head1 NAME

Complete::Riap - Riap-related completion routines

=head1 VERSION

This document describes version 0.07 of Complete::Riap (from Perl distribution Complete-Riap), released on 2015-11-29.

=head1 SYNOPSIS

 use Complete::Riap qw(complete_riap_url);
 my $res = complete_riap_url(word => '/Te', type=>'package');
 # -> {word=>['/Template/', '/Test/', '/Text/'], path_sep=>'/'}

=head1 FUNCTIONS


=head2 complete_riap_url(%args) -> any

Complete Riap URL.

Currently only support local Perl schemes (e.g. C</Pkg/Subpkg/function> or
C<pl:/Pkg/Subpkg/>).

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<riap_client> => I<obj>

=item * B<type> => I<str>

Filter by entity type.

=item * B<word>* => I<str> (default: "")

Word to complete.

=back

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Complete-Riap>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Complete-Riap>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Complete-Riap>

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
