use v5.38;
use feature 'class';
no warnings qw(
    experimental::class
    experimental::for_list
);

use Net::NVD;
use Path::Tiny;
use CPANSEC::Admin::Util;

class CPANSEC::Admin::Command::CVEScan {
    field %options;

    method name { 'cvescan' }

    method command ($manager, @args){
        %options = $manager->get_options(\@args, {
            'triage-dir=s'    =>  './triage',
            'index-file=s'    => '{triage_dir}/last_visited_index',
            'from=i'          => undef,
            'ignore=s'        => undef,
            'limit=i'         => undef,
            'no-index-update' => undef,
        });
        $options{from} = _read_index_file($options{index_file}) unless $options{from};
        my %ignored = _fetch_ignore_list($options{ignore});

        $manager->info('querying NVD. Initial index is ' . $options{from});
        my $cves = _get_cves(%options);

        $manager->info(@$cves . ' CVEs set for triage.');
        return if !@$cves;
        my $candidates = _find_eligible_candidates($cves, \%ignored);

        if (@$candidates) {
            $manager->info('processing ' . @$candidates . ' eligible candidates');
            my @processed = map _process_candidate($_), @$candidates;

            $manager->info('storing candidates for triage');
            _save_for_triage(\%options, \@processed);
        }
        else {
            $manager->info('no eligible candidates found.');
        }

        if (!$options{no_index_update}) {
            $manager->info('updating index file');
            _update_index_file(\%options, scalar(@$cves));
        }

        $manager->info('complete');
    }

    sub _update_index_file ($opts, $entries_read) {
        my $new_index = $opts->{from} + $entries_read;
        Path::Tiny::path($opts->{index_file})->spew_raw($new_index);
    }

    sub _fetch_ignore_list ($path) {
        return () unless defined $path;
        $path = Path::Tiny::path($path);
        die "$path not found (for --ignore)." unless $path->is_file;
        my %ignored = map { /(CVE\-\d+\-\d+)/ ? ($1 => 1) : () } $path->lines;
        return %ignored;
    }

    sub _save_for_triage ($opts, $candidates) {
        my $basedir = Path::Tiny::path( $opts->{'triage_dir'} );
        foreach my $candidate (@$candidates) {
            CPANSEC::Admin::Util::triage_write($basedir->child($candidate->[1]) . '.yml', $candidate);
        }
    }

    sub _process_candidate ($cve) {
        my ($description) = map $_->{value}, grep $_->{lang} eq 'en', $cve->{descriptions}->@*;
        $description //= 'REPLACE ME';

        # use the highest CVSS version we can find.
        my ($cvss_version, $cvss_value);
        foreach my ($k, $v) ($cve->{metrics}->%*) {
            my ($version) = $k =~ /cvssMetricV(\d)/;
            if (!$cvss_version || $cvss_version < $version) {
                $cvss_version = $version;
                $cvss_value = $v->[0]{cvssData}{vectorString};
            }
        }

        return [
            cve                => $cve->{id},
            summary            => '~',
            description        => $description,
            categories         => '~',
            ($cvss_version
                ? ("CVSS_$cvss_version" => $cvss_value)
                : ()
            ),
            references         => [ map $_->{url}, $cve->{references}->@* ],
            cpan_distribution  => '~',
            version_range      => '~',
        ];
    }

    sub _find_eligible_candidates ($cves, $ignored) {
        my @candidates;
        foreach my $cve (@$cves) {
            push @candidates, $cve
                if !$ignored->{ $cve->{id } }
                && $cve->{descriptions}[0]{value} =~ /(cpan|perl)\b/in;
        }
        return \@candidates;
    }

    sub _get_cves (%opts) {
        my $nvd = Net::NVD->new;
        my @cves = $nvd->search(
            # keyword_search => 'perl cpan',
            # ^^ NVD keyword search would be perfect, but for some reason
            # it misses a LOT of entries. So we filter ourselves.
            start_index  => $opts{from},
            no_rejected  => 1,
            ($opts{limit} ? (results_per_page => $opts{limit}) : ()),
        );
        return \@cves;
    }

    sub _read_index_file ($path) {
        return 0 unless $path;
        $path = Path::Tiny::path($path);
        return 0 unless $path->is_file;
        my $data = $path->slurp;
        chomp $data if $data =~ /\n/;
        die "invalid index '$data' in $path." unless $data =~ /\A[0-9]+\z/;
        return $data;
    }
}

__END__

=head1 NAME

CPANSEC::Admin::Command::CVEScan - Scans CVE entries for potential CPAN packages

=head1 SYNOPSIS

    cpansec-admin cvescan  [-q | --quiet] [--triage-dir=<path>]
                           [--from=<value>] [--limit=<value>]
                           [--ignore=<path>] [--no-index-update]

=head1 DESCRIPTION

This command scans CVE entries to triage for potential CPAN packages.

=head1 ARGUMENTS

    -q, --quiet               Silence all output, except for errors. Can
                              also be set via the CPANSEC_QUIET environment
                              variable.

    --triage-dir=<path>       Use a custom path for the triage (destination)
                              folder. Defaults to "./triage". Can also be set
                              via the CPANSEC_TRIAGE_DIR environment variable.

    --index-file=<path>       Reads the given file for a single line
                              containing the index of the last visited CVE.
                              Defaults to the "last_visited_index" file inside
                              the specified triage folder. Can also be set via
                              the CPANSEC_INDEX_FILE environment variable.

    --from=<index>            Start scan from an index other than the one
                              defined by "--index-file". Can also be set via
                              the CPANSEC_FROM environment variable.

    --limit=<value>           Limit the amount of CVEs to fetch. Defaults to
                              the NVD server-side limit, currently at 2K. Can
                              also be set via the CPANSEC_LIMIT environment
                              variable.

    --ignore=<path>           Reads a file containing a list of CVE entries to
                              ignore when scanning. Can also be set via the
                              CPANSEC_IGNORE environment variable.

    --no-index-update         Use this flag to prevent the index file from
                              being updated at the end of the scan. Can also
                              be set via the CPANSEC_NO_INDEX_UPDATE
                              environment variable.