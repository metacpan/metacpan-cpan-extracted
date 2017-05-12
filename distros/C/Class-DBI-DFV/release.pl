#!/usr/bin/perl
#
# Nabbed from Catalyst:
#   http://dev.catalyst.perl.org/file/trunk/release.pl?rev=1984&format=txt

use IO::Handle;
use YAML;

my $REPO = 'http://svn.ecclestoad.co.uk/svn';
my $SVN  = -d '.svn' ? 'svn' : 'svk';

print "\n";
unless ( -e 'Build.PL' ) {
    print "Error: must be run from a module directory\n\n";
    exit 1;
}

check_commit();
make_dist();

my $meta    = YAML::LoadFile('META.yml');
my $name    = $meta->{name};
my $version = $meta->{version};

cpan_upload();
make_tag();

sub check_commit {
    print "Checking for uncommitted files... ";
    STDOUT->flush;

    my @files = grep { !/^\?/ } split( "\n", `$SVN st` );
    if (@files) {
        print "\n\n", join( "\n", @files ),
          "\n\nPlease commit them before releasing.\n\n";
        exit 1;
    }
    else {
        print "none found.\n";
    }
}

sub make_dist {
    do_cmd("perl Build.PL");
    do_cmd("rm -f MANIFEST");
    do_cmd("perl Build manifest");
    do_cmd("perl Build disttest");
    do_cmd("perl Build dist");
}

sub cpan_upload {
    my $distfile = "$name-$version.tar.gz";

    print "\nDo you wish to upload $distfile to CPAN with cpan-upload? (y/n) ";
    my $answer = <STDIN>;
    do_cmd("cpan-upload $distfile") if $answer =~ /^y/;
}

sub make_tag {
    my $trunk = "$REPO/" . lc $name . "/trunk";
    my $tag   = "$REPO/" . lc $name . "/tags";

    print
qq(\nDo you wish to create a tag with "svn copy $trunk $tag/$version"? (y/n) );
    my $answer = <STDIN>;
    if ( $answer =~ /^y/ ) {
        print "Checking if $tag exists... ";
        STDOUT->flush;
        if ( system "svn list $tag >/dev/null 2>&1" ) {
            print "not found, creating.\n";
            do_cmd("svn mkdir $tag -m '- created tag directory for $name'");
        }
        else {
            print "found.\n";
        }

        do_cmd("svn copy $trunk $tag/$version -m '- tagged $name-$version'");
    }
}

sub do_cmd {
    my $cmd = shift;
    print "\n>>> $cmd\n";
    system($cmd) and exit 1;
}
