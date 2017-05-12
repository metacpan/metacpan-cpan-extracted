package CPAN::DistroBuilder;

use strict;
use Exporter ();

$CPAN::DistroBuilder::VERSION = '0.01';
@CPAN::DistroBuilder::EXPORT  = qw(build);
@CPAN::DistroBuilder::ISA   = qw(Exporter);

use CPAN;
# must load it now, so we can overload some of the config
CPAN::Config->load;

use File::Find qw(finddepth);
use File::Spec::Functions;

# local config
use lib qw(.);
use CPAN::DistroBuilderConfig;

# override CPAN's default configuration
$CPAN::Config->{$_} = $CPAN::DistroBuilderConfig::Config->{$_}
    for keys %{ $CPAN::DistroBuilderConfig::Config };

my $cpan_dir = $CPAN::Config->{cpan_home};
my $src_dir  = $CPAN::Config->{build_dir};

sub build {
    die "usage: $0 release-name release-version [module(s)] [bundle(s)]\n" 
        unless @ARGV > 2;

    my ($release_name, $version, @bundles) = @ARGV;
    my $package = "$release_name-$version.tar.gz";

    # cleanup from previous session
    del_tree($cpan_dir, $src_dir);

    # fetch all the modules
    report("building in $src_dir");
    CPAN::Shell->force('make', @bundles);

    # make sure distros are clean, before adding to MANIFEST
    CPAN::Shell->clean(@bundles);

    # prepare the MANIFEST file
    add_to_MANIFEST($src_dir, $src_dir);

    write_Makefile_PL($src_dir, $release_name, $version);
    add_to_MANIFEST($src_dir,'Makefile.PL');

    system "(cd $src_dir; perl Makefile.PL && make dist)";

    # mv the product into the current dir
    my $from = catfile $src_dir, $package;
    my $to   = catfile $src_dir, '..', $package;
    rename $from, $to or die "couldn't rename: $from => $to $!";
    report("written $to");
}

# deletes the whole tree(s) or just file(s)
sub del_tree {
    for my $file (@_) {
        next unless -e $file;
        finddepth(sub {-d $_ ? rmdir : unlink; }, $file);
    }
}

# expands the dir|file into a list of files (dirs are skipped)
sub expand_tree {
    my @tree = ();
    for my $file (@_) {
        next unless -e $file;
        push(@tree, $file), next if -f $file;
        finddepth(sub {-f $_ && push @tree, 
                           ($File::Find::name =~ m|$file/(.*)|) }, $file);
    }
    return \@tree;
}

sub write_Makefile_PL {
    my ($dir, $release_name, $version) = @_;
    $dir = '.' unless defined $dir;
    my $file = catfile $dir, 'Makefile.PL';
    open my $fh, '>', $file or die "cannot open $file: $!";
    print $fh qq{use ExtUtils::MakeMaker;\n};
    print $fh qq{WriteMakefile(NAME => "$release_name", VERSION => $version);\n};
    close $fh;
}

# first argument is in what dir MANIFEST is to be appended to
# second argument is a file or directory that should be expanded into
# files, which than added to the MANIFEST file
sub add_to_MANIFEST {
    my ($dir, @files) = @_;
    $dir = '.' unless defined $dir;
    my $file = catfile $dir, 'MANIFEST';
    open my $fh, '>>', $file or die "cannot open $file: $!";
    print $fh join "", map {"$_\n"} @{ expand_tree(@files) };
    close $fh;
}

sub dumper {
    require Data::Dumper;
    print STDERR Data::Dumper::Dumper(@_);
}

sub report {
    print STDERR "+++ $_[0]\n";
}

__END__
1;

=head1 NAME

  CPAN::DistroBuilder - Create a distro from a bundle or a number of modules from CPAN

=head1 SYNOPSIS

  % perl -MCPAN::DistroBuilder -webuild ApacheSDK 0.1 Bundle::Apache

  % perl -MCPAN::DistroBuilder -webuild CoolSDK 0.1 MD5 CGI

=head1 DESCRIPTION

This package does a very simple thing. It fetches the source packages
from CPAN, using C<CPAN.pm> and puts them all into a single I<tar.gz>
package ready for distribution. This distribution package later can be
installed in one command and therefore very useful for users who have
to use our software, but know little or no Perl at all and don't know
how to use CPAN shell to fetch and install all the required
packages. Releasing Bundles and properly defining prerequisites in the
CPAN modules is very important, and we go one step further to actually
provide sort of SDK.

This package relies on the locally working C<CPAN.pm>'s shell. If you
didn't configure your C<CPAN.pm>, do it before using this package. If
normally C<CPAN.pm> works for you, this package should work too.

=head1 CAVEATS

Some packages' build is interactive (i.e. user input is
expected). Therefore we use C<CPAN.pm>'s C<inactivity_timeout>
attribute to interrupt the awaiting for user's input after a few
seconds, which works in I<perl Makefile.PL> stage, but not during
I<make>. In the latter case you have to manually satisfy the requested
input or interrupt it. Since here we completely rely on C<CPAN.pm>'s
shell to do the right thing, there is not much we can do. Remember
that we have to run C<perl Makefile.PL> to extract the prerequisites.
You can adjust the value of the C<inactivity_timeout> attribute in
C<CPAN::DistroBuilderConfig>.

Unfortunately some packages define they own interactive methods which
CPAN cannot skip automatically, in this case you have to manually
answer the question.

=head1 USAGE

To package the packages or bundles I<Foo> and I<Bar> into a ready for
distribution package I<FooBar-0.2>, execute:

  % perl -MCPAN::DistroBuilder -webuild FooBar 0.2 Foo Bar

this will create I<FooBar-0.2.tar.gz> in the current directory.

To install the contents of the created distribution package, run:

  % tar -xzvf FooBar-0.2.tar.gz
  % cd FooBar-0.2
  % perl Makefile.PL && make && make test && make install

The last command will go through all the source packages and run:

  % perl Makefile.PL && make && make test && make install

in every one. You may need to do the C<make install> part as a root
user if the files need to be installed system-wide.

When the packages are fetches from CPAN they are saved in the
I<distro-build> directory (or a different one if you override the
C<build_dir> attribute in C<CPAN::DistroBuilderConfig>) created at the
current directory. This directory is cleaned up automatically on the
next invocation of the this tool, if invoked from the same directory.

Notice that the build process is logged to the I<make.out> file in the
current directory.

As a side-effect of using C<CPAN.pm> is that it creates the I<.cpan>
directory in the current directory where it downloads the index files
and the modules source packages.

=head1 AUTHORS

Stas Bekman <stas@stason.org>

Inspired by Doug MacEachern <dougm@apache.org>


=head1 COPYRIGHT

The C<CPAN::DistroBuilder> module is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.


=cut

