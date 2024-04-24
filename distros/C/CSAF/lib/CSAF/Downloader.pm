package CSAF::Downloader;

use 5.010001;
use strict;
use warnings;
use utf8;

use CSAF::Options::Downloader;
use CSAF::Util qw(file_read gpg_verify);
use CSAF;

use Cpanel::JSON::XS;
use File::Basename;
use File::Path            qw(make_path);
use File::Spec::Functions qw(catfile);
use LWP::UserAgent;
use Parallel::ForkManager;
use URI::URL;

use Moo;
with 'CSAF::Util::Log';

has options => (
    isa   => sub { Carp::croak 'Invalid configurator' unless ref($_[0]) eq 'CSAF::Options::Downloader' },
    is    => 'lazy',
    build => 1,
);

sub _build_options { CSAF::Options::Downloader->new }


sub ua {

    my $self = shift;

    my $ua = LWP::UserAgent->new(
        ssl_opts          => {verify_hostname => ($self->options->insecure ? !!0 : !!1)},
        agent             => sprintf('CSAF/%s', $CSAF::VERSION),
        protocols_allowed => ['http', 'https']
    );

    $ua->add_handler(
        'request_send' => sub {
            $self->log->trace('[HTTP Request]', $_[0]->method, $_[0]->uri);
            return;
        }
    );

    $ua->add_handler(
        'response_done' => sub {
            $self->log->trace('[HTTP Response]', $_[0]->status_line);
            return;
        }
    );

    return $ua;

}

sub mirror {

    my ($self, $url) = @_;

    my $is_provider_metadata = 0;
    my $is_index_txt         = 0;
    my $is_rolie_feed        = 0;
    my $is_base_url          = 0;

    $is_index_txt         = 1 if ($url =~ /\/index\.txt$/);
    $is_provider_metadata = 1 if ($url =~ /\/provider-metadata\.json$/);

    my $ua  = $self->ua;
    my $log = $self->log;

    $log->info("Check: $url");

    if (my $res = $ua->head($url)) {
        if (!$res->is_success) {
            $log->error($res->status_line);
            Carp::croak $res->message;
        }
    }

    $log->info('Include pattern =>', $self->options->include_pattern) if $self->options->include_pattern;
    $log->info('Exclude pattern =>', $self->options->exclude_pattern) if $self->options->exclude_pattern;

    my $base_url = $url;
    $base_url =~ s/\/index\.txt$//;
    $base_url =~ s/\/provider-metadata\.json$//;

    return $self->_mirror_via_index_txt($base_url)         if ($is_index_txt);
    return $self->_mirror_via_provider_metadata($base_url) if ($is_provider_metadata);

    return $self->_mirror_via_rolie_feed($url);

}

sub _mirror_via_rolie_feed {

    my ($self, $url) = @_;

    my $ua  = $self->ua;
    my $log = $self->log;

    my $res = $ua->get($url);

    if (!$res->is_success) {
        $log->error($res->status_line);
        Carp::croak $res->message;
    }

    my $rolie = eval { Cpanel::JSON::XS->new->decode($res->content) };

    my $idx = 0;
    my $pm  = Parallel::ForkManager->new($self->options->parallel_downloads);

ENTRY:
    foreach my $entry (@{$rolie->{feed}->{entry}}) {

        my $options  = {signature => 0, integrity => {sha256 => 0, sha512 => 0}};
        my $csaf_url = undef;

        foreach my $link (@{$entry->{link}}) {

            $options->{signature} = 1 if ($link->{rel} eq 'signature');

            $options->{integrity}->{sha256} = 1 if ($link->{rel} eq 'hash' & $link->{href} =~ /sha256/);
            $options->{integrity}->{sha512} = 1 if ($link->{rel} eq 'hash' & $link->{href} =~ /sha512/);

            $csaf_url = $link->{href} if ($link->{rel} eq 'self');

        }

        $idx++;

        $pm->start and next ENTRY;

        my $csaf_file = catfile($self->options->directory, URI::URL->new($csaf_url)->path);

        $log->debug("[#$idx] Download CSAF document: $csaf_url => $csaf_file");
        $self->_download_csaf_document($csaf_url, $csaf_file, $options);

        $pm->finish;

    }

    $pm->wait_all_children;

}

sub _mirror_via_provider_metadata {

    my ($self, $base_url) = @_;

    my $ua  = $self->ua;
    my $log = $self->log;

    my $provider_metadata_file = catfile($self->options->directory, 'provider-metadata.json');

    $log->debug("Download: $base_url/provider-metadata.json => $provider_metadata_file");
    $ua->mirror("$base_url/provider-metadata.json", $provider_metadata_file);

    my $provider_metadata = eval { Cpanel::JSON::XS->new->decode(file_read($provider_metadata_file)) };

    foreach my $distribution (@{$provider_metadata->{distributions}}) {

        if (defined $distribution->{directory_url}) {
            $self->_mirror_via_index_txt($distribution->{directory_url});
        }

    }

}

sub _mirror_via_index_txt {

    my ($self, $base_url) = @_;

    $base_url =~ s{/$}{};

    my $ua  = $self->ua;
    my $log = $self->log;

    my $base_dir = catfile($self->options->directory, URI::URL->new($base_url)->path);
    make_path($base_dir) unless -e $base_dir;

    my $index_file             = catfile($base_dir, 'index.txt');
    my $changes_file           = catfile($base_dir, 'changes.csv');
    my $provider_metadata_file = catfile($base_dir, 'provider-metadata.json');

    $log->debug("Download: $base_url/index.txt => $index_file");
    $ua->mirror("$base_url/index.txt", $index_file);

    $log->debug("Download: $base_url/changes.csv => $changes_file");
    $ua->mirror("$base_url/changes.csv", $changes_file);

    $log->debug("Download: $base_url/provider-metadata.json => $provider_metadata_file");
    $ua->mirror("$base_url/provider-metadata.json", $provider_metadata_file);

    my $content     = file_read($index_file);
    my @files       = split(/\n/, $content);
    my $total_files = scalar @files;

    $log->info("Total $total_files CSAF documents");

    my $idx = 0;
    my $pm  = Parallel::ForkManager->new($self->options->parallel_downloads);

FILES:
    foreach my $file (@files) {

        chomp($file);
        next if $file =~ /^$/;

        if (my $include_pattern = $self->options->include_pattern) {
            next unless $file =~ qr/$include_pattern/;
        }

        if (my $exclude_pattern = $self->options->exclude_pattern) {
            next if $file =~ qr/$exclude_pattern/;
        }

        $idx++;

        $pm->start and next FILES;

        my $csaf_file = catfile($base_dir, $file);
        my $csaf_url  = "$base_url/$file";

        $log->debug("[#$idx] Download CSAF document: $csaf_url => $csaf_file");

        $self->_download_csaf_document($csaf_url, $csaf_file);

        $pm->finish;

    }

    $pm->wait_all_children;

}

sub _download_csaf_document {

    my ($self, $csaf_url, $csaf_file, $options) = @_;

    my $ua  = $self->ua;
    my $log = $self->log;

    $options //= {signature => 1, integrity => {sha256 => 1, sha512 => 1}};

    my $csaf_base_dir = dirname($csaf_file);
    make_path($csaf_base_dir) unless -e $csaf_base_dir;

    if (my $res = $ua->mirror($csaf_url, $csaf_file)) {

        if ($res->code == 200) {

            $log->debug("Download signature and/or integrity files");

            $ua->mirror("$csaf_url.asc", "$csaf_file.asc") if (defined $options->{signature} && $options->{signature});

            if (defined $options->{integrity}) {
                $ua->mirror("$csaf_url.sha256", "$csaf_file.sha256") if ($options->{integrity}->{sha256});
                $ua->mirror("$csaf_url.sha512", "$csaf_file.sha512") if ($options->{integrity}->{sha512});
            }

            $self->_check_document($csaf_file);

        }

    }

}

sub _check_document {

    my ($self, $csaf_file) = @_;

    my $log = $self->log;

    if ($self->options->validate) {

        $log->info("Validate CSAF document");

        my $parser = CSAF::Parser->new(file => $csaf_file);
        my $csaf   = $parser->parse;

        if (my @errors = $csaf->validate($self->options->validate)) {
            $log->error($_) for (@errors);
        }

    }

    if ($self->options->integrity_check) {

        my @algo = (256, 512);

        foreach my $algo (@algo) {
            if (-e "$csaf_file.sha$algo") {

                $log->info("Check integrity of CSAF document ($algo)");

                my $sha = Digest::SHA->new($algo);
                $sha->addfile($csaf_file);
                my $digest = $sha->hexdigest;

                my ($verify) = split /\s+/, file_read("$csaf_file.sha$algo");

                if ($verify eq $digest) {
                    $log->info("Integrity check OK: $algo");
                }
                else {
                    $log->error("Integrity check KO: $algo");
                    Carp::croak "Integrity check failed for '$csaf_file'";
                }

            }
        }

    }

    if ($self->options->signature_check) {

        if (-e "$csaf_file.asc") {

            $log->info("Check signature of CSAF document");

            my $result = gpg_verify(signed => "$csaf_file.asc", file => $csaf_file);

            if ($result->{exit_code} == 0) {
                $log->info("Signature check OK");
                $log->trace($result->{status});
            }
            else {
                $log->error("Signature check FAILED");
                $log->trace($result->{status});
                Carp::croak "Signature check FAILED for '$csaf_file'";
            }

        }

    }

}

1;

__END__

=encoding utf-8

=head1 NAME

CSAF::Downloader - Download CAF document

=head1 SYNOPSIS

    use CSAF::Downloader;

    my $downloader = CSAF->Downloader;
    $downloader->mirror($url);

=head1 DESCRIPTION

L<CSAF::Downloader> allows the download of CSAF documents through C<index.txt>,
C<provider-metadata.json> or a ROLIE feed.

=head2 METHODS

=over

=item CSAF::Downloader>new

=item $downloader->mirror ( $url )

Download all CSAF document using the provided C<$url>.

=item $downloader->options

Change the default options for L<CSAF::Options::Downloader> configurator.

=back

Execute the command

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/giterlizzi/perl-CSAF/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/giterlizzi/perl-CSAF>

    git clone https://github.com/giterlizzi/perl-CSAF.git


=head1 AUTHOR

=over 4

=item * Giuseppe Di Terlizzi <gdt@cpan.org>

=back


=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2023-2024 by Giuseppe Di Terlizzi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
