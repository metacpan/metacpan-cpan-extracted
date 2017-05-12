package Data::Circular::Util;

our $DATE = '2015-09-03'; # DATE
our $VERSION = '0.59'; # VERSION

use 5.010001;
use strict;
use warnings;
#use experimental 'smartmatch';

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(clone_circular_refs has_circular_ref);

our %SPEC;

$SPEC{clone_circular_refs} = {
    v => 1.1,
    summary => 'Remove circular references by deep-copying them',
    description => <<'_',

For example, this data:

    $x = [1];
    $data = [$x, 2, $x];

contains circular references by referring to `$x` twice. After
`clone_circular_refs`, data will become:

    $data = [$x, 2, [1]];

that is, the subsequent circular references will be deep-copied. This makes it
safe to transport to JSON, for example.

Sometimes it doesn't work, for example:

    $data = [1];
    push @$data, $data;

Cloning will still create circular references.

This function modifies the data structure in-place, and return true for success
and false upon failure.

_
    args_as => 'array',
    args => {
        data => {
            schema => "any",
            pos => 0,
            req => 1,
        },
    },
    result_naked => 1,
};
sub clone_circular_refs {
    require Data::Clone;

    my ($data) = @_;
    my %refs;
    my $doit;
    $doit = sub {
        my $x = shift;
        my $r = ref($x);
        return if !$r;
        if ($r eq 'ARRAY') {
            for (@$x) {
                next unless ref($_);
                if ($refs{"$_"}++) {
                    $_ = Data::Clone::clone($_);
                } else {
                    $doit->($_);
                }
            }
        } elsif ($r eq 'HASH') {
            for (keys %$x) {
                next unless ref($x->{$_});
                if ($refs{"$x->{$_}"}++) {
                    $x->{$_} = Data::Clone::clone($x->{$_});
                } else {
                    $doit->($_);
                }
            }
        }
    };
    $doit->($data);
    !has_circular_ref($data);
}

$SPEC{has_circular_ref} = {
    v => 1.1,
    summary => 'Check whether data item contains circular references',
    description => <<'_',

Does not deal with weak references.

_
    args_as => 'array',
    args => {
        data => {
            schema => "any",
            pos => 0,
            req => 1,
        },
    },
    result_naked => 1,
};
sub has_circular_ref {
    my ($data) = @_;
    my %refs;
    my $check;
    $check = sub {
        my $x = shift;
        my $r = ref($x);
        return 0 if !$r;
        return 1 if $refs{"$x"}++;
        if ($r eq 'ARRAY') {
            for (@$x) {
                next unless ref($_);
                return 1 if $check->($_);
            }
        } elsif ($r eq 'HASH') {
            for (values %$x) {
                next unless ref($_);
                return 1 if $check->($_);
            }
        }
        0;
    };
    $check->($data);
}

1;
# ABSTRACT: Remove circular references by deep-copying them

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Circular::Util - Remove circular references by deep-copying them

=head1 VERSION

This document describes version 0.59 of Data::Circular::Util (from Perl distribution Data-Circular-Util), released on 2015-09-03.

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 FUNCTIONS


=head2 clone_circular_refs($data) -> any

Remove circular references by deep-copying them.

For example, this data:

 $x = [1];
 $data = [$x, 2, $x];

contains circular references by referring to C<$x> twice. After
C<clone_circular_refs>, data will become:

 $data = [$x, 2, [1]];

that is, the subsequent circular references will be deep-copied. This makes it
safe to transport to JSON, for example.

Sometimes it doesn't work, for example:

 $data = [1];
 push @$data, $data;

Cloning will still create circular references.

This function modifies the data structure in-place, and return true for success
and false upon failure.

Arguments ('*' denotes required arguments):

=over 4

=item * B<data>* => I<any>

=back

Return value:  (any)


=head2 has_circular_ref($data) -> any

Check whether data item contains circular references.

Does not deal with weak references.

Arguments ('*' denotes required arguments):

=over 4

=item * B<data>* => I<any>

=back

Return value:  (any)

=head1 SEE ALSO

L<SHARYANTO>

L<Data::Structure::Util> has the XS version of C<has_circular_ref> which is at
least around 3 times faster than this module's implementation which is pure
Perl. Use that instead if possible (in some cases, Data::Structure::Util fails
to build and this module provides an alternative for that function).
Data::Structure::Util does not the equivalent of this module's
C<clone_circular_refs> though.

This module is however much faster than L<Devel::Cycle>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Circular-Util>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-SHARYANTO-Data-Util>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Circular-Util>

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
