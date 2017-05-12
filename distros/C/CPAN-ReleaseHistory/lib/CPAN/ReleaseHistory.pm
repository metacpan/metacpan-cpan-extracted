package CPAN::ReleaseHistory;
$CPAN::ReleaseHistory::VERSION = '0.15';
use 5.006;
use Moo;
use MooX::Role::CachedURL 0.06;

use CPAN::DistnameInfo;
use Carp;
use autodie qw(open);

use CPAN::ReleaseHistory::Release;

with 'MooX::Role::CachedURL';

has '+url' =>
    (
     default => sub { return 'http://backpan.cpantesters.org/backpan-releases-by-dist-index.txt.gz' },
    );

has '+max_age' =>
    (
     default => sub { '1 day' },
    );


sub release_iterator
{
    my $self = shift;

    require CPAN::ReleaseHistory::ReleaseIterator;
    return CPAN::ReleaseHistory::ReleaseIterator->new( history => $self, @_ );
}

1;

=head1 NAME

CPAN::ReleaseHistory - information about all files ever released to CPAN

=head1 SYNOPSIS

  use CPAN::ReleaseHistory 0.10;

  my $history  = CPAN::ReleaseHistory->new();
  my $iterator = $history->release_iterator();

  while (my $release = $iterator->next_release) {
    print 'path = ', $release->path,           "\n";
    print 'dist = ', $release->distinfo->dist, "\n";
    print 'time = ', $release->timestamp,      "\n";
    print 'size = ', $release->size,           "\n";
  }
  
=head1 DESCRIPTION

This module provides an iterator that can be used to look at every file
that has ever been released to CPAN, regardless of whether it is still on CPAN.

The BackPAN index used was changed in release 0.10, which resulted in the caching
mechanism changing, so you should make sure you have at least version 0.10,
as shown in the SYNOPSIS above.

The C<$release> returned by the C<next_release()> method on the iterator
is an instance of L<CPAN::ReleaseHistory::Release>. It has five methods:

=over 4

=item path

the relative path of the release. For example C<N/NE/NEILB/again-0.05.tar.gz>.

=item distinfo

an instance of L<CPAN::DistnameInfo>, which is constructed lazily.
Ie it is only created if you ask for it.

=item timestamp

An integer epoch-based timestamp.

=item date

An ISO-format date string (YYYY-MM-DD) for the timestamp in UTC
(ie the date used by PAUSE and CPAN, rather than the time of release
in your local timezone.

=item size

The number of bytes in the file.

=back

=head2 Be aware

When iterating over CPAN's history, you'll find that most distribution names reveal
a clean release history. For example, JUERD did two releases of L<again>,
which I then adopted:

 J/JU/JUERD/again-0.01.tar.gz
 J/JU/JUERD/again-0.02.tar.gz
 N/NE/NEILB/again-0.03.tar.gz
 N/NE/NEILB/again-0.04.tar.gz
 N/NE/NEILB/again-0.05.tar.gz

But you will also discover that there are various 'anomalies' in the history of CPAN releases.
These are usually well in the past -- PAUSE and the related toolchains have evolved to
prevent most of these.
For example, here's the sequence of releases for distributions called 'enum':

 Z/ZE/ZENIN/enum-1.008.tar.gz
 Z/ZE/ZENIN/enum-1.009.tar.gz
 Z/ZE/ZENIN/enum-1.010.tar.gz
 Z/ZE/ZENIN/enum-1.011.tar.gz
 N/NJ/NJLEON/enum-0.02.tar.gz
 Z/ZE/ZENIN/enum-1.013.tar.gz
 Z/ZE/ZENIN/enum-1.014.tar.gz
 Z/ZE/ZENIN/enum-1.015.tar.gz
 Z/ZE/ZENIN/enum-1.016.tar.gz
 R/RO/ROODE/enum-0.01.tar.gz
 N/NE/NEILB/enum-1.016_01.tar.gz
 N/NE/NEILB/enum-1.02.tar.gz
 N/NE/NEILB/enum-1.03.tar.gz
 N/NE/NEILB/enum-1.04.tar.gz
 N/NE/NEILB/enum-1.05.tar.gz
 N/NE/NEILB/enum-1.06.tar.gz

The L<enum> module was first released by ZENIN, and I (NEILB) recently adopted it.
But you'll see that there have been two other releases of other modules (with similar aims).

Depending on what you're trying to do, you might occasionally be surprised by the sequence
of version numbers and maintainers.

=head1 METHODS

At the moment there is only one method, to create a release iterator.
Other methods will be added as required / requested.

=head2 release_iterator()

See the SYNOPSIS.

This supports one optional argument, C<well_formed>, which if true says that the
iterator should only return releases where the dist name and author's PAUSE id
could be found:

 my $iterator = CPAN::ReleaseHistory->new()->release_iterator(
                    well_formed => 1
                );

This saves you from having to write code like the following:

 while (my $release = $iterator->next_release) {
    next unless defined($release->distinfo);
    next unless defined($release->distinfo->dist);
    next unless defined($release->distinfo->cpanid);
    ...
 }

=head1 SEE ALSO

L<BackPAN::Index> - creates an SQLite database of the BackPAN index,
and provides an interface for querying it.

L<backpan.cpantesters.org|http://backpan.cpantesters.org> - the BackPAN site
from where this module grabs the index.

=head1 REPOSITORY

L<https://github.com/neilbowers/CPAN-ReleaseHistory>

=head1 AUTHOR

Neil Bowers E<lt>neilb@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Neil Bowers <neilb@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

