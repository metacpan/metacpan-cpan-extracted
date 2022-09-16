## no critic: Modules::ProhibitAutomaticExportation

package Data::Walk::More;

use 5.010001;
use strict;
use warnings;
use Log::ger;

use Exporter qw(import);
use Scalar::Util qw(blessed reftype refaddr);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-07-21'; # DATE
our $DIST = 'Data-Walk-More'; # DIST
our $VERSION = '0.002'; # VERSION

our @EXPORT = qw(walk walkdepth);

our %_seen_refaddrs;

our $depth;
our @containers;
our $container;
our @indexes;
our $index;
our $prune;

sub _walk {
    my ($opts, $val) = @_;

    my $ref = ref $val;
    if ($ref eq '') {
        local $_ = $val; $opts->{wanted}->($val);
        return;
    }

    my $refaddr = refaddr($val);
    if ($_seen_refaddrs{$refaddr}++) {
        return unless $opts->{follow};
    }

    my $class;
    if (blessed $val) {
        $class = $ref;
        $ref = reftype($val);
    }

  RECURSE_ARRAY_HASH: {
        last unless $ref eq 'ARRAY' || $ref eq 'HASH';
        last if !$opts->{recurseobjects} && defined $class;

        unless ($opts->{bydepth}) {
            local $_ = $val; $opts->{wanted}->($val);
        }

        if ($prune) {
            $prune = 0;
            return;
        }

        {
            local $depth = $depth + 1;
            local @containers = (@containers, $val);
            local $container = $containers[-1];
            local @indexes = (@indexes, undef);
            local $index;
            if ($ref eq 'ARRAY') {
                for my $i (0..$#{$val}) {
                    $indexes[-1] = $i;
                    $index       = $i;
                    _walk($opts, $val->[$i]);
                }
            } else { # HASH
                for my $k ($opts->{sortkeys} ? (sort keys %$val) : (keys %$val)) {
                    $indexes[-1] = $k;
                    $index       = $k;
                    _walk($opts, $val->{$k});
                }
            }
        }

        if ($opts->{bydepth}) {
            local $_ = $val; $opts->{wanted}->($val);
        }

        return;
    } # RECURSE_ARRAY_HASH

    local $_ = $val; $opts->{wanted}->($val);
    return;
}

sub walk {
    my $opts = ref($_[0]) eq 'HASH' ? { %{shift()} } : { wanted=>shift() };
    $opts->{recurseobjects} //= 1;
    $opts->{sortkeys} //= 1;

    local %_seen_refaddrs;
    for my $data (@_) {
        local $depth = 0;
        local $prune = 0;
        _walk($opts, $data);
    }
}

sub walkdepth {
    my $opts = ref($_[0]) eq 'HASH' ? { %{shift()} } : { wanted=>shift() };
    $opts->{bydepth} = 1;
    walk($opts, @_);
}

1;
# ABSTRACT: Traverse Perl data structures, with more information during traversing

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Walk::More - Traverse Perl data structures, with more information during traversing

=head1 VERSION

This document describes version 0.002 of Data::Walk::More (from Perl distribution Data-Walk-More), released on 2022-07-21.

=head1 SYNOPSIS

 use Data::Walk::More; # exports walk() and walkdepth()

 walk \&wanted, @items_to_walk;
 walkdepth \&wanted, @items_to_walk;

 # full options
 walk {
     wanted => \&wanted,
     # follow => 0,         # whether to follow circular refs, default is 0.
     # bydepth => 0,        # whether to descend into subnodes first. default is 0.
     # sortkeys => 1,       # whether to visit hash values in key order. default is 1.
     # recurseobjects => 1, # whether to recurse into objects. default is 1.
 }, @items_to_walk;

=head1 DESCRIPTION

This module is like L<Data::Walk>, but there are a few differences, a few more
options, and the callback gets more information.

=head1 VARIABLES

The following variables are available for the callback. Unless specified
otherwise, do not modify these during traversing.

=head2 $Data::Walk::More::depth

Integer, starts at 0.

=head2 @Data::Walk::More::containers

=head2 $Data::Walk::More::container

=head2 @Data::Walk::More::indexes

=head2 $Data::Walk::More::index

=head2 $Data::Walk::More::prune

Can be set to true to prevent Data::Walk::More to descend into hash or array.
Ineffective when you use L</bydepth> option, since Data::Walk::More will have
already descended into hash or array before the callback can prune it.

=head1 DIFFERENCES BETWEEN DATA::WALK::MORE (DWM) WITH DATA::WALK (DW)

DWM also provides the full path (containers from the top level, in
C<@containers> and <@indexes>) instead of just the immediate container in
C<$container> and C<$index>.

When traversing hash, C<$index> package variable in DWM refers to hash key, not
a number, which is more useful in my opinion.

You can prune (avoid descending) by setting C<$prune>.

=head1 FUNCTIONS

=head2 walk

Options:

=head3 wanted

=head3 bydepth

=head3 follow

=head3 sortkeys

=head3 recurseobjects

=head2 walkdepth

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Walk-More>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Walk-More>.

=head1 SEE ALSO

L<Data::Walk>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022, 2020 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Walk-More>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
