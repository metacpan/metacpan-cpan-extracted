package Complete::Perl;

our $DATE = '2016-10-18'; # DATE
our $VERSION = '0.05'; # VERSION

use 5.010001;
use strict;
use warnings;

#use List::MoreUtils qw(uniq);

use Complete::Common qw(:all);

our %SPEC;
require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(
                       complete_perl_version
                       complete_perl_builtin_function
                       complete_perl_builtin_symbol
               );

$SPEC{complete_perl_builtin_function} = {
    v => 1.1,
    description => <<'_',

Currently using `@Functions` from <pm:B::Keywords>.

_
    args => {
        %arg_word,
    },
    result_naked => 1,
};
sub complete_perl_builtin_function {
    require B::Keywords;
    require Complete::Util;

    my %args = @_;
    Complete::Util::complete_array_elem(
        word => $args{word},
        array => \@B::Keywords::Functions,
    );
}

$SPEC{complete_perl_builtin_symbol} = {
    v => 1.1,
    description => <<'_',

Currently using `@Symbols` from <pm:B::Keywords>.

_
    args => {
        %arg_word,
    },
    result_naked => 1,
};
sub complete_perl_builtin_symbol {
    require B::Keywords;
    require Complete::Util;

    my %args = @_;
    Complete::Util::complete_array_elem(
        word => $args{word},
        array => \@B::Keywords::Symbols,
    );
}

$SPEC{complete_perl_version} = {
    v => 1.1,
    args => {
        %arg_word,
        use_v => {
            summary => 'Whether to prefix the perl versions with "v"',
            schema => 'bool',
            description => <<'_',

If not specified, then if the word starts with v then will default to true.

_
        },
        dev => {
            summary => 'Whether to include development perl releases',
            schema => 'bool',
            description => <<'_',

If not specified, then will first try completing without development releases
and if none is found will try with.

_
        },
    },
    result_naked => 1,
};
sub complete_perl_version {
    require Complete::Util;
    require Module::CoreList;

    my %args = @_;
    my $word = $args{word} // '';
    my $use_v = $args{use_v} // do {
        $word =~ /\A[Vv]/ ? 1:0;
    };
    my $dev = $args{dev};

    my @with_devs;
    if ($dev) {
        @with_devs = (1);
    } elsif (defined $dev) {
        @with_devs = (0);
    } else {
        @with_devs = (0,1);
    }

    my $res;
    for my $with_dev (@with_devs) {
        my @vers   = sort keys %Module::CoreList::version;
        unless ($with_dev) {
            @vers = grep {
                my $v = version->parse($_)->normal;
                my ($minor) = $v =~ /\.(\d+)/; $minor //= 0;
                $minor % 2 == 0;
            } @vers;
        }
        my @vers_normalv    = map {version->parse($_)->normal} @vers;
        my @vers_normalnonv = map {my $v = $_; $v =~ s/\Av//; $v }
            @vers_normalv;

        local $Complete::Common::OPT_FUZZY = 0;
        if ($use_v) {
            $res = Complete::Util::complete_array_elem(
                word=>$word, array => \@vers_normalv);
        } elsif ($word =~ /\..+\./) {
            $res = Complete::Util::complete_array_elem(
                word=>$word, array => \@vers_normalnonv);
        } else {
            $res = Complete::Util::complete_array_elem(
                word=>$word, array => \@vers);
        }
        last if @$res;
    }
    $res;
}

1;
# ABSTRACT: Complete various Perl entities

__END__

=pod

=encoding UTF-8

=head1 NAME

Complete::Perl - Complete various Perl entities

=head1 VERSION

This document describes version 0.05 of Complete::Perl (from Perl distribution Complete-Perl), released on 2016-10-18.

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 FUNCTIONS


=head2 complete_perl_builtin_function(%args) -> any

Currently using C<@Functions> from L<B::Keywords>.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<word>* => I<str> (default: "")

Word to complete.

=back

Return value:  (any)


=head2 complete_perl_builtin_symbol(%args) -> any

Currently using C<@Symbols> from L<B::Keywords>.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<word>* => I<str> (default: "")

Word to complete.

=back

Return value:  (any)


=head2 complete_perl_version(%args) -> any

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<dev> => I<bool>

Whether to include development perl releases.

If not specified, then will first try completing without development releases
and if none is found will try with.

=item * B<use_v> => I<bool>

Whether to prefix the perl versions with "v".

If not specified, then if the word starts with v then will default to true.

=item * B<word>* => I<str> (default: "")

Word to complete.

=back

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Complete-Perl>.

=head1 SOURCE

Source repository is at L<https://github.com/sharyanto/perl-Complete-Perl>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Complete-Perl>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Complete>

L<Complete::Module>

L<Reply> (which has plugins to complete global variables, user-defined
functions, lexicals, methods, packages, and so on).

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
