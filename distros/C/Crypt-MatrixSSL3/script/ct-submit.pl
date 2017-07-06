#!/usr/bin/perl
use warnings;
use strict;

use version 0.77 (); our $VERSION = 'v3.9.1';

use Getopt::Long;
use Pod::Usage;
use MIME::Base64;
use LWP::UserAgent;
use JSON;

## no critic (Capitalization, RequireCarping)

# command line variables binds
my @pem;         # certificate list
my $extbuf;      # output ready to use extension data to a file
my $individual;  # write each SCT file in it's own file

GetOptions(
    'help|?' => sub { pod2usage(1); },
    'pem=s' => \@pem,
    'extbuf=s' => \$extbuf,
    'individual=s' => \$individual
) or pod2usage(2);
if (!@pem) {
    pod2usage(-exitval => 0, -verbose => 2)
}

# CT log servers
my %logs = (
    'aviator'   => 'https://ct.googleapis.com/aviator',
    'certly'    => 'https://log.certly.io',
    'pilot'     => 'https://ct.googleapis.com/pilot',
    'rocketeer' => 'https://ct.googleapis.com/rocketeer',
    #'digicert'  => 'https://ct1.digicert-ct.com/log',
    #'izenpe'    => 'https://ct.izenpe.com',
    'symantec'  => 'https://ct.ws.symantec.com',
    'venafi'    => 'https://ctlog.api.venafi.com',
    'vega'      => 'https://vega.ws.symantec.com',
);

@pem = split /,/ms, join q{,}, @pem;

my @chain;
my @cert;
my @sct;

write_log('ct-submit Start');

foreach my $pem (@pem) {
    write_log("Reading certificate $pem");
    open my $fh, '<', $pem or die "Cannot open $pem: $@"; ## no critic (RequireBriefOpen)
    while (my $line = <$fh>) {
        chomp $line;
        next if $line eq q{};
        if ($line =~ /\-+begin certificate\-+/msi) {
            @cert = ();
            next;
        }
        if ($line =~ /\-+end certificate\-+/msi) {
            my $b64 = join q{}, @cert;
            push @chain, $b64;
            next;
        }
        push @cert, $line;
    }
    close $fh or die "close: $!";
}

my $json_data = to_json( {'chain' => \@chain } );

while (my ($log_name, $log_url) = each %logs) {
    write_log("\nSending request to $log_url");

    my $ua = LWP::UserAgent->new;
    my $req = HTTP::Request->new('POST', $log_url . '/ct/v1/add-chain', ['Content-Type' => 'application/json'], $json_data);
    my $res = $ua->request($req);

    if (!$res->is_success) {
        write_log('Failed: ', $res->status_line, "\n");
        next;
    }

    write_log("Got response from $log_url");
    my $sct = from_json($res->content);

    write_log(
        '  version: ', $sct->{'sct_version'}, "\n",
        '  log ID : ', $sct->{'id'}, "\n",
        '  timestamp: ', $sct->{'timestamp'}, "\n",
        '  extensions: ', $sct->{'extensions'}, "\n",
        '  signature: ', $sct->{'signature'}, "\n"
    );

    my $id = decode_base64($sct->{'id'});
    my $timestamp = $sct->{'timestamp'};
    my $extensions = decode_base64($sct->{'extensions'});
    my $signature = decode_base64($sct->{'signature'});

    my $bsct = pack '(C a32 Q S a' . length($extensions) . ' a' . length($signature) . ')>', 0, $id, $timestamp, length($extensions), $extensions, $signature;

    write_log('SCT (', length($bsct), '): ', encode_base64($bsct));

    push @sct, $bsct;

    if (defined $individual) {
        write_log("Writing $log_name.sct\n");

        open my $fh, '>', "$individual$log_name.sct" or die "Cannot open $log_name.sct for writing";
        binmode $fh;
        print {$fh} $bsct;
        close $fh or die "close: $!";
    }
}

if (defined $extbuf) {
    write_log("Writing ready to use extension data in $extbuf");

    my $size = 0;

    foreach my $sct (@sct) {
        $size += 2 + length $sct;
    }

    open my $fh, '>', $extbuf or die "Cannot open $extbuf for writing";
    binmode $fh;

    foreach my $sct (@sct) {
        print {$fh} pack '(S a' . length($sct) . ')>', length($sct), $sct;
    }

    close $fh or die "close: $!";

    write_log('Done.');
}

# utility subs

sub write_log {
    print @_, "\n";
    return;
}

__END__

=encoding utf8

=for stopwords pem extbuf sct Timestamps

=head1 NAME

ct-submit - Query the Certificate Transparency logs

=head1 SYNOPSIS

ct-submit [options]

    Options:
        --help
        --pem cert1,cert2,...
        --extbuf /path/to/CT.sct
        --individual /path/to/sct/

=head1 OPTIONS

=over 8

=item B<--help>

Show help message

=item B<--pem> certificate.crt

Input certificates. Start with the server certificate and continue to the root. Can be specified multiple times.
Note that the root certificate is not required.

=item B<--extbuf> /path/to/CT.sct

Output file - all responses from log queries will be concatenated into a ready to use extension data.

=item B<--individual> /path/to/sct/

Output folder - all responses from log queries will be save in individual .sct files inside this folder

=back

=head1 DESCRIPTION

Query the Certificate Transparency logs for specified certificates and retrieve Signed Certificate Timestamps.

=cut
