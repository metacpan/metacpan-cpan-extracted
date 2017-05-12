package CPAN::Cover::Results;
$CPAN::Cover::Results::VERSION = '0.03';
use CPAN::Cover::Results::ReleaseIterator;

use 5.006;
use Moo;
with 'MooX::Role::CachedURL'
    # => { -version => 0.03 }
    ;

has '+url' =>
    (
        default => sub { 'http://cpancover.com/latest/cpancover.json.gz' },
    );

sub release_iterator
{
    my $self = shift;

    return CPAN::Cover::Results::ReleaseIterator->new( results => $self );
}

1;

=head1 NAME

CPAN::Cover::Results - get CPAN coverage test results from CPAN Cover service

=head1 SYNOPSIS

 use CPAN::Cover::Results;

 my $iterator = CPAN::Cover::Results->new()->release_iterator();

 while (my $release = $iterator->next) {
     printf "%s (%s) : %.2f\n",
            $release->distname,
            $release->version,
            $release->total;
 }

=head1 DESCRIPTION

This module will get the coverage test results from the
L<CPAN Cover|http://cpancover.com>
service and let you iterate over them, distribution by distribution.
CPAN Cover is a service that runs L<Devel::Cover>
on as much of CPAN as possible,
and makes the results available.

The release iterator returns instances of L<CPAN::Cover::Results::Release>,
which has the following attributes:

=over 4

=item * distname - the name of the distribution, as determined
by L<CPAN::DistnameInfo>.

=item * version - the version number of the release.

=item * branch - the branch coverage of the release's testsuite,
or C<undef>.

=item * condition - the condition coverage figure, or C<undef>.

=item * pod - the pod coverage, if available, or C<undef>.

=item * statement - the statement coverage, or C<undef>.

=item * subroutine - the subroutine coverage, or C<undef>.

=item * total - the total coverage.

=back

See the L<Devel::Cover> documentation for more information on the
different coverage figures.

=head1 SEE ALSO

L<Devel::Cover> - the module used to generate test coverage statistics.

L<cpancover.com|http://cpancover.com> - the coverage testing service that
generates the results accessed via this module.

L<Practical code coverage|http://pjcj.net/presentations/spw-2013-practical-code-coverage/slides/> - slides from a talk by Paul Johnson, the author
of Devel::Cover and cpancover.

L<CPAN::Cover::Results::Release> - the release iterator returns instances
of this class.

=head1 REPOSITORY

L<https://github.com/neilbowers/CPAN-Cover-Results>

=head1 AUTHOR

Neil Bowers E<lt>neilb@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Neil Bowers <neilb@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
