package CPAN::Dashboard::Distribution;
$CPAN::Dashboard::Distribution::VERSION = '0.02';
use 5.006;
use Moo;

has 'name'           => ( is => 'ro' );
has 'modules'        => ( is => 'rw' );
has 'release_path'   => ( is => 'rw' );
has 'distinfo'       => ( is => 'rw' );
has 'version'        => ( is => 'rw' );
has 'is_developer'   => ( is => 'rw' );
has 'release_date'   => ( is => 'rw' );
has 'owner'          => ( is => 'rw' );
has 'bug_count'      => ( is => 'rw' );
has 'rev_deps_count' => ( is => 'rw' );
has 'cpan_testers'   => ( is => 'rw' );
has 'kwalitee'       => ( is => 'rw' );
has 'rating'         => ( is => 'lazy' );

sub _build_rating
{
    my $self = shift;
    my $rating = 0;

    #
    # Do all the negative components first
    #

    $rating-- if ($self->version =~ /^0\./);
    $rating-- if ($self->is_developer);

    my @owners = @{ $self->owner };
    if (@owners == 1) {
        # no owners (only co-maint(s)
        $rating-- if $owners[0] eq '__undef';
    }
    else {
        # more than one owner
        $rating--;
    }

    $rating-- if $self->bug_count > 0;
    $rating-- if $self->bug_count > 10;

    if (!defined($self->kwalitee) || $self->kwalitee->core_kwalitee < 100) {
        $rating--;
    }

    if (!defined($self->cpan_testers)) {
        # if we could find a CPAN Testers, it means either the site
        # was down, so it's a new module.
        # Seems fair to assume the worst :-)
        $rating--;
    }
    else {
        my $testers = $self->cpan_testers;
        my $total   = $testers->passes + $testers->fails + $testers->unknowns;
        my $score   = $total > 0 ? $testers->passes / $total : 0;

        if ($total < 100 || ($score < 0.95 && $score > 0.5)) {
            $rating--;
        }
        elsif ($score < 0.5) {
            $rating -= 2;
        }
    }

    #
    # You can only go positive if you didn't have any negative components
    #
    if ($rating < 0) {
        return $rating;
    }

    $rating++ if $self->bug_count == 0;

    # TODO: should only get +1 if the dependent dist isn't also yours
    $rating++ if $self->rev_deps_count > 1;

    $rating++ if $self->kwalitee->kwalitee >= 130;
    $rating++ if $self->cpan_testers->fails == 0
              && $self->cpan_testers->unknowns == 0;

    return $rating;
}

1;

=head1 NAME

CPAN::Dashboard::Distribution - Package to manage the distribution for CPAN Dashboard.

=head1 DESCRIPTION

B<FOR INTERNAL USE ONLY>

=head1 REPOSITORY

L<https://github.com/neilbowers/CPAN-Dashboard>

=head1 AUTHOR

Neil Bowers E<lt>neilb@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Neil Bowers <neilb@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
