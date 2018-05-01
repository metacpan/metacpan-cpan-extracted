package Test::App::Wax;

# helper lib which exports a `wax_is` assertion and some fixtures (arrays)
# which map URLs to local filenames

use strict;
use warnings;
use base qw(Exporter);

use App::Wax;
use Method::Signatures::Simple;
use Test::Differences qw(eq_or_diff);
use Test::TinyMocker qw(mock);

my @FILENAMES = ('1.json', '2.html');

our @KEEP = map { "/cache/file$_" } @FILENAMES;
our @TEMP = map { "/tmp/file$_" } @FILENAMES;
our @URL = map { "http://example.com/$_" } @FILENAMES;

my %FILENAME_TEMP = map { $URL[$_] => $TEMP[$_] } 0 .. $#FILENAMES;
my %FILENAME_KEEP = map { $URL[$_] => $KEEP[$_] } 0 .. $#FILENAMES;

our @EXPORT_OK = qw(@KEEP @TEMP @URL wax_is);

# a test helper (assertion) which takes a wax command (string/arrayref) and the
# command we expect it to be translated into (string/arrayref) then calls wax
# in test mode, which returns the translated command. passes if the latter
# matches; otherwise, fails and displays a diff
func wax_is ($args, $want) {
    my @args = ref($args) ? @$args : split(/\s+/, $args);
    my @want = ref($want) ? @$want : split(/\s+/, $want);
    my $wax  = App::Wax->new();

    shift(@args) if ($args[0] eq 'wax');

    my $description = sprintf(
        'wax %s => %s',
        $wax->dump_command(\@args),
        $wax->dump_command(\@want)
    );

    my $got = $wax->run([ '--test', @args ]);

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    eq_or_diff $got, \@want, $description;
}

# by hooking the `resolve` method, which maps a URL to its local filename, we
# can avoid network requests and make the filenames deterministic.
# XXX note this doesn't allow us to (properly) test things like --timeout
# and --user-agent
mock(
    'App::Wax::resolve' => method ($_url) {
        my ($url, $url_index) = @$_url;
        my $filename = $self->keep ? $FILENAME_KEEP{$url} : $FILENAME_TEMP{$url};
        my @resolved = ($filename, undef); # (filename, error)

        return wantarray ? @resolved : \@resolved;
    }
);

1;
