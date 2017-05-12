use 5.010;
use Test::More;
use App::QuoteCC;
use Encode;
use File::Slurp qw(slurp);
use File::Temp qw<tempdir tempfile>;

plan skip_all => "Need curl / gcc / lua to test"
    unless
        qx[ curl --version ] =~ /^curl \d+\..*\nProtocols:/s and
        qx[ gcc --version ]  =~ /Free Software Foundation/ and
        qx[ lua -e 'require "posix"; print(string.format("The time is %s", os.time()));' ] =~ /^The time is \d+$/;
plan tests => 65;

my @test = (
    {
        url => 'http://v.nix.is/~failo/quotes.yml',
        fmt => 'YAML',
    },
    {
        url => 'http://www.trout.me.uk/quotes.txt',
        fmt => 'Fortune',
    }
);

sub test_quotes_encoding {
    my ($output, $quote, $url) = @_;

    ok($quote, "Got quote from $output --all");
    cmp_ok(length($quote), '>', 1000, "All quotes were long enough");
    if ($url =~ /failo/) {
        like $quote, qr/mosque on Phobos/, "sanity check";
        like $quote, qr/Blökkumaður/, "sanity check";
        like $quote, qr/botti líka/, "sanity check";
    }
}

for my $compiler (qw/Perl C Lua/) {
    for my $test (@test) {
        my $url = $test->{url};
        my $fmt = $test->{fmt};

        # Dir to store our stuff
        my $dir = tempdir( "app-quotecc-XXXX", CLEANUP => 1, TMPDIR => 1 );
        ok(-d $dir, "tempdir $dir exists");
        my ($fh1, $quotes) = tempfile( DIR => $dir, SUFFIX => '.quotes', EXLOCK => 0 );
        my ($fh2, $output) = tempfile( DIR => $dir, SUFFIX => '.' . lc($compiler), EXLOCK => 0 );
        ok(-f $_, "tempfile $_ exists") for $quotes, $output;

        my $cmd = qq[curl --user-agent 'App::QuoteCC/$App::QuoteCC::VERSION' -s '$url' --output '$quotes'];
        system $cmd;
        App::QuoteCC->new(
            input => $quotes,
            input_format => $fmt,
            output => $output,
            output_format => $compiler,
        )->run;
        ok(-s $quotes, "$quotes is non-zero size");
        ok(-s $output, "$output is non-zero size");

        given ($compiler) {
            when ('Lua') {
                system "chmod +x $output";

                chomp(my $quote = qx[lua $output]);
                ok($quote, "Got quote from $output");

                chomp($quote = qx[lua $output --all]);
                ok($quote, "Got quote from $output --all");
                test_quotes_encoding($output, $quote, $url);
            }
            when ('C') {
                $cmd = qq[gcc -Wall $output -o $output.exe];
                system $cmd;

                chomp(my $quote = qx[$output.exe]);
                ok($quote, "Got quote from $output.exe");

                chomp($quote = qx[$output.exe --all]);
                ok($quote, "Got quote from $output.exe --all");
                test_quotes_encoding($output, $quote, $url);
            }
            when ('Perl') {
                my $raw = slurp($output);
                unlike($raw, qr/require MIME::Base64/, "Data::Dump didn't use modules");

                chomp(my $quote = qx[$^X $output]);
                ok($quote, "Got quote from $^X $output");
                cmp_ok(length($quote), '>', 5, "quote was long enough");

                chomp($quote = qx[$^X $output --all]);
                test_quotes_encoding($output, $quote, $url);
            }
        }
    }
}
