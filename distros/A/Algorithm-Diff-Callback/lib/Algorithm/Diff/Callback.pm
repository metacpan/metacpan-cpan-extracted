package Algorithm::Diff::Callback;
# ABSTRACT: Use callbacks on computed differences
$Algorithm::Diff::Callback::VERSION = '0.111';
use strict;
use warnings;
use parent          'Exporter';

use Carp            'croak';
use List::Util 1.45 'uniq';
use Algorithm::Diff 'diff';

our @EXPORT_OK = qw(diff_hashes diff_arrays);

sub diff_hashes {
    my ( $old, $new, %cbs ) = @_;

    ref $old eq 'HASH' or croak 'Arg 1 must be hashref';
    ref $new eq 'HASH' or croak 'Arg 2 must be hashref';

    my @changed;
    foreach my $key ( keys %{$new} ) {
        if ( ! exists $old->{$key} ) {
            exists $cbs{'added'}
                and $cbs{'added'}->( $key, $new->{$key} );
        } else {
            push @changed, $key;
        }
    }

    foreach my $key ( keys %{$old} ) {
        if ( ! exists $new->{$key} ) {
            exists $cbs{'deleted'}
                and $cbs{'deleted'}->( $key, $old->{$key} );
        }
    }

    foreach my $key (@changed) {
        my $before = $old->{$key} || '';
        my $after  = $new->{$key} || '';

        if ( $before ne $after ) {
            exists $cbs{'changed'}
                and $cbs{'changed'}->( $key, $before, $after );
        }
    }

    return;
}

sub diff_arrays {
    my ( $old, $new, %cbs ) = @_;

    ref $old eq 'ARRAY' or croak 'Arg 1 must be arrayref';
    ref $new eq 'ARRAY' or croak 'Arg 2 must be arrayref';

    # normalize arrays
    my @old = uniq sort @{$old};
    my @new = uniq sort @{$new};

    my @diffs = diff( \@old, \@new );

    foreach my $diff (@diffs) {
        foreach my $changeset ( @{$diff} ) {
            my ( $change, undef, $value ) = @{$changeset};

            if ( $change eq '+' ) {
                exists $cbs{'added'} and $cbs{'added'}->($value);
            } elsif ( $change eq '-' ) {
                exists $cbs{'deleted'} and $cbs{'deleted'}->($value);
            } else {
                croak "Can't recognize change in changeset: '$change'";
            }
        }
    }

    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Algorithm::Diff::Callback - Use callbacks on computed differences

=head1 VERSION

version 0.111

=head1 SYNOPSIS

Use callbacks in your diff process to get better control over what will happen.

    use Algorithm::Diff::Callback 'diff_arrays';

    diff_arrays(
        \@old_family_members,
        \@new_family_members,
        added   => sub { say 'Happy to hear about ', shift },
        deleted => sub { say 'Sorry to hear about ', shift },
    );

Or using hashes:

    use Algorithm::Diff::Callback 'diff_hashes';

    diff_hashes(
        \%old_details,
        \%new_details,
        added   => sub { say 'Gained ', shift },
        deleted => sub { say 'Lost ',   shift },
        changed => sub {
            my ( $key, $before, $after ) = @_;
            say "$key changed from $before to $after";
        },
    );

=head1 DESCRIPTION

One of the difficulties when using diff modules is that they assume they know
what you want the information for. Some give you formatted output, some give you
just the values that changes (but neglect to mention how each changed) and some
(such as L<Algorithm::Diff>) give you way too much information that you now have
to skim over and write long complex loops for.

L<Algorithm::Diff::Callback> let's you pick what you're going to diff (Arrays or
Hashes) and set callbacks for the diff process.

=head1 EXPORT

You'll need to declare to explicitly export these functions.

=head2 diff_arrays

=head2 diff_hashes

    use Algorithm::Diff::Callback qw<diff_arrays diff_hashes>;

=head1 SUBROUTINES/METHODS

=head2 diff_arrays(\@old, \@new, %callbacks)

The first two parameters are array references to compare.

The rest of the parameters are keys for the type of callback you want and the
corresponding callback. You can provide multiple callbacks. Supported keys are:

=over 4

=item * added

    diff_arrays(
        \@old, \@new,
        added => sub {
            my $value = shift;
            say "$value was added to the array";
        }
    );

=item * deleted

    diff_arrays(
        \@old, \@new,
        deleted => sub {
            my $value = shift;
            say "$value was deleted from the array";
        }
    );

=back

=head2 diff_hashes(\%old, \%new, %callbacks)

The first two parameters are hash references to compare.

The rest of the parameters are keys for the type of callback you want and the
corresponding callback. You can provide multiple callbacks. Supported keys are:

=over 4

=item * added

    diff_hashes(
        \%old, \%new,
        added => sub {
            my ( $key, $value ) = @_;
            say "$key ($value) was added to the hash";
        }
    );

=item * deleted

    diff_hashes(
        \%old, \%new,
        deleted => sub {
            my ( $key, $value ) = @_;
            say "$key ($value) was deleted from the hash";
        }
    );

=item * changed

    diff_hashes(
        \%old, \%new,
        changed => sub {
            my ( $key, $before, $after ) = @_;
            say "$key in the hash was changed from $before to $after";
        }
    );

=back

=head1 BUGS

Please report bugs on the Github issues page at
L<http://github.com/xsawyerx/algorithm-diff-callback/issues>.

=head1 SUPPORT

This module sports 100% test coverage, but in case you have more issues...

You can find documentation for this module with the perldoc command.

    perldoc Algorithm::Diff::Callback

You can also look for information at:

=over 4

=item * Github issues tracker

L<http://github.com/xsawyerx/algorithm-diff-callback/issues>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Algorithm-Diff-Callback>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Algorithm-Diff-Callback>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Algorithm-Diff-Callback>

=item * Search CPAN

L<http://search.cpan.org/dist/Algorithm-Diff-Callback/>

=back

=head1 DEPENDENCIES

L<Algorithm::Diff>

L<List::MoreUtils>

L<Carp>

L<Exporter>

=head1 AUTHOR

Sawyer X <xsawyerx@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Sawyer X.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
