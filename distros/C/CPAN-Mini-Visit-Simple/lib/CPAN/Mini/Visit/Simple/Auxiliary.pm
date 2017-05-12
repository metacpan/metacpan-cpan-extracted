package CPAN::Mini::Visit::Simple::Auxiliary;
use 5.010;
use strict;
use warnings;
our @ISA       = qw( Exporter );
our @EXPORT_OK = qw(
    $ARCHIVE_REGEX
    dedupe_superseded
    get_lookup_table
    normalize_version_number
    create_minicpan_for_testing
    create_one_new_distro_version
    create_file
);
use Carp;
use File::Basename;
use File::Path qw( make_path );
use File::Spec;
use File::Temp qw( tempdir );

our $ARCHIVE_REGEX = qr{\.(?:
    tar\.(?:bz2|gz|Z) |
    t(?:gz|bz)          |
    zip                 |
    gz
)$}ix; 
sub dedupe_superseded {
    my $listref = shift;
    my (%version_seen, @newlist);
    DISTRO:  foreach my $distro (@$listref) {
        my $dir;
        eval { $dir   = dirname($distro); };
        if ($@) {
            say STDERR "Problem calling File::Basename::dirname on '$distro'";
            say STDERR $@;
            next DISTRO;
        }
        my $base  = basename($distro);
        if ($base =~ m/^(.*)-([\d\.]+)(?:$ARCHIVE_REGEX)/) {
            my ($stem, $version) = ($1,$2);
            my $k = File::Spec->catfile($dir, $stem);
            if ( not $version_seen{$k}{version} ) {
                $version_seen{$k} = {
                    distro => $distro,
                    version => normalize_version_number($version),
                };
            }
            else {
                my $norm_current =
                    normalize_version_number($version_seen{$k}{version});
                my $norm_new = normalize_version_number($version);
                if ( $norm_new > $norm_current ) {
                    $version_seen{$k} = {
                        distro => $distro,
                        version => $norm_new,
                    };
                }
            }
        }
        else {
            push @newlist, $distro;
        }
    }
    foreach my $k (keys %version_seen) {
        push @newlist, $version_seen{$k}{distro};
    }
    return [ sort @newlist ];
}

sub get_lookup_table {
    my $distributions_ref = shift;
    my %lookup_table = ();
    foreach my $distro ( @{$distributions_ref} ) {
        my $dir   = dirname($distro);
        my $base  = basename($distro);
        if ($base =~ m/^(.*)-([\d\.]+)(?:$ARCHIVE_REGEX)/) {
            my ($stem, $version) = ($1,$2);
            my $k = File::Spec->catfile($dir, $stem);
            $lookup_table{$k} = {
                distro => $distro,
                version => normalize_version_number($version),
            };
        }
        else {
            # Since we don't have any authoritative way to compare version
            # numbers that can't be normalized, we will (for now) pass over
            # distributions with non-standard version numbers.
        }
    }
    return \%lookup_table;
}

sub normalize_version_number {
    my $v = shift;
    my @captures = split /\./, $v;
    $captures[0] =~ s/^v//;
    my $normalized;
    if ( $captures[0] eq q{} ) {
        $normalized = 0;
    }
    else {
        $normalized = 0+$captures[0];
    }

    $normalized .= '.';
    for my $cap (@captures[1..$#captures]) {
        $normalized .= sprintf("%05d", $cap);
    }
    $normalized =~ s/-//g;
    return $normalized;
}

sub create_minicpan_for_testing {
    my ( $tdir, $id_dir, $author_dir );
    my ( @source_list );
    # Prepare the test by creating a minicpan in a temporary directory.
    $tdir = tempdir( CLEANUP => 1 );
    $id_dir = File::Spec->catdir($tdir, qw( authors id ));
    make_path($id_dir, { mode => 0711 });
    Test::More::ok( -d $id_dir, "'authors/id' directory created for testing" );
    $author_dir = File::Spec->catdir($id_dir, qw( A AA AARDVARK ) );
    make_path($author_dir, { mode => 0711 });
    Test::More::ok( -d $author_dir, "'author's directory created for testing" );

    @source_list = qw(
        Alpha-Beta-0.01.tar.gz
        Gamma-Delta-0.02.tar.gz
        Epsilon-Zeta-0.03.tar.gz
    );
    foreach my $distro (@source_list) {
        my $fulldistro = File::Spec->catfile($author_dir, $distro);
        create_file($fulldistro);
        Test::More::ok( ( -f $fulldistro ), "$fulldistro created" );
    }
    return ($tdir, $author_dir);
}

sub create_one_new_distro_version {
    my ($author_dir) = @_;
    # Bump up the version number of one distro in the minicpan
    my $remove = q{Epsilon-Zeta-0.03.tar.gz};
    my $removed_file = File::Spec->catfile($author_dir, $remove);
    Test::More::is( unlink($removed_file), 1, "$removed_file deleted" );

    my $update = q{Epsilon-Zeta-0.04.tar.gz};
    my $updated_file = File::Spec->catfile($author_dir, $update);
    create_file($updated_file);
    Test::More::ok( ( -f $updated_file ), "$updated_file created" );
}

sub create_file {
    my $file = shift;
    open my $FH, '>', $file
        or croak "Unable to open handle to $file for writing";
    say $FH q{};
    close $FH or croak "Unable to close handle to $file after writing";
}

1;


=head1 NAME

CPAN::Mini::Visit::Simple::Auxiliary - Helper functions for CPAN::Mini::Visit::Simple

=head1 SYNOPSIS

    use CPAN::Mini::Visit::Simple::Auxiliary qw(
        $ARCHIVE_REGEX
        dedupe_superseded
        get_lookup_table
        normalize_version_number
    );

=head1 DESCRIPTION

This package provides subroutines, exported on demand only, which are used in
Perl extension CPAN-Mini-Visit-Simple and its test suite.

=head1 SUBROUTINES

=head2 C<dedupe_superseded()>

=over 4

=item * Purpose

Due to what is probably a bug in CPAN::Mini, a minicpan repository may, under
its F<author/id/> directory, contain two or more versions of a single CPAN
distribution.  Example:

    minicpan/authors/id/D/DR/DROLSKY/Class-MOP-0.82.tar.gz
    minicpan/authors/id/D/DR/DROLSKY/Class-MOP-0.88.tar.gz
    minicpan/authors/id/D/DR/DROLSKY/Class-MOP-0.98.tar.gz

This I<may> be due to an algorithm which searches for the most recent version
of each Perl I<module> on CPAN and then places the I<distribution> in which it
is found in the minicpan -- even if that module is not found in the most
recent version of the distribution.

Be this as it may, if you are using a minicpan, chances are that you really
want only the most recent version of a particular CPAN distribution and that
you don't care about packages found in older versions which have been deleted
by the author/maintainer (presumably for good reason) from the newest
version.

So when you traverse a minicpan to compose a list of distributions, you
probably want that list I<deduplicated> by stripping out older, presumably
superseded versions of distributions.   This function tries to accomplish
that.  It does I<not> try to be omniscient.  In particular, it does not strip
out distributions with letters in their versions.  So, faced with a situation
like this:

    minicpan/authors/id/D/DR/DROLSKY/Class-MOP-0.82.tar.gz
    minicpan/authors/id/D/DR/DROLSKY/Class-MOP-0.88.tar.gz
    minicpan/authors/id/D/DR/DROLSKY/Class-MOP-0.98.tar.gz
    minicpan/authors/id/D/DR/DROLSKY/Class-MOP-0.98b.tar.gz

... it will dedupe this listing to:

    minicpan/authors/id/D/DR/DROLSKY/Class-MOP-0.98.tar.gz
    minicpan/authors/id/D/DR/DROLSKY/Class-MOP-0.98b.tar.gz

=item * Arguments

    $newlist_ref = dedupe_superseded(\@list);

One argument:  Reference to an array holding a list of distributions needing
to be duplicated.

=item * Return Value

Reference to an array holding a deduplicated list.

=back


=head2 C<get_lookup_table()>

=over 4

=item * Purpose

Convert a list of distributions into a hash keyed on the stem of the
distribution name and having values which are corresponding version numbers.

=item * Arguments

    my $primary = get_lookup_table( $self->get_list_ref() );

Array reference.

=item * Return Value

Reference to hash holding lookup table.  Elements in that hash will resemble:

    '/home/user/minicpan/author/id/Alpha-Beta' => {
        version     => '0.01',
        distro      => '/home/user/minicpan/author/id/Alpha-Beta.tar.gz',
    },

=back


=head2 C<normalize_version_number()>

=over 4

=item * Purpose

Yet another attempt to deal with version number madness.  No attempt to claim
that this is the absolutely correct way to create comparable version numbers.

=item * Arguments

    $new_version = normalize_version_number($old_version),

One argument:  Version number, hopefully in two or more
decimal-point-delimited parts.

=item * Return Value

A version number in which 'minor version', 'patch version', etc., have been
changed to C<0>-padded 5-digit numbers.

=back

=head1 BUGS

Report bugs at
F<https://rt.cpan.org/Public/Bug/Report.html?Queue=CPAN-Mini-Visit-Simple>.

=head1 AUTHOR

    James E Keenan
    CPAN ID: jkeenan
    Perl Seminar NY
    jkeenan@cpan.org
    http://thenceforward.net/perl/modules/CPAN-Mini-Visit-Simple/

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

CPAN-Mini.  CPAN-Mini-Visit-Simple.

=cut

