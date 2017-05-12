use strict;
use warnings;
use inc::Module::Install;

# Module::Install stuff
{
    no_index directory => 't/lib';
    no_index file => 'examples/friends_photos/FriendsPhotos.pm';

    license ('perl');

   # Graphics::Magick is recommended over Image::Magick, but isn't on CPAN
    recommends
        'Image::Magick'    => 0;

   # This could probably become a "test_requires"
   requires 'Image::Size' => 0;


}


use Config ();
use Getopt::Long();
use Data::Dumper ();

my $TESTDB  = "test";

use vars qw($opt);
$opt = {
    "help"    => \&Usage ,
     testdsn  => 'dbi:SQLite:dbname=t/test.db',
};

Getopt::Long::GetOptions($opt, "help", "testdsn=s", "testuser=s","testpassword=s");
my $source = {};

for my $key (qw/testdsn testuser testpassword/) {
  Configure($opt, $source, $key);
}

print <<"MSG";
I will use the following settings for compiling and testing:

MSG

delete $opt->{'help'};
my $keylen = 0;
for my $key (keys %$opt) {
  $keylen = length($key) if length($key) > $keylen;
}
my $slen = 0;
for my $val (values %$source) {
  $slen = length($val) if length($val) > $slen;
}
for my $key (sort { $a cmp $b} keys %$opt) {
  printf("  %-" . $keylen . "s (%-" . $slen . "s) = %s\n",
     $key, $source->{$key}, $opt->{$key})
}

print <<"MSG";

To change these settings, see 'perl Makefile.PL --help'.

MSG

#sleep 5;

eval { require File::Spec };
my $fileName = $@ ?
  "t/cgi-uploader.config" : File::Spec->catfile("t", "cgi-uploader.config");
die "Failed to determine location of $fileName" unless -f $fileName;

if (open(FILE, ">$fileName")) {
    print FILE '$dsn      = q!'.$opt->{testdsn}."!;\n";
    print FILE '$user     = q!'.$opt->{testuser}."!;\n";
    print FILE '$password = q!'.$opt->{testpassword}."!;\n";
    print FILE "1;\n";
    close(FILE) or die "Failed to create $fileName: $!";
}

sub Configure {
    my($opt, $source, $param) = @_;

    if (exists($opt->{$param})) {
        $source->{$param} = "Users choice";
        return;
    }
    elsif ($param eq "testuser"  || $param eq "testpassword" ||
             $param eq "testdsn") {
        $source->{$param} = "default";
        $opt->{$param} = "";
    } else {
        die "Unknown configuration parameter: $param";
    }
}


sub Usage {
  print STDERR <<"USAGE";
Usage: perl $0 [options]

Possible options are:

  --testdsn=<dsn>         Use the DBI datasource <dsn> for running the test suite

      Postgres Example:
       dbi:Pg:dbname=\$db;host=\$host;username=\$user;password=\$pw

      MySQL Example:
       DBI:mysql:database=\$db;host=\$hostname

 --testuser=<user>

 --testpassword=<password>

  --help                 Print this message and exit

  Tables named "uploads" and "cgi_uploader_test"  will be created and then
  removed.  If a table by that name already exists, the tests will be skipped.

USAGE
  exit 1;
}



use 5.008;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'      => 'CGI::Uploader',
     AUTHOR     => 'Mark Stosberg <mark@summersault.com>',
    'VERSION_FROM'  => 'lib/CGI/Uploader.pm', # finds $VERSION
    'PREREQ_PM'     => {
        'Carp::Assert'        => 0,
        'CGI::Carp'           => 0,
        'Digest::MD5'         => 0,
        'File::Copy'          => 0,
        'File::Spec'          => 0,
        'File::MMagic'        => 1.22,
        'File::Path'          => 0,
        'MIME::Type'          => 0,
        'MIME::Types'         => 0,
        'Params::Validate'    => 0.77,
        'SQL::Abstract'       => 0,
        'CGI'                 => 0,
        'DBI'                 => 0,
        'DBD::SQLite'         => 1.1,
        'File::Temp'          => 0.15,
        'Test::DatabaseRow'   => 0,
        'HTTP::BrowserDetect' => 0.98,
        'Scalar::Util'        => 0,

        # For testing
        'HTTP::Request::Common' => 0,

    },
);
