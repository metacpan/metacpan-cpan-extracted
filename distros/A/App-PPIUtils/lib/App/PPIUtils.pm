package App::PPIUtils;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-10-02'; # DATE
our $DIST = 'App-PPIUtils'; # DIST
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

use File::Slurper::Dash 'read_text';
use Sort::Sub;

our %SPEC;

our %arg0_filename = (
    filename => {
        summary => 'Path to Perl script/module',
        schema => 'filename*',
        default => '-',
        pos => 0,
    },
);

our %arg0_filenames = (
    filenames => {
        'x.name.is_plural' => 1,
        'x.name.singular' => 'filename',
        summary => 'Paths to Perl scripts/modules',
        schema => ['array*', of=>'filename*'],
        pos => 0,
        default => ['-'],
        slurpy => 1,
    },
);

sub _sort {
    my ($doc, $sorter, $sorter_meta) = @_;

    my @children = @{ $doc->{children} // [] };
    return unless @children;

    require Sort::SubList;
    my @sorted_children =
        map { $children[$_] }
        Sort::SubList::sort_sublist(
            sub {
                if ($sorter_meta->{compares_record}) {
                    my $rec0 = [$children[$_[0]]->name, $_[0]];
                    my $rec1 = [$children[$_[1]]->name, $_[1]];
                    $sorter->($rec0, $rec1);
                } else {
                    #say "D: ", $children[$_[0]]->name, " vs ", $children[$_[1]]->name;
                    $sorter->($children[$_[0]]->name, $children[$_[1]]->name);
                }
            },
            sub { $children[$_]->isa('PPI::Statement::Sub') && $children[$_]->name },
            0..$#children);
    $doc->{children} = \@sorted_children;
}

$Sort::Sub::argsopt_sortsub{sort_sub}{cmdline_aliases} = {S=>{}};
$Sort::Sub::argsopt_sortsub{sort_args}{cmdline_aliases} = {A=>{}};

$SPEC{sort_perl_subs} = {
    v => 1.1,
    summary => 'Sort Perl named subroutines by their name',
    description => <<'_',

This utility sorts Perl subroutine definitions in source code. By default it
sorts asciibetically. For example this source:

    sub one {
       ...
    }

    sub two { ... }

    sub three {}

After the sort, it will become:

    sub one {
       ...
    }

    sub three {}

    sub two { ... }

Caveat: if you intersperse POD documentation, currently it will not be moved
along with the subroutines.

_
    args => {
        %arg0_filename,
        %Sort::Sub::argsopt_sortsub,
    },
    result_naked => 1,
};
sub sort_perl_subs {
    require PPI::Document;

    my %args = @_;

    my $sortsub_routine = $args{sort_sub} // 'asciibetically';
    my $sortsub_args    = $args{sort_args} // {};

    my $source = read_text($args{filename});
    my $doc = PPI::Document->new(\$source);
    my ($sorter, $sorter_meta) =
        Sort::Sub::get_sorter($sortsub_routine, $sortsub_args, 'with meta');
    _sort($doc, $sorter, $sorter_meta);
    "$doc";
}

$SPEC{reverse_perl_subs} = {
    v => 1.1,
    summary => 'Reverse Perl subroutines',
    args => {
        %arg0_filename,
    },
    result_naked => 1,
};
sub reverse_perl_subs {
    my %args = @_;
    sort_perl_subs(%args, sort_sub=>'record_by_reverse_order');
}

1;
# ABSTRACT: Command-line utilities related to PPI

__END__

=pod

=encoding UTF-8

=head1 NAME

App::PPIUtils - Command-line utilities related to PPI

=head1 VERSION

This document describes version 0.001 of App::PPIUtils (from Perl distribution App-PPIUtils), released on 2020-10-02.

=head1 SYNOPSIS

This distribution provides the following command-line utilities related to
L<PPI>:

=over

=item * L<reverse-perl-subs>

=item * L<sort-perl-subs>

=back

=head1 FUNCTIONS


=head2 reverse_perl_subs

Usage:

 reverse_perl_subs(%args) -> any

Reverse Perl subroutines.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<filename> => I<filename> (default: "-")

Path to Perl scriptE<sol>module.


=back

Return value:  (any)



=head2 sort_perl_subs

Usage:

 sort_perl_subs(%args) -> any

Sort Perl named subroutines by their name.

This utility sorts Perl subroutine definitions in source code. By default it
sorts asciibetically. For example this source:

 sub one {
    ...
 }
 
 sub two { ... }
 
 sub three {}

After the sort, it will become:

 sub one {
    ...
 }
 
 sub three {}
 
 sub two { ... }

Caveat: if you intersperse POD documentation, currently it will not be moved
along with the subroutines.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<filename> => I<filename> (default: "-")

Path to Perl scriptE<sol>module.

=item * B<sort_args> => I<array[str]>

Arguments to pass to the Sort::Sub::* routine.

=item * B<sort_sub> => I<sortsub::spec>

Name of a Sort::Sub::* module (without the prefix).


=back

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-PPIUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-PPIUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-PPIUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<PPI>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
