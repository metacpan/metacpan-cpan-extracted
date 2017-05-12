package BackPAN::Index::Create;
$BackPAN::Index::Create::VERSION = '0.13';
use 5.006;
use strict;
use warnings;
use Exporter::Lite;
use Path::Iterator::Rule;
use Scalar::Util            qw/ reftype /;
use Module::Loader;
use Carp;
use autodie;

our @EXPORT_OK       = qw(create_backpan_index);
my $FORMAT_REVISION  = 1;
my $DEFAULT_ORDER    = 'dist';
my $PLUGIN_NAMESPACE = 'BackPAN::Index::Create::OrderBy';
my $COMMA            = q{,};

sub create_backpan_index
{
    if (@_ != 1 || reftype($_[0]) ne 'HASH') {
        croak "create_backpan_index() expects a single hashref argument\n";
    }
    my $argref           = shift;
    my $basedir          = $argref->{basedir}
                           || croak "create_backpan_index() must be given a 'basedir'\n";
    my $order            = defined($argref->{order})
                           ? $argref->{order}
                           : $DEFAULT_ORDER;
    my $author_dir       = "$basedir/authors";
    my $stem             = "$author_dir/id";
    my $releases_only    = $argref->{releases_only} || 0;
    my $loader           = Module::Loader->new()
                           || croak "failed to instantiate Module::Loader\n";
    my @plugins          = $loader->find_modules($PLUGIN_NAMESPACE);
    my @plugin_basenames = map { my $p = $_; $p =~ s/^.*:://; $p } @plugins;
    my $fh;


    if (not -d $author_dir) {
        croak "create_backpan_index() can't find 'authors' directory in basedir ($basedir)\n";
    }

    my ($basename) = grep { lc($_) eq lc($order) } @plugin_basenames;
    if (not defined($basename)) {
        croak "order '$order' not known. Supported orders are ",
              join($COMMA, map { "'".lc($_)."'" } @plugin_basenames), "\n";
    }
    my $plugin_class = $PLUGIN_NAMESPACE.'::'.$basename;

    $loader->load($plugin_class);

    if (exists($argref->{output})) {
        open($fh, '>', $argref->{output});
    }
    else {
        $fh = \*STDOUT;
    }

    my $plugin = $plugin_class->new(filehandle => $fh)
                 || croak "failed to create instance of '$order' plugin ($plugin_class)";

    print $fh "#FORMAT $FORMAT_REVISION\n";

    my $rule = Path::Iterator::Rule->new();

    $rule->file->name("*");

    if ($releases_only) {
        # A 'releases only' index contains just the tarballs
        # and the paths don't include the leading 'authors/id'
        # Does a BackPAN ever contain anything in a directory
        # other than authors?
        $rule->and(sub { /\.(tar\.gz|tgz|zip)$/ }) if $releases_only;
        $stem = "$author_dir/id";
    }
    else {
        $stem = $basedir;
    }

    foreach my $path ($rule->all($author_dir)) {
        next if $path =~ /\s+\z/;
        next if $path =~ /\n/;
        my $tail = $path;
           $tail =~ s!^\Q${stem}\E[^A-Za-z0-9]+!!;
           $tail =~ s!\\!/!g if $^O eq 'MSWin32';
        my @stat = stat($path);
        my $time = $stat[9];
        my $size = $stat[7];
        # printf $fh "%s %d %d\n", $tail, $time, $size;
        $plugin->add_file($tail, $time, $size);
    }

    $plugin->finish();

    close($fh) if exists($argref->{output});
}

1;

=head1 NAME

BackPAN::Index::Create - generate an index file for a BackPAN mirror

=head1 SYNOPSIS

 use BackPAN::Index::Create qw/ create_backpan_index /;

 create_backpan_index({
      basedir       => '/path/to/backpan'
      releases_only => 0 | 1,
      output        => 'backpan-index.txt',
      order         => 'dist' # or 'author' or 'age'
 });

=head1 DESCRIPTION

B<BackPAN::Index::Create> provides a function C<create_backpan_index()>
that will create a text index file for a BackPAN CPAN mirror.
A BackPAN CPAN mirror is like a regular CPAN mirror, but it has everything
that has ever been released to CPAN.
The canonical BackPAN mirror is L<backpan.perl.org|http://backpan.perl.org>.

By default the generated index will look like this:

 #FORMAT 1
 authors/id/B/BA/BARBIE/Acme-CPANAuthors-British-1.01.meta.txt 1395991503 1832
 authors/id/B/BA/BARBIE/Acme-CPANAuthors-British-1.01.readme.txt 1395991503 1912
 authors/id/B/BA/BARBIE/Acme-CPANAuthors-British-1.01.tar.gz 1395991561 11231

The first line is a comment that identifies the revision number of the index format.
For each file in the BackPAN mirror the index will then contain one line.
Each line contains three items:

=over 4

=item * path

=item * timestamp

=item * size (in bytes)

=back

You can see indexes created using this module on the
L<CPAN Testers BackPAN|http://backpan.cpantesters.org>,
the home page of which also has more information about BackPAN mirrors.

=head1 ARGUMENTS

The supported arguments are all shown in the SYNOPSIS.

=head2 basedir

The path to the top of your BackPAN repository, without a trailing slash.

=head2 releases_only

If the C<releases_only> option is true, then the index will only contain
release tarballs, and the paths won't include the leading C<authors/id/>:

 #FORMAT 1
 B/BA/BARBIE/Acme-CPANAuthors-British-1.01.tar.gz 1395991561 11231

=head2 output

The path to the file where the index should be generated.
If the file already exists, it will be over-written.

=head2 order

Specifies what order the entries should be written to the index in.
Currently supported values are:

=over 4

=item * 'dist'

Entries are sorted first by dist name (as determined by L<CPAN::DistnameInfo>,
and then by age. This means that when processing the file, you'll see
entries dist by dist, and within each dist you'll see them in order they
were released.

=item * 'author'

Entries are sorted first by author, and then by filename.
This will cluster files from the same release.

=item * 'age'

Entries are sorted first by age, and then by filename.
Given that filenames are unique on CPAN, this should give
a deterministic result for a specific BackPAN.

=back

The supported sort orders are defined by plugins in the
C<BackPAN::Index::Create::OrderBy> namespace. 
C<Dist.pm>, C<Author.pm>, and C<Age.pm> are included in the base distribution.
If you have installed additional plugins, they'll be automatically available.

Note: CPAN::DistnameInfo doesn't handle paths for files other than
tarballs, so if you generate a full index, you may not get the results
you expect.

=head1 Note for Windows users

On Windows the generated index will use '/' as the directory separator,
as I I<think> that's the right thing to do.
Please let me know if you think I'm wrong.

=head1 SEE ALSO

L<create-backpan-index> - a script that provides a command-line interface
to this module, included in the same distribution.

L<BackPAN::Index> - an interface to an alternate BackPAN index.

L<CPAN Testers BackPAN|http://backpan.cpantesters.org> -
one of the BackPAN mirrors. It provides four different indexes
that are generated using this module. The script used to generate
these can be found in the C<examples> directory of this distribution.

=head1 REPOSITORY

L<https://github.com/neilbowers/BackPAN-Index-Create>

=head1 AUTHOR

Neil Bowers E<lt>neilb@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Neil Bowers <neilb@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

