use v5.38;
use version;
use feature 'class';
use builtin qw( true false );
no warnings qw(
    experimental::class
    experimental::builtin
);

use Time::Piece;
use Path::Tiny ();
use CPANSEC::Admin::Util;
use JSON ();
use List::Util ();

class CPANSEC::Admin::Command::Publish {
    field %options;
    my $current_id;
    my $time = gmtime;

    method name { 'publish' }

    method command ($manager, @args) {
        %options = $manager->get_options(\@args, {
            'triage-dir=s'  => './triage',
            'published-dir' => './advisories',
            'all'           => undef,
        });
        die "cannot use --all with a filename (@args)" if $options{all} && @args;
        $options{files} = @args ? [map Path::Tiny::path($_), @args]
                        : [Path::Tiny::path($options{triage_dir})->children( qr/\.yml\z/ )];
        die 'no files found!' unless $options{files};

        $current_id = _find_last_used_id($options{published_dir});
        foreach my $file (sort $options{files}->@*) {
            $self->_process_file($manager, $file);
        }
    }

    method _process_file ($manager, $file) {
        my %data = CPANSEC::Admin::Util::triage_read($file)->@*;
        if (!$data{approved} || $data{approved} ne 'true') {
            $manager->info("report $file is not approved yet, please use 'triage' first") unless $options{all};
            return;
        }
        my $osv = _triage2osv(%data);
        my $target = Path::Tiny::path($options{published_dir}, $osv->{id} . '.json');
        die "$target already exists!" if $target->exists;
        $target->spew_raw(JSON::encode_json($osv));
        $file->remove;
        $current_id++;
    }

    sub _find_last_used_id($published_dir) {
        my ($file) = sort { $b <=> $a } Path::Tiny::path($published_dir)->children(qr/\ACPANSEC\-\d+\-\d+\.json\z/);
        my ($year, $id) = $file =~ /\ACPANSEC\-(\d+)\-(\d+)\.json\z/;
        $id = 0 if $year < $time->year;
        return $id + 1;
    }

    sub _triage2osv (%data) {
        my $id = sprintf('CPANSEC-%04d-%04d', $time->year, $current_id);
        return {
            schema_version => '1.6.0',
            id             => $id,
            modified       => $time->datetime . 'Z',
            published      => $time->datetime . 'Z',
            aliases        => [ $data{cve} ],
            summary        => $data{summary},
            details        => $data{description},
            ($data{CVSS_2} || $data{CVSS_3} ?
                (severity => [{
                    ($data{CVSS_2} ? (type => 'CVSS_V2', score => $data{CVSS_2})
                                   : (type => 'CVSS_V3', score => $data{CVSS_3})),
                }])
                : ()
            ),
            affected => [{
                package => {
                    ecosystem => 'CPAN',
                    name      => $data{cpan_distribution},
                    purl      => 'pkg:cpan/' . $data{cpan_distribution},
                },
                versions => _get_versions_from_range($data{cpan_distribution}, $data{version_range}),
                ecosystem_specific => {
                    source => 'https://github.com/CPAN-Security/cpan-advisory-database/blob/advisories/' . $id . '.json',
                    categories => [split /\s*;\s*/ => $data{categories}],
                    version_range => $data{version_range},
                },
            } ],
            references => _parse_references($data{references}),
            database_specific => { license => 'CC0-1.0' },
        };
    }

    sub split_version_range ($version_range) {
        my (@greater, @lower, @equal, @not_equal);
        foreach my $expr (split /\s*,\s*/, $version_range) {
            if ($expr =~ /\A\s*([>=<!]=?)?\s*([0-9]\S*)\s*\z/) {
                my ($op, $ver) = ($1, $2);
                $ver = version->parse($ver);
                if ($op eq '>') {
                    push @greater, $ver;
                }
                elsif ($op eq '>=') {
                    push @greater, $ver;
                    push @equal, $ver;
                }
                elsif ($op eq '<') {
                    push @lower, $ver;
                }
                elsif ($op eq '<=') {
                    push @lower, $ver;
                    push @equal, $ver;
                }
                elsif ($op eq '!=') {
                    push @not_equal, $ver;
                }
                elsif ($op eq '==') {
                    push @equal, $ver;
                }
                else {
                    die "unknown operator '$op' in '$expr'";
                }
            }
            else {
                die "unknown version range '$expr'";
            }
        }
        return { greater => \@greater, lower => \@lower, equal => \@equal, not_equal => \@not_equal };
    }

    sub _get_versions_from_range ($distname, $version_range) {
        my $ranges = split_version_range ($version_range);

        my $response = JSON::decode_json(
            HTTP::Tiny->new->post('https://fastapi.metacpan.org/release?size=500', {
                content => encode_json({
                    query => { term => { distribution => $distname } },
                    fields => ['version']
                })
            })->{content}
        );
        my @all_versions = map version->parse($_->{fields}{version}), $response->{hits}{hits}->@*;

        my @versions_in_range;
        foreach my $version (@all_versions) {
            push @versions_in_range, $version if version_in_range($version, $ranges);
        }
        return [sort @versions_in_range];
    }

    sub version_in_range ($version, $range) {
        return true  if List::Util::any { $version == $_ } $range->{equal}->@*;
        return false if List::Util::any { $version == $_ } $range->{not_equal}->@*;
        my @greater = sort $range->{greater}->@*;
        my @lower   = sort $range->{lower}->@*;
        return true if @greater && (!@lower || $greater[-1] > $lower[-1]) && $version > $greater[-1];
        return true if @lower && (!@greater || ($lower[0] < $greater[0])) && $version < $lower[0];
        return true  if (( List::Util::any { $version >  $_ } $range->{greater}->@*)
                        && (List::Util::any { $version <  $_ } $range->{lower}->@*));
        return false;
    }

    sub _parse_references ($references) {
        my @parsed;
        foreach my $url (@$references) {
            my $type;
            if ($url =~ m{\Ahttps?://metacpan.org/.+}) {
                $type = 'PACKAGE';
            }
            if ($url =~ m{\Ahttps?://github.com/.+?/issues/.+}) {
                $type = 'REPORT'
            }
            elsif ($url =~ m{\Ahttps?://github.com/.+?/pull/.+}) {
                $type = 'FIX'
            }
            elsif ($url =~ m{\blists?\b}) {
                $type = 'DISCUSSION';
            }
            elsif ($url =~ m{\bblogs?\b}) {
                $type = 'ARTICLE';
            }
            else {
                $type = 'WEB';
            }
            push @parsed, { type => $type, url => $url };
        }
        return \@parsed;
    }
}

__END__

=head1 NAME

CPANSEC::Admin::Command::Publish - handles advisories ready for publishing

=head1 SYNOPSIS

    cpansec-admin publish  [--triage-dir=<path>] [--published-dir=<path>]
                           [-a | --all] [<filepath>...]

=head1 DESCRIPTION

This command takes approved advisories from triage, converts them to the
OSV JSON format, assigns them a unique CPANSEC-YYYY-NNNN identifier and
moves them to the published folder.

=head1 ARGUMENTS

    -a, --all                 Inspect the entire triage folder. Alternatively,
                              you may inspect a single candidate by passing
                              its filename.

    --triage-dir=<path>       Use a custom path for the triage (source)
                              folder. Defaults to "./triage". Can also be set
                              via the CPANSEC_TRIAGE_DIR environment variable.
                              This option is ignored when you pass specific
                              file paths instead of --all.

    --published-dir=<path>    Use a custom path for the published (destination)
                              folder. Defaults to "./advisories". Can also be set
                              via the CPANSEC_PUBLISHED_DIR environment variable.