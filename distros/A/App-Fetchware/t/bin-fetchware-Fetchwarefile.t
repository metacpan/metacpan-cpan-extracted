#!perl
# bin-fetchware-Fetchwarefile.t tests bin/fetchware by trying to install a
# number of real world example Fetchwarefiles.
use strict;
use warnings;
use 5.010001;

# Set a umask of 022 just like bin/fetchware does. Not all fetchware tests load
# bin/fetchware, and so all fetchware tests must set a umask of 0022 to ensure
# that any files fetchware creates during testing pass fetchware's safe_open()
# security checks.
umask 0022;

use App::Fetchware::Util 'run_prog';
use Test::Fetchware 'skip_all_unless_release_testing';
use File::Temp 'tempfile';
use Cwd 'cwd';


# Test::More version 0.98 is needed for proper subtest support.
use Test::More 0.98 tests => '6'; #Update if this changes.

# Set PATH to a known good value.
$ENV{PATH} = '/usr/local/bin:/usr/bin:/bin';
# Delete *bad* elements from environment to make it safer as recommended by
# perlsec.
delete @ENV{qw(IFS CDPATH ENV BASH_ENV)};

# This test file requires root access and the special FETCHWARE_INSANE_TESTING
# environment variable to be set in order to run, because I only want to run
# these tests when I specifically ask for them to be run.
# The SKIP block is needed, because skip() can not be called a second time.
SKIP: {
    # First be sure release testing is also set.
    # But I can't actually just call skip_all_unless_release_testing() to do
    # this, because it calls Test::More's plan(), but plan() apparently can only
    # be called once, so I have to check the same stuff that
    # skip_all_unless_release_testing() tests for here as well :(
    # Then, check for FETCHWARE_INSANE_TESTING, and skip all if its not set.
    if (not exists $ENV{FETCHWARE_INSANE_TESTING}
        or not defined $ENV{FETCHWARE_INSANE_TESTING}
        or $ENV{FETCHWARE_INSANE_TESTING} ne 'On'
        # And we're *not* running as root, which is needed for each Fetchware file's
        # make install.
        and ($< != 0 and $> != 0)) {
        my $how_many = 6;
        skip 'Skipping insane lengthy Fetchwarefile tests.', $how_many;
    }


subtest 'test Apache Fetchwarefile success' => sub {

    my $apache_fetchwarefile = <<'EOF';
use App::Fetchware;

program 'Apache';
lookup_url 'http://www.apache.org/dist/httpd/';
filter 'httpd-2.2';
mirror 'http://mirrors.ibiblio.org/apache/httpd/';
mirror 'ftp://apache.cs.utah.edu/apache.org/httpd/';

verify_method 'gpg';
gpg_keys_url 'http://www.apache.org/dist/httpd/KEYS';

make_options '-j 4';
prefix '/home/dly/software/apache2.2';
# You can use heredocs to make gigantic options like this one more legible.
configure_options <<EOO;
--with-mpm=prefork
--enable-modules="access alias auth autoindex cgi logio log_config status vhost_alias userdir rewrite ssl"
--enable-so
EOO
EOF

    # Create a tempfile to store the Fetchwarefile in.
    my ($fh, $filename) = tempfile("fetchware-test-$$-XXXXXXXXXXX", TMPDIR => 1,
        UNLINK => 1);
    # Write the $apache_fetchwarefile to disk, so bin/fetchware can access it.
    print $fh $apache_fetchwarefile;
    close $fh; # Close $fh to ensure its contents make it out to disk.

    # Just execute bin/fetchware install with the newly created
    # apache.Fetchwarefile to test it.
    ok(run_prog(qw!perl -I lib bin/fetchware install!, $filename),
        'Checked Apache Fetchwarefile success.');
};


subtest 'test Nginx Fetchwarefile success' => sub {

    my $nginx_fetchwarefile = <<'EOF';
use App::Fetchware;

program 'nginx';

# lookup_url and mirror are the same thing, because nginx does not seem to have
# mirrors. Fetchware, however, requires one, so the same URL is simply
# duplicated.
lookup_url 'http://nginx.org/download/';
mirror 'http://nginx.org/download/';


# Must add the developers public keys to my own keyring. These keys are
# availabe from http://nginx.org/en/pgp_keys.html Do this with:
# gpg \
# --fetch-keys http://nginx.org/keys/aalexeev.key\
# --fetch-keys http://nginx.org/keys/is.key\
# --fetch-keys http://nginx.org/keys/mdounin.key\
# --fetch-keys http://nginx.org/keys/maxim.key\
# --fetch-keys http://nginx.org/keys/sb.key\
# --fetch-keys http://nginx.org/keys/glebius.key\
# --fetch-keys http://nginx.org/keys/nginx_signing.key
# You might think you could just set gpg_keys_url to the nginx-signing.key key,
# but that won't work, because like apache different releases are signed by
# different people. Perhaps I could change gpg_keys_url to be like mirror where
# you can specify more than one option?
user_keyring 'On';
# user_keyring specifies to use the user's own keyring instead of fetchware's.
# But fetchware drops privileges by default using he user 'nobody.' nobody is
# nobody, so that user account does not have a home directory for gpg to read a
# keyring from. Therefore, I'm using my own account instead.
user 'dly';
# The other option, which is commented out below, is to use root's own keyring,
# and the no_install option to ensure that root uses its own keyring instead of
# nobody's.
# noinstall 'On';
verify_method 'gpg';
EOF

    # Create a tempfile to store the Fetchwarefile in.
    my ($fh, $filename) = tempfile("fetchware-test-$$-XXXXXXXXXXX", TMPDIR => 1,
        UNLINK => 1);
    # Write the $apache_fetchwarefile to disk, so bin/fetchware can access it.
    print $fh $nginx_fetchwarefile;
    close $fh; # Close $fh to ensure its contents make it out to disk.

    # Just execute bin/fetchware install with the newly created
    # apache.Fetchwarefile to test it.
    ok(run_prog(qw!perl -I lib bin/fetchware install!, $filename),
        'Checked Nginx Fetchwarefile success.');
};



subtest 'test PHP Fetchwarefile success' => sub {

    my $php_fetchwarefile = <<'EOF';
use App::Fetchware qw(
    :OVERRIDE_LOOKUP
    :OVERRIDE_DOWNLOAD
    :OVERRIDE_VERIFY
    :DEFAULT
);
use App::Fetchware::Util ':UTIL';
use HTML::TreeBuilder;
use URI::Split qw(uri_split uri_join);
use Data::Dumper;
use HTTP::Tiny;

program 'php';

lookup_url 'http://us1.php.net/downloads.php';
mirror 'http://us1.php.net';
mirror 'http://us2.php.net';
mirror 'http://www.php.net';

# php does *not* use a standard http or ftp mirrors for downloads. Instead, it
# uses its Web site, and some sort of application to download files using URLs
# such as: http://us1.php.net/get/php-5.5.3.tar.bz2/from/this/mirror
#
# Bizarrely a URL like
# http://us1.php.net/get/php-5.5.3.tar.bz2/from/us2.php.net/mirror
# gets you the same page, but on a different mirror. Weirdly, these are direct
# downloads without any HTTP redirects using 300 codes, but direct downloads.
# 
# This is why using fetchware with php you needs a custom lookup handler.
# The files you download are resolved to a [http://us1.php.net/distributions/...]
# directory, but trying to access a apache styple auto index at that url fails
# with a rediret back to downloads.php.
my $md5sum;
hook lookup => sub {
    die <<EOD unless config('lookup_url') =~ m!^http://!;
php.Fetchwarefile: Only http:// lookup_url's and mirrors are supported. Please
only specify a http lookup_url or mirror.
EOD

    msg "Downloading lookup_url [@{[config('lookup_url')]}].";
    my $dir_list = download_dirlist(config('lookup_url'));

    vmsg "Parsing HTML page listing php releases.";
    my $tree = HTML::TreeBuilder->new_from_content($dir_list);

    # This parsing code assumes that the latest version of php is the first one
    # we find, which seems like a dependency that's unlikely to change.
    my $download_path;
    $tree->look_down(
        _tag => 'a',
        sub {
            my $h = shift;
            
            my $link = $h->as_text();

            # Is the link a php download link or something to ignore.
            if ($link =~ /tar\.(gz|bz2|xz)|(tgz|tbz2|txz)/) {

                # Set $download_path to this tags href, which should be
                # something like: /get/php-5.5.3.tar.bz2/from/a/mirror
                if (exists $h->{href} and defined $h->{href}) {
                    $download_path = $h->{href};
                } else {
                    die <<EOD;
php.Fetchwarefile: A path should be found in this link [$link], but there is no
path it in. No href [$h->{href}].
EOD
                }

                # Find and save the $md5sum for the verify hook below.
                # It should be 3 elements over, so it should be the third index
                # in the @right array below (remember to start counting 2 0.).
                my @right = $h->right();
# Left for the next time the page annoyingly, arbitrarily changes :)
#local $Data::Dumper::Maxdepth = 3; # Only show 3 "levels" of crap.
#use Test::More;
#diag("RIGHT[");
#for my $i (0..$#right) {
#    diag("TAG#[$i]");
#    diag explain \@right;
#    diag("ENDTAG#[$i]");
#}
#diag("]");
                my $md5_span_tag = $right[5];
                $md5sum = $md5_span_tag->as_text();
                $md5sum =~ s/md5:\s+//; # Ditch md5 header.
            }
        }
    );

    # Delete the $tree, so perl can garbage collect it.
    $tree = $tree->delete;

    # Determine and return a properl $download_path.
    # Switch it from [/from/a/mirror] to [/from/this/mirror], so the mirror will
    # actually return the file to download.
    $download_path =~ s!/a/!/this/!;

    vmsg "Determined download path to be [$download_path]";
    return $download_path;
};


# I also must hook download(), because fetchware presumes that the filename of
# the downloaded file is the last part of the $path, but that is not the case
# with the path php uses for file downloads, because it ends in mirror, which is
# *not* the name of the file; therefore, I must  hook download() to fix this
# problem.
hook download => sub {
    my ($temp_dir, $download_path) = @_;

    my $http = HTTP::Tiny->new();
    my $response;
    for my $mirror (config('mirror')) {
        my ($scheme, $auth, $path, $query, $fragment) = uri_split($mirror);
        my $url = uri_join($scheme, $auth, $download_path, undef, undef);
        msg <<EOM;
Downloading path [$download_path] using mirror [$mirror].
EOM
        $response = $http->get($url);
        
        # Only download it once.
        last if $response->{success};
    }

    die <<EOD unless $response->{success};
php.Fetchwarefile: Failed to download the download path [$download_path] using
the mirrors [@{[config('mirror')]}]. The response was:
[@{[Dumper($response->{headers})]}].
EOD
    die <<EOD unless length $response->{content};
php.Fetchwarefile: Didn't actually download anything. The length of what was
downloaded is zero. status [$response->{status}] reason [$response->{reason}]
HTTP headers [@{[Dumper($response->{headers})]}].
EOD

    msg 'File downloaded successfully.';

    # Determine $filename from $download_path
    my @paths = split('/', $download_path);
    my ($filename) = grep /php/, @paths;

    vmsg "Filename determined to be [$filename]";

    open(my $fh, '>', $filename) or die <<EOD;
php.Fetchwarefile: Failed to open [$filename] for writing. OS error [$!].
EOD

    print $fh $response->{content};
    close $fh or die <<EOD;
php.Fetchwarefile: Huh close($filename) failed! OS error [$!].
EOD

    my $package_path = determine_package_path($temp_dir, $filename);

    vmsg "Package path determined to be [$package_path].";

    return $package_path
};


# The above lookup hook parses out the md5sum on the php downloads.php web
# site, and stores it in $md5sum, which is used in the the verify hook below.
hook verify => sub {
    # Don't need the $download_path, because lookup above did that work for us.
    # $package_path is the actual php file that we need to ensure its md5
    # matches the one lookup determined.
    my ($download_path, $package_path) = @_;

    msg "Verifying [$package_path] using md5.";

    die <<EOD if not defined $md5sum;
php.Fetchwarefile: lookup failed to figure out the md5sum for verify to use to
verify that the php version [$package_path] matches the proper md5sum.
The md5sum was [$md5sum].
EOD

    my $package_fh = safe_open($package_path, <<EOD);
php.Fetchwarefile: Can not open the php package [$package_path]. The OS error
was [$!].
EOD

    # Calculate the downloaded php file's md5sum.
    my $digest = Digest::MD5->new();
    $digest->addfile($package_fh);
    my $calculated_digest = $digest->hexdigest();

    die <<EOD unless $md5sum eq $calculated_digest;
php.Fetchwarefile: MD5sum comparison failed. The calculated md5sum
[$calculated_digest] does not match the one parsed of php.net's Web site
[$md5sum]! Do not trust this downloaded file! Perhaps there's a bug somewhere,
or perhaps the php mirror you downloaded this php package from has been hacked.
Mirrors do get hacked occasionally, so it is very much possible.
EOD

    msg "ms5sums [$md5sum] [$calculated_digest] match.";

    return 'Package Verified';
};
EOF

    # Create a tempfile to store the Fetchwarefile in.
    my ($fh, $filename) = tempfile("fetchware-test-$$-XXXXXXXXXXX", TMPDIR => 1,
        UNLINK => 1);
    # Write the $apache_fetchwarefile to disk, so bin/fetchware can access it.
    print $fh $php_fetchwarefile;
    close $fh; # Close $fh to ensure its contents make it out to disk.

    # Just execute bin/fetchware install with the newly created
    # apache.Fetchwarefile to test it.
    ok(run_prog(qw!perl -I lib bin/fetchware install!, $filename),
        'Checked PHP Fetchwarefile success.');
};



subtest 'test PHP git Fetchwarefile success' => sub {

    my $php_git_fetchwarefile = <<'EOF';
# php-using-git.Fetchwarefile: example fetchwarefile using php's git repo
# for lookup(), download(), and verify() functionality.
use App::Fetchware qw(:DEFAULT :OVERRIDE_LOOKUP);
use App::Fetchware::Util ':UTIL';
use Cwd 'cwd';

# The directory where the php source code's local git repo is.
my $git_repo_dir = '/home/dly/Desktop/Code/php-src';

# By default Fetchware drops privs, and since the source code repo is stored in
# the user dly's home directory, I should drop privs to dly, so that I have
# permission to access it.
user 'dly';

# Turn on verify failure ok, because the current version as of this writing (php
# 5.4.5) is signed by someone who has not shared uploaded their gpg key to a
# keyserver somewhere making git verifgy-tag fail, because I can't find the key.
# Hopefully, php bug# 65840 will result in this being fixed.
verify_failure_ok 'On';

# Determine latest version by using the tags developers create to determine the
# latest version.
hook lookup => sub {
    # chdir to git repo.
    chdir $git_repo_dir or die <<EOD;
php.Fetchwarefile: Failed to chdir to git repo at
[$git_repo_dir].
OS error [$!].
EOD

    # Pull latest changes from php git repo.
    run_prog('git pull');

    # First determine latest version that is *not* a development version.
    # And chomp off their newlines.
    chomp(my @tags = `git tag`);

    # Now sort @tags for only ones that begin with 'php-'.
    @tags = grep /^php-/, @tags;

    # Ditch release canidates (RC, alphas and betas.
    @tags = grep { $_ !~ /(RC\d+|beta\d+|alpha\d+)$/ } @tags;

    # Sort the tags to find the latest one.
    # This is quite brittle, but it works nicely.
    @tags = sort { $b cmp $a } @tags;

    # Return $download_path, which is only just the latest tag, because that's
    # all I need to know to download it using git by checking out the tag.
    my $download_path = $tags[0];

    return $download_path;
};


# Just checkout the latest tag to "download" it.
hook download => sub {
    my ($temp_dir, $download_path) = @_;

    # The latest tag is the download path see lookup.
    my $latest_tag = $download_path;

    # checkout the $latest_tag to download it.
    run_prog('git checkout', "$latest_tag");

    my $package_path = cwd();
    return $package_path;
};


# You must manually add php's developer's gpg keys to your gpg keyring. Do
# this by  going to the page: http://us1.php.net/downloads.php . At the
# bottom the gpg key "names are listed such as "7267B52D" or "5DA04B5D."
# These are their key "names." Use gpg to download them and import them into
# your keyring using: gpg --keyserver pgp.mit.edu --recv-keys [key id]
hook verify => sub {
    my ($download_path, $package_path) = @_;

    # the latest tag is the download path see lookup.
    my $latest_tag = $download_path;

    # Run git verify-tag to verify the latest tag
    my $success = eval { run_prog('git verify-tag', "$latest_tag"); 1;};

    # If the git verify-tag fails, *and* verify_failure_ok has been turned on,
    # then ignore the thrown exception, but print an annoying message.
    unless (defined $success and $success) {
        unless (config('verify_failure_ok')) {
            msg <<EOM;
Verification failure ok, becuase you've configured fetchware to continue even
if it cannot verify its downloads. Please reconsider, because mirror and source
code repos do get hacked. The exception that was caught was:
[$@]
EOM
        }
    }
};


hook unarchive => sub {
    # there is nothing to archive due to use of git.
    do_nothing(); # But return the $build_path, which is the cwd().
    my $build_path = $git_repo_dir;
    return $build_path;
};

# It's a git tag, so it lacks an already generated ./configure, so I must use
# ./buildconf to generate one. But it won't work on php releases, so I have to
# force it with --force to convince ./buildconf to run autoconf to generate the
# ./configure program to configure php for building.
build_commands './buildconf --force', './configure', 'make';

# Add any custom configure options that you may want to add to customize
# your build of php, or control what php extensions get built.
#configure_options '--whatever you --need ok';

# start() creates a tempdir in most cases this is exactly what you want, but
# because this Fetchwarefile is using git instead. I don't need to bother with
# creating a temporary directory.
hook start => sub {
    # But checkout master anyway that way the repo can be in a known good state
    # so lookup()'s git pull can succeed.
    run_prog('git checkout master');
};


# Switch the local php repo back to the master branch to make using it less
# crazy. Furthermore, when using git pull to update the repo git uses what
# branch your on, and if I've checked out a tag, I'm not actually on a branch
# anymore; therefore, I must switch back to master, so that the git pull when
# this fetchwarefile is run again will still work.
hook end => sub {
    run_prog('git checkout master');
};
EOF

    # Create a tempfile to store the Fetchwarefile in.
    my ($fh, $filename) = tempfile("fetchware-test-$$-XXXXXXXXXXX", TMPDIR => 1,
        UNLINK => 1);
    # Write the $apache_fetchwarefile to disk, so bin/fetchware can access it.
    print $fh $php_git_fetchwarefile;
    close $fh; # Close $fh to ensure its contents make it out to disk.

    # Just execute bin/fetchware install with the newly created
    # apache.Fetchwarefile to test it.
    ok(run_prog(qw!perl -I lib bin/fetchware install!, $filename),
        'Checked PHP git Fetchwarefile success.');
};



subtest 'test MariaDB Fetchwarefile success' => sub {

    my $mariadb_fetchwarefile = <<'EOF';
use App::Fetchware;

program 'MariaDB';

# MariaDB uses ccache, which wants to create a ~/.ccache cache, which it can't
# do when it's running as nobody, so use a real user account to ensure ccache
# has a cache directory it can write to.
user 'dly';

lookup_url 'https://downloads.mariadb.org/';

# Below are the two USA mirrors where I live. Customize them as you need based
# on the mirrors listed on the download page (https://downloads.mariadb.org/ and
# then click on which version you want, and then click on the various mirrors
# by country. All you need is the scheme (ftp:// or http:// part) and the
# hostname without a slash (ftp.osuosl.org or mirror.jmu.edu). Not the full path
# for each mirror.
mirror 'http://ftp.osuosl.org';
mirror 'http://mirror.jmu.edu';

# The filter option is key to the custom lookup hook working correctly. It must
# represent the text that corresponds to the latest GA release of MariaDB
# available. It should be 'Download 5.5' for 5.5 or 'Download 10.0' for the
# newver but not GA 10.0 version of MariaDB.
filter 'Download 5.5';

hook lookup => sub {
    vmsg "Downloading HTML download page listing MariaDB releases.";
    my $dir_list = http_download_dirlist(config('lookup_url'));

    vmsg "Parsing HTML page listing MariaDB releases.";
    my $tree = HTML::TreeBuilder->new_from_content($dir_list);

    # This parsing code assumes that the latest version of php is the first one
    # we find, which seems like a dependency that's unlikely to change.
    my @version_number;
    $tree->look_down(
        _tag => 'a',
        sub {
            my $h = shift;
            
            my $link = $h->as_text();

            # Find the filter which should be "Download\s[LATESTVERSION]"
            my $filter = config('filter');
            if ($link =~ /$filter/) {
                # Parse out the version number.
                # It's just the second space separated field.
                push @version_number, (split ' ', $link)[1];
            }
        }
    );

    # Delete the $tree, so perl can garbage collect it.
    $tree = $tree->delete;

    # Only one version should be found.
    die <<EOD if @version_number > 1;
mariaDB.Fetchwarefile: multiple version numbers detected. You should probably
refine your filter option and try again. Filter [@{[config('filter')]}].
Versions found [@version_number].
EOD

    # Construct a download path using $version_number[0].
    my $filename = 'mariadb-' . $version_number[0] . '.tar.gz';

    # Return a proper $download_path, so That I do not have to hook download(),
    # but can reuse Fetchware's download() subroutine.
    my $weird_prefix = '/mariadb-' . $version_number[0] . '/kvm-tarbake-jaunty-x86/';
    my $download_path = '/pub/mariadb' . $weird_prefix .$filename;
    return $download_path;
};

# Make verify() failing to verify MariaDB ok, because parsing out the MD5 sum
# would require a Web scraper that supports javascript, which HTML::TreeBuilder
# obviously does not.
verify_failure_ok 'On';

# Use build_commands to configure fetchware to use MariaDB's BUILD script to
# build it.
build_commands 'BUILD/compile-pentium64-max';

# Use install_commands to tell fetchware how to install it. I could leave this
# out, but it nicely documents what command is needed to install MariaDB
# properly.
install_commands 'make install';
EOF

    # Create a tempfile to store the Fetchwarefile in.
    my ($fh, $filename) = tempfile("fetchware-test-$$-XXXXXXXXXXX", TMPDIR => 1,
        UNLINK => 1);
    # Write the $apache_fetchwarefile to disk, so bin/fetchware can access it.
    print $fh $mariadb_fetchwarefile;
    close $fh; # Close $fh to ensure its contents make it out to disk.

    # Just execute bin/fetchware install with the newly created
    # apache.Fetchwarefile to test it.
    ok(run_prog(qw!perl -I lib bin/fetchware install!, $filename),
        'Checked MariaDB Fetchwarefile success.');
};



subtest 'test PostgreSQL Fetchwarefile success' => sub {

    my $postgresql_fetchwarefile = <<'EOF';
use App::Fetchware qw(:DEFAULT :OVERRIDE_LOOKUP);
use App::Fetchware::Util ':UTIL';
use Data::Dumper 'Dumper';

use HTML::TreeBuilder;

program 'postgres';

# The Postgres file browser URL lists the available versions of Postgres.
lookup_url 'http://www.postgresql.org/ftp/source/';

# Mirror URL where the file browser links to download them from.
my $mirror = 'http://ftp.postgresql.org';
mirror $mirror;

# The Postgres file browser URL that is used for the lookup_url lists version
# numbers of Postgres like v9.3.0. this lookup hook parses out the list of
# theses numbers, determines the latest one, and constructs a $download_path to
# return for download to use to download based on what I set my mirror to.
hook lookup => sub {
    my $dir_list = no_mirror_download_dirlist(config('lookup_url'));

    my $tree = HTML::TreeBuilder->new_from_content($dir_list);

    # Parse out version number directories.
    my @ver_nums;
    my @list_context = $tree->look_down(
        _tag => 'a',
        sub {
            my $h = shift;

            my $link = $h->as_text();

            # Is this link a version number or something to ignore?
            if ($link =~ /^v\d+\.\d+(.\d+)?$/) {
                # skip version numbers that are beta's, alpha's or release
                # candidates (rc).
                return if $link =~ /beta|alpha|rc/i;
                # Strip useless "v" that just gets in the way later when I
                # create the $download_path.
                $link =~ s/^v//;
                push @ver_nums, $link;
            }
        }
    );

    # Turn @ver_num into the array of arrays that lookup_by_versionstring()
    # needs its arguments to be in.
    my $directory_listing = do {
        my $arrayref_of_arrays_directory_listing = [];
        for my $ver_num (@ver_nums) {
            push @$arrayref_of_arrays_directory_listing,
                [$ver_num];
        }
        $arrayref_of_arrays_directory_listing;
    };
    # Find latest version.
    my $latest_ver = lookup_by_versionstring($directory_listing);

    # Return $download_path.
    my $download_path = '/pub/source/'. "v$latest_ver->[0][0]" .
        "/postgresql-$latest_ver->[0][0].tar.bz2";
    return $download_path;
};

# MD5sums are stored on the download site, so use them to verify the package.
verify_method 'md5';
# But they are *not* stored on the original "lookup_url" site, so I must provide
# a md5_url pointing to the download site.
md5_url $mirror;
EOF

    # Create a tempfile to store the Fetchwarefile in.
    my ($fh, $filename) = tempfile("fetchware-test-$$-XXXXXXXXXXX", TMPDIR => 1,
        UNLINK => 1);
    # Write the $apache_fetchwarefile to disk, so bin/fetchware can access it.
    print $fh $postgresql_fetchwarefile;
    close $fh; # Close $fh to ensure its contents make it out to disk.

    # Just execute bin/fetchware install with the newly created
    # apache.Fetchwarefile to test it.
    ok(run_prog(qw!perl -I lib bin/fetchware install!, $filename),
        'Checked PostgreSQL Fetchwarefile success.');
};


# End annoying SKIP block.
}

# Remove this or comment it out, and specify the number of tests, because doing
# so is more robust than using this, but this is better than no_plan.
#done_testing();
