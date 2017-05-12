package CPAN::Releases::Latest;
$CPAN::Releases::Latest::VERSION = '0.08';
use 5.006;
use Moo;
use File::HomeDir;
use File::Spec::Functions 'catfile';
use MetaCPAN::Client 1.001001;
use Module::Runtime qw/ is_module_name require_module /;
use CPAN::DistnameInfo;
use Carp;
use autodie;

my $FORMAT_REVISION = 1;

has 'max_age'           => (is => 'ro', default => sub { '1 day' });
has 'cache_path'        => (is => 'rw');
has 'basename'          => (is => 'ro', default => sub { 'latest-releases.txt' });
has 'path'              => (is => 'ro');
has 'source'            => (is => 'ro', default => sub { 'MetaCPAN' });

has '_indexer'          => (is => 'lazy');

sub BUILD
{
    my $self = shift;

    if ($self->path) {
        if (-f $self->path) {
            return;
        }
        else {
            croak "the file you specified with 'path' doesn't exist";
        }
    }

    if (not $self->cache_path) {
        my $classid = __PACKAGE__;
           $classid =~ s/::/-/g;

        $self->cache_path(
            catfile(File::HomeDir->my_dist_data($classid, { create => 1 }),
                    $self->basename)
        );
    }

    if (-f $self->cache_path) {
        require Time::Duration::Parse;
        my $max_age_in_seconds = Time::Duration::Parse::parse_duration(
                                     $self->max_age
                                 );
        return unless time() - $max_age_in_seconds
                      > (stat($self->cache_path))[9];
    }

    $self->_build_cached_index();
}

sub _build_cached_index
{
    my $self     = shift;
    my $indexer  = $self->_indexer;
    my $distdata = $indexer->get_release_info();

    $self->_write_cache_file($distdata);
}

sub _build__indexer
{
    my $self             = shift;
    my $base_module_name = $self->source;

    if (not is_module_name($base_module_name)) {
        croak "source '$base_module_name' is not a valid module name";
    }

    my $full_class_name  = "CPAN::Releases::Latest::Source::$base_module_name";
    require_module($full_class_name);

    return $full_class_name->new();
}

sub _write_cache_file
{
    my $self     = shift;
    my $distdata = shift;
    my %seen;

    $seen{$_} = 1 for keys(%{ $distdata->{released} });
    $seen{$_} = 1 for keys(%{ $distdata->{developer} });

    open(my $fh, '>', $self->cache_path);
    print $fh "#FORMAT: $FORMAT_REVISION\n";
    foreach my $distname (sort { lc($a) cmp lc($b) } keys %seen) {
        my ($stable_release, $developer_release);

        if (defined($stable_release = $distdata->{released}->{$distname})) {
            printf $fh "%s %s %d %d\n",
                       $distname,
                       $stable_release->{path},
                       $stable_release->{time},
                       $stable_release->{size};
        }

        if (   defined($developer_release = $distdata->{developer}->{$distname})
            && (   !defined($stable_release)
                || $developer_release->{time} > $stable_release->{time}
               )
           )
        {
            printf $fh "%s %s %d %d\n",
                       $distname,
                       $developer_release->{path},
                       $developer_release->{time},
                       $developer_release->{size};
        }

    }
    close($fh);
}

sub release_iterator
{
    my $self = shift;

    require CPAN::Releases::Latest::ReleaseIterator;
    return CPAN::Releases::Latest::ReleaseIterator->new( latest => $self, @_ );
}

sub distribution_iterator
{
    my $self = shift;

    require CPAN::Releases::Latest::DistributionIterator;
    return CPAN::Releases::Latest::DistributionIterator->new(
                latest => $self,
                @_
           );
}

sub _open_file
{
    my $self       = shift;
    my $options    = @_ > 0 ? shift : {};
    my $filename   = $self->cache_path;
    my $whatfile   = 'cached';
    my $from_cache = 1;
    my $fh;

    if (defined($self->path)) {
        $filename   = $self->path;
        $from_cache = 0;
        $whatfile   = 'passed';
    }

    open($fh, '<', $filename);
    my $line = <$fh>;
    if ($line !~ m!^#FORMAT: (\d+)$!) {
        croak "unexpected format of first line - should give format";
    }
    my $file_revision = $1;

    if ($file_revision > $FORMAT_REVISION) {
        croak "the $whatfile file has a later format revision ($file_revision) ",
              "than this version of ", __PACKAGE__,
              " supports ($FORMAT_REVISION). Maybe it's time to upgrade?\n";
    }

    if ($file_revision < $FORMAT_REVISION) {
        if ($whatfile eq 'passed') {
            croak "the passed file $filename is from an older version of ",
                  __PACKAGE__, "\n";
        }

        # The locally cached version was written by an older version of
        # this module, but is still within the max_age constraint, which
        # is how we ended up here. We rebuild the cached index and call
        # this method again. But if we're here because we were trying to
        # rebuild the index, then bomb out, because This Should Never Happen[TM].
        if ($options->{rebuilding}) {
            croak "failed to rebuild the cached index with the expected version\n";
        }
        $self->_build_cached_index();
        return $self->_open_file({ rebuilding => 1});
    }

    return $fh;
}

1;

=head1 NAME

CPAN::Releases::Latest - find latest release(s) of all dists on CPAN, including dev releases

=head1 SYNOPSIS

 use CPAN::Releases::Latest;
 
 my $latest   = CPAN::Releases::Latest->new(max_age => '1 day');
 my $iterator = $latest->release_iterator();
 
 while (my $release = $iterator->next_release) {
     printf "%s path=%s  time=%d  size=%d\n",
            $release->distname,
            $release->path,
            $release->timestamp,
            $release->size;
 }

=head1 DESCRIPTION

This module constructs a list of all dists on CPAN, by default using the MetaCPAN API.
The generated index is cached locally.
It will let you iterate over the index, either release by release,
or distribution by distribution.

See below for details of the two iterators you can instantiate.

B<Note:> this is very much an alpha release; all things may change.

When you instantiate this class, you can specify the C<max_age> of
the generated index. You can specify the age
using any of the expressions supported by L<Time::Duration::Parse>:

 5 minutes
 1 hour and 30 minutes
 2d
 3600

If no units are given, it will be interpreted as a number of seconds.
The default for max age is 1 day.

If you already have a cached copy of the index, and it is less than
the specified age, then we'll use your cached copy and not even
check with MetaCPAN.

=head2 distribution_iterator

The C<distribution_iterator> method returns an iterator which
will process the index dist by dist:

 my $latest   = CPAN::Releases::Latest->new();
 my $iterator = $latest->distribution_iterator();

 while (my $dist = $iterator->next_distribution) {
    print $dist->distname, "\n";
    process_release($dist->release);
    process_release($dist->developer_release);
 }

The iterator returns instances of L<CPAN::Releases::Latest::Distribution>,
or C<undef> when the index has been exhausted.
The distribution object has three attributes:

=over 4

=item * distname: the distribution name as determined by L<CPAN::DistnameInfo>

=item * release: a release object for the latest non-developer release, or C<undef>

=item * developer_release: a release object for the latest developer release that is more recent than the latest non-developer release, or C<undef>

=back

The release objects are instances of L<CPAN::Releases::Latest::Release>,
which are described in the next section, below.

=head2 release_iterator

The C<release_iterator> method returns an iterator which will process the index
release by release. See the example in the SYNOPSIS.

You will see the releases ordered distribution by distribution.
For a given distribution you'll first see the latest non-developer release,
if there is one;
if the most recent release for the distribution is a developer release,
then you'll see that.
So for any dist you'll see at most two releases, and the developer release
will always come second.

The release objects are instances of L<CPAN::Releases::Latest::Release>,
which have the following attributes:

=over 4

=item * distname: the distribution name as determined by L<CPAN::DistnameInfo>

=item * path: the partial path for the release tarball (eg C<N/NE/NEILB/enum-1.05.tar.gz>)

=item * timestamp: an epoch-based timestamp for when the tarball was uploaded to PAUSE.

=item * size: the size of the release tarball, in bytes.

=item * distinfo: an instance of L<CPAN::DistnameInfo>, which is constructed lazily.

=back

=head1 Data source

By default the locally cached index is generated using information requested
from MetaCPAN, using L<MetaCPAN::Client>. The plugin which does this is
L<CPAN::Releases::Latest::Source::MetaCPAN>. You can explicitly specify
the source when calling the constructor:

 $latest = CPAN::Releases::Latest->new( source => 'MetaCPAN' );

You can use a different source for the data, by providing your own plugin,
which must live in the C<CPAN::Releases::Latest::Source> namespace.

The plugin must return a hashref that has the following structure:

 {
   release => {

     'Graph' => {
        path => 'J/JH/JHI/Graph-0.96.tar.gz',
        time => 1369483123,
        size => 147629,
     },

   },

   developer => {

     'Graph' => {
        path => 'N/NE/NEILB/Graph-0.96_01.tar.gz',
        time => 1394362358,
        size => 147335,
     },

   }

 }

At the moment this isn't enforced, but a future version will croak
if the source doesn't return the right structure.

=head1 SEE ALSO

L<CPAN::ReleaseHistory> provides a similar iterator, but for all releases
ever made to CPAN, even those that are no longer on CPAN.

L<BackPAN::Index> is another way to get information about all releases
ever made to CPAN.

=head1 REPOSITORY

L<https://github.com/neilb/CPAN-Releases-Latest>

=head1 AUTHOR

Neil Bowers E<lt>neilb@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Neil Bowers <neilb@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

