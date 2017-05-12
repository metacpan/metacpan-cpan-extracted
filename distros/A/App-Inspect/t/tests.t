use Test2::Bundle::Extended;

use App::Inspect;

sub capture(&) {
    my $code = shift;

    my $out = "";

    my ($ok, $e);
    {
        local *STDOUT;

        ($ok, $e) = Test2::Util::try(sub {
            open(STDOUT, '>', \$out) or die "Failed to open a temporary STDOUT: $!";

            $code->();
        });
    }

    die $e unless $ok;

    return $out;
}

require 'scripts/inspect';

imported_ok('run');

use Term::ANSIColor qw/color/;

my $normal = color('reset');
my $red    = color('bold red');
my $grn    = color('bold green');
my $blu    = color('blue');
my $ylw    = color('yellow');

$INC{'Found/File1.pm'} = 'path/to/found/file1.pm';
$INC{'Found/File2.pm'} = 'path/to/found/file2.pm';

$Found::File1::VERSION = "2.123";

my $out = capture { run('Found::File1', 'Found::File2', 'Not::Found') };
is([split /\n+/, $out], [split /\n+/, <<"EOT"], "got expected output");

${grn}Found::File1${normal} ${grn}2.123${normal} is installed at  ${blu}path/to/found/file1.pm${normal}
${grn}Found::File2${normal} ${ylw}--   ${normal} is installed at  ${blu}path/to/found/file2.pm${normal}
${red}Not::Found  ${normal} ${red}--   ${normal} ${red}is not installed${normal}${blu}${normal}
EOT

done_testing;
