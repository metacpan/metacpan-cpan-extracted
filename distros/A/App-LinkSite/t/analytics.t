use strict;
use warnings;
use Test::More;
use FindBin '$Bin';
use File::Temp 'tempdir';
use JSON;
use Path::Tiny;
use App::LinkSite;

my $src = path($Bin)->parent->child('src')->absolute;
my $work = path(tempdir(CLEANUP => 1));

for my $case (
    ['configured ID', { ga4 => 'G-EXAMPLE123' }],
    ['different configured ID', { ga4 => 'G-OTHER456' }],
    ['omitted ID', {}],
    ['empty ID', { ga4 => '' }],
    ['null ID', { ga4 => undef }],
) {
    my ($label, $analytics) = @$case;
    subtest $label => sub {
        my $directory = $work->child($label);
        $directory->mkpath;
        my $input = $directory->child('links.json');
        $input->spew(JSON->new->encode({
            name => 'Analytics fixture', handle => 'example',
            desc => 'Analytics rendering test', image => '', og_image => '',
            site_url => 'https://example.invalid/', social => [], links => [],
            %$analytics,
        }));
        my $out = $directory->child('public');
        App::LinkSite->new(file => "$input", src => "$src", out => "$out")->run;

        my $html = $out->child('index.html')->slurp;
        like($html, qr/<title>Analytics fixture \/ \@example<\/title>/,
            'the source template renders the input');
        if (defined $analytics->{ga4} && length $analytics->{ga4}) {
            my ($loader_id) = $html =~ m{https://www\.googletagmanager\.com/gtag/js\?id=([^"\s]+)};
            is($loader_id, $analytics->{ga4}, 'loader uses the configured measurement ID');
            my ($config_id) = $html =~ /gtag\('config', '([^']+)'\)/;
            is($config_id, $analytics->{ga4}, 'configuration uses the same measurement ID');
        } else {
            unlike($html, qr/gtag|googletagmanager|dataLayer/,
                'disabled analytics emits neither the loader nor initialization code');
        }
        done_testing;
    };
}

done_testing;
