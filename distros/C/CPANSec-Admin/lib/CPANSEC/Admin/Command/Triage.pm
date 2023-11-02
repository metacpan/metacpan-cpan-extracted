use v5.38;
use builtin qw( trim true false );
use feature qw( class try );
no warnings qw(
    experimental::class
    experimental::builtin
    experimental::try
    experimental::const_attr
);

use Getopt::Long;
use Path::Tiny;
use List::Util;
use MetaCPAN::Client;
use CPAN::Meta::Requirements;
use URI;

use CPANSEC::Admin::Util;
local $| = 1;

class CPANSEC::Admin::Command::Triage {
    field %options;

    *NOTADIST   = sub : const { 1 };
    *PERLISSUE  = sub : const { 2 };
    *UNRELATED  = sub : const { 3 };
    *THIRDPARTY = sub : const { 4 };
    *VALIDISSUE = sub : const { 5 };
    *NOTSURE    = sub : const { 6 };

    my %rejection_criteria = (
        NOTADIST()   => 'Not a CPAN distribution',
        PERLISSUE()  => 'Issue refers to Perl itself',
        UNRELATED()  => 'Unrelated to Perl or Perl modules',
        THIRDPARTY() => 'Third-party (DarkPAN, not CPAN)',
        VALIDISSUE() => '** VALID! **',
        NOTSURE()    => '(not sure... better skip this one for now)',
    );

    method name { 'triage' }

    method command ($manager, @args) {
        %options = $manager->get_options(\@args, {
            'triage-dir=s' => './triage',
            'all'          => undef,
        });
        die "cannot use --all with a filename (@args)" if $options{all} && @args;
        $options{files} = @args ? [map Path::Tiny::path($_), @args]
                        : [Path::Tiny::path($options{triage_dir})->children( qr/\.yml\z/ )];
        die 'no files found!' unless $options{files};

        my $total = scalar $options{files}->@*;
        my $current = 0;
        foreach my $file (sort $options{files}->@*) {
            $manager->info('(' . ++$current . "/$total) processing '$file'");
            $self->_process_file($manager, $file);
        }
    }

    method _process_file ($manager, $file) {
        my %data = CPANSEC::Admin::Util::triage_read($file)->@*;
        return if $options{all} && $data{approved} && $data{approved} eq 'true';
        say join("\n", 'References:', $data{references}->@*) . "\n\n$data{description}\n";
        my $msg = CPANSEC::Admin::Util::prompt(
            "Please triage the information above as:\n"
          . join("\n", map "  $_. $rejection_criteria{$_}" => sort keys %rejection_criteria),
          1 .. scalar keys %rejection_criteria
        );
        if ($msg == NOTSURE()) {
            $manager->info('Skipped!');
        }
        elsif ($msg == VALIDISSUE()) {
            if ($self->review(\%data)) {
                CPANSEC::Admin::Util::triage_write($file, \%data);
            }
        }
        else {
            $manager->info('adding entry to ignored list');
            $self->add_to_ignored($file, $msg);
        }
        return;
    }

    method review ($data) {
        while (!$data->{cve} || $data->{cve} !~ /\ACVE-\d{4}\-\d{4,}\z/) {
            $data->{cve} = CPANSEC::Admin::Util::prompt('Please type a proper CVE or "~" if your are *SURE* there is none.');
            last if $data->{cve} && $data->{cve} eq '~';
        }

        my $valid_dist;
        while (!$valid_dist) {
            my $dist = $data->{cpan_distribution}
                    // CPANSEC::Admin::Util::prompt('Please type a valid distribution name for this issue (with "-", not "::", and no version)');
            if ($dist !~ /\A(\s|~|:)*\z/n) {
                try { MetaCPAN::Client->new->distribution($dist); $valid_dist = $dist }
                catch ($e) { warn $e unless $e =~ /Not Found/ }
            }
        }
        $data->{cpan_distribution} = $valid_dist;

        my $valid_description;
        while (!$valid_description) {
            my $desc = CPANSEC::Admin::Util::prompt(
                'Please describe the issue in detail. Use literal "\n" for line breaks '
              . '`backticks` for code and [name](https://...) for links where necessary. '
              . '50 characters minimum. Please don\'t just copy-paste a CVE description, '
              . 'follow references so people reading this advisory are able to understand '
              . 'any possible risks and make a decision.'
            );
            $valid_description = $desc if length($desc) > 50;
        }
        $data->{description} = $valid_description;

        while (!$data->{summary} || 20 < length($data->{summary}) < 120) {
            $data->{summary} = CPANSEC::Admin::Util::prompt('Please provide a summary for the issue (20-120 chars)');
        }

        CATEGORY:
        while (!$data->{categories} || $data->{categories} ne '~') {
            my %valid_categories = map { $_ => 1 } qw( code-execution denial-of-service crypto-failure);
            my $cat_input = CPANSEC::Admin::Util::prompt(
                'Please provide one or more categories for this issue (separated by ";"). '
              . "Categories can be any of:\n - " . join("\n - " => sort keys %valid_categories)
            );
            foreach my $cat (split /\s*;\s*/, $cat_input) {
                redo CATEGORY unless exists $valid_categories{$cat};
            }
            $data->{categories} = $cat_input;
        }

        while (
            ref $data->{references} ne 'ARRAY'
         || List::Util::notall { URI->new($_)->has_recognized_scheme } $data->{references}->@*
        ) {
            my @input = split /;/, CPANSEC::Admin::Util::prompt('Please provide at least one reference URL (separate URLs with ";")');
            $data->{references} = \@input;
        }
        # TODO: check CVSS_2 and CVSS_3
        my $version_range;
        while (!defined $version_range) {
            my $v_range = $data->{version_range}
                // CPANSEC::Admin::Util::prompt("Please provide the version range for this issue in cpanfile-style, e.g.:\n"
                         . "> 1.0.2, <= 2.3.1, != 2.1.7\n"
                         . "Do NOT provide an upper bound for unfixed issues."
                );
            try { CPAN::Meta::Requirements->from_string_hash({ $valid_dist => $v_range }); $version_range = $v_range }
            catch ($e) { warn $e };
        }
        # TODO: check MetaCPAN/BackPAN if given versions are valid
        if (CPANSEC::Admin::Util::prompt('Ready to commit your changes? (y/n)', 'y', 'n') eq 'y') {
            $data->{approved} = 'true';
            return true;
        }
        return false;
    }

    method add_to_ignored ($file, $msg_index) {
        my $ignored = Path::Tiny::path($options{triage_dir}, 'false_positives');
        my $fh = $ignored->opena_raw;
        say $fh $file->basename('.yml') . '    # ' . $rejection_criteria{$msg_index};
        $file->remove;
    }
}

__END__

=head1 NAME

CPANSEC::Admin::Command::Triage - Approve/Reject advisories from triage

=head1 SYNOPSIS

    cpansec-admin triage  [--triage-dir=<path>]  [-a | --all] [<filepath>...]

=head1 DESCRIPTION

This command allows you to easily inspect one or more items on the triage
folder, to approve them as actual CPANSEC advisories or reject the candidate.

=head1 ARGUMENTS

    -a, --all                 Inspect the entire triage folder. Alternatively,
                              you may inspect a single candidate by passing
                              its filename.

    --triage-dir=<path>       Use a custom path for the triage (destination)
                              folder. Defaults to "./triage". Can also be set
                              via the CPANSEC_TRIAGE_DIR environment variable.
                              This option is ignored when you pass specific
                              file paths instead of --all.