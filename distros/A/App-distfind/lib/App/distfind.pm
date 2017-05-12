use 5.008;
use strict;
use warnings;

package App::distfind;
BEGIN {
  $App::distfind::VERSION = '1.101400';
}

# ABSTRACT: Find Perl module distributions within a directory hierarchy
use File::Find;
use Getopt::Long;
use Pod::Usage;

sub run {
    our %opt = (prefix => '', suffix => '', join => ' ');
    GetOptions(
        \%opt, qw(help|h|? man|m
          dir|d=s@ prune=s@ print-roots print-path=s@
          prefix|p=s suffix|s=s join|j=s line)
    ) or pod2usage(2);
    if ($opt{help}) {
        pod2usage(
            -exitstatus => 0,
            -input      => __FILE__,
        );
    }
    if ($opt{man}) {
        pod2usage(
            -exitstatus => 0,
            -input      => __FILE__,
            -verbose    => 2
        );
    }
    $opt{dir} ||= [];
    unless (@{ $opt{dir} }) {
        push @{ $opt{dir} } => $ENV{PROJROOT} if defined $ENV{PROJROOT};
    }
    $opt{dir} = normalize_dirs($opt{dir});
    if ($opt{'print-roots'}) {
        print join $opt{join} => @{ $opt{dir} };
        exit;
    }
    $opt{'print-path'} ||= [];
    my %prune_lookup = map { $_ => 1 } @{ $opt{prune} || [] },
      qw(.svn .git blib skel);
    my @distro =
      map { "$opt{prefix}$_$opt{suffix}" }
      find_dists($opt{dir}, $opt{'print-path'}, \%prune_lookup);
    if ($opt{line}) {
        print "$_\n" for @distro;
    } else {
        print join $opt{join} => @distro;
    }
}

sub normalize_dirs {
    my $dirs = shift;
    my %seen;
    [   grep { !$seen{$_}++ }
        map { s/^~/$ENV{HOME}/; $_ }
        map { split /\s*[:;]\s*/ } @$dirs
    ];
}

sub find_dists {
    my ($dirs, $restrict_paths, $prune_lookup) = @_;
    if (defined $restrict_paths) {
        $restrict_paths = [$restrict_paths]
          unless ref $restrict_paths eq 'ARRAY';
    } else {
        $restrict_paths = [];
    }
    my %restrict_paths = map { $_ => 1 } @$restrict_paths;    # lookup hash
    my @distro;
    find(
        sub {
            return unless -d;
            if ($prune_lookup->{$_}) {
                $File::Find::prune = 1;
                return;
            }
            if (-e "$_/Build.PL" || -e "$_/Makefile.PL" || -e "$_/dist.ini") {

              # only remember the distro if there was no path restriction, or if
              # it is within the restrict_path specs
                if (@$restrict_paths == 0 || exists $restrict_paths{$_}) {
                    push @distro => $File::Find::name;
                }

               # but prune anyway - we assume there are no distributions below a
               # directory that contains a Build.PL or a Makefile.PL.
                $File::Find::prune = 1;
            }
        },
        @$dirs
    );
    wantarray ? @distro : \@distro;
}
1;


__END__
=pod

=for stopwords dirs

=for test_synopsis 1;
__END__

=head1 NAME

App::distfind - Find Perl module distributions within a directory hierarchy

=head1 VERSION

version 1.101400

=head1 SYNOPSIS

    $ distfind
    path/to/My-Dist path/to/My-Other-Dist

    $ distfind --dir foo --dir bar --prune deprecated --line
    foo/some/path/My-Dist
    foo/some/other/path/My-Other-Dist
    bar/yet/another/path/My-Shiny

    $ distfind --dir baz --print-roots
    baz

    $ distfind --print-path Foo-Bar --prefix "ls -al "
    ls -al path/to/Foo-Bar

To be able to run programs from within your development directories without
having to install the distributions, add this to your C<.bashrc>:

    for i in $(distfind)
    do
        if [ -d $i/bin ]; then
            PATH=$i/bin:$PATH
        fi
    done

=head1 DESCRIPTION

C<distfind> can find Perl module distributions in a directory hierarchy. A
Perl distribution in this sense is defined as a directory that contains a
C<Makefile.PL>, C<Build.PL> or C<dist.ini> file.

=head1 FUNCTIONS

=head2 run

The main function, which is called by the C<distfind> program.

=head2 normalize_dirs

This function takes a reference to an array of directory specifications. It
then normalizes them by splitting them along colon or semicolon characters and
filters out duplicates. Tilde characters will be expanded to C<$ENV{HOME}>.
The returning list is returned as an array reference.

=head2 find_dists

Traverses the given directories, looks for Perl module distributions, and
returns a list of paths to those distribution directories. See C<--prune> for
directories that will be pruned. Also if a Perl module distribution directory
is found, it is then pruned because we assume that it won't recursively
contain another Perl module distribution.

=head1 OPTIONS

Options can be shortened according to L<Getopt::Long/"Case and
abbreviations">.

=over

=item C<--dir>

This option takes a string argument and can be given several times. Specifies
a directory that should be searched for Perl module distributions. If no
directories are specified, the value of C<$ENV{PROJROOT}> is added by default.

=item C<--prune>

This option takes a string argument and can be given several times. If a
directory with this name is encountered, it will be pruned.

By default, the following directories are pruned: C<.svn>, C<.git>, C<blib>
and C<skel>.

=item C<--print-roots>

This option causes the directories that would be searched to be printed,
without actually searching them. The C<--join> option is used, if given.
See C<--dir> on how this could be different from the options you gave at
the command-line.

=item C<--print-path>

This option takes a string argument and can be given several times. It has the
effect of restricting what will be printed to the given distribution names.
For example:

    $ distfind --print-path Foo-Bar --print-path Baz

will only print paths to those distributions:

    path/to/Foo-Bar path/to/Baz

=item C<--prefix>

This option takes a string argument. If given, every distribution path will be
prefixed with this string as it is printed.

=item C<--suffix>

This option takes a string argument. If given, every distribution path will be
suffixed with this string as it is printed.

=item C<--join>

This option takes a string argument. When printing distribution paths, they
will be separated by this string. It defaults to a single space character.

=item C<--line>

Print each distribution path on a line of its own. It overrides the C<--join>
option.

=item C<--help>

Prints a brief help message and exits.

=item C<--man>

Prints the manual page and exits.

=back

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org/Public/Dist/Display.html?Name=App-distfind>.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see
L<http://search.cpan.org/dist/App-distfind/>.

The development version lives at
L<http://github.com/hanekomu/App-distfind/>.
Instead of sending patches, please fork this project using the standard git
and github infrastructure.

=head1 AUTHOR

  Marcel Gruenauer <marcel@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

