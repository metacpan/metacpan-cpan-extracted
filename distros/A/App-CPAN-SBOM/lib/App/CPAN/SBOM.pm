package App::CPAN::SBOM;

use 5.010001;
use strict;
use warnings;
use utf8;

use CPAN::Audit;
use CPAN::Meta;
use Cpanel::JSON::XS qw(encode_json);
use Data::Dumper;
use File::Basename;
use File::Spec;
use Getopt::Long qw(GetOptionsFromArray :config gnu_compat);
use HTTP::Tiny;
use MetaCPAN::Client;
use MIME::Base64;
use Pod::Usage qw(pod2usage);
use URI::PackageURL;

use SBOM::CycloneDX::Component;
use SBOM::CycloneDX::ExternalReference;
use SBOM::CycloneDX::Hash;
use SBOM::CycloneDX::License;
use SBOM::CycloneDX::Metadata;
use SBOM::CycloneDX::OrganizationalContact;
use SBOM::CycloneDX::Util qw(cpan_meta_to_spdx_license cyclonedx_tool cyclonedx_component);
use SBOM::CycloneDX::Vulnerability::Affect;
use SBOM::CycloneDX::Vulnerability::Rating;
use SBOM::CycloneDX::Vulnerability::Source;
use SBOM::CycloneDX::Vulnerability;
use SBOM::CycloneDX;

our $VERSION = '1.03';


sub DEBUG { $ENV{SBOM_DEBUG} || 0 }

sub cli_error {
    my ($error, $code) = @_;
    $error =~ s/ at .* line \d+.*//;
    say STDERR "ERROR: $error";
    return $code || 1;
}

sub run {

    my (@args) = @_;

    my %options = ();

    GetOptionsFromArray(
        \@args, \%options, qw(
            help|h
            man
            v
            debug|d

            output|o=s

            meta=s
            distribution=s

            maxdepth=i

            vulnerabilities!
            validate!

            project-meta=s
            project-type=s
            project-author=s@
            project-description=s
            project-directory=s
            project-license=s
            project-name=s
            project-version=s

            server-url=s
            api-key=s
            skip-tls-check
            project-id=s
            parent-project-id=s

            cyclonedx-spec-version=s

            list-spdx-licenses
        )
    ) or pod2usage(-verbose => 0);

    pod2usage(-exitstatus => 0, -verbose => 2) if defined $options{man};
    pod2usage(-exitstatus => 0, -verbose => 0) if defined $options{help};

    $options{'project-meta'} //= $options{meta};

    if (defined $options{v}) {
        return show_version();
    }

    if ($options{'list-spdx-licenses'}) {
        say $_ for (sort @{SBOM::CycloneDX::Enum->SPDX_LICENSES});
        return 0;
    }

    unless ($options{distribution} || $options{'project-meta'} || $options{'project-directory'}) {
        pod2usage(-exitstatus => 0, -verbose => 0);
    }

    $options{maxdepth} //= 1;
    $options{validate} //= 1;

    if (defined $options{debug}) {
        $ENV{SBOM_DEBUG} = 1;
    }

    my $bom = SBOM::CycloneDX->new;

    if (defined $options{distribution}) {

        my ($distribution, $version) = split '@', $options{distribution};

        return cli_error('Missing distribution version') unless $version;

        make_sbom_from_dist(bom => $bom, distribution => $distribution, version => $version, options => \%options);
    }

    if (defined $options{'project-directory'} || defined $options{'project-meta'}) {
        make_sbom_from_project(bom => $bom, options => \%options);
    }

    $bom->metadata->tools->push(cyclonedx_tool());

    my $output_file = $options{output} // 'bom.json';

    say STDERR "Save SBOM to $output_file";

    open my $fh, '>', $output_file or Carp::croak "Failed to open file: $!";
    say $fh $bom->to_string;
    close $fh;

    if ($options{validate}) {
        my @errors = $bom->validate;
        say STDERR $_ foreach (@errors);
    }

    if (defined $options{'server-url'} && defined $options{'api-key'}) {
        submit_bom(bom => $bom, options => \%options);
    }

}

sub show_version {

    (my $progname = $0) =~ s/.*\///;

    say <<"VERSION";
$progname version $VERSION

Copyright 2025, Giuseppe Di Terlizzi <gdt\@cpan.org>

This program is part of the "App-CPAN-SBOM" distribution and is free software;
you can redistribute it and/or modify it under the same terms as Perl itself.

Complete documentation for $progname can be found using 'man $progname'
or on the internet at <https://metacpan.org/dist/App-CPAN-SBOM>.
VERSION

    return 0;

}

sub make_sbom_from_project {

    my (%params) = @_;

    my $audit_discover = CPAN::Audit::Discover->new;

    my $bom     = $params{bom};
    my $options = $params{options} || {};

    my @META_FILES = (qw[META.json META.yml MYMETA.json MYMETA.yml]);

    say STDERR 'Generate SBOM';

    my $project_type        = $options->{'project-type'} || 'library';
    my $project_directory   = File::Spec->rel2abs($options->{'project-directory'});
    my $project_meta        = $options->{'project-meta'}    || $options->{'meta'};
    my $project_name        = $options->{'project-name'}    || basename($project_directory);
    my $project_version     = $options->{'project-version'} || 0;
    my $project_description = $options->{'project-description'};
    my $project_license     = $options->{'project-license'};
    my $project_author      = $options->{'project-author'} || [];

    if ($project_directory) {
        return cli_error('Directory not found') unless -d $project_directory;
    }

    unless ($project_meta) {
        foreach (@META_FILES) {
            my $meta_file = File::Spec->catfile($project_directory, $_);
            if (-f $meta_file) {
                $project_meta = $meta_file;
                last;
            }
        }
    }

    my @licenses            = ();
    my @authors             = ();
    my @external_references = ();
    my @dependencies        = ();

    # Use META/MYMETA for populate:
    # - Name
    # - Licenses
    # - Authors
    # - Dependencies

    if ($project_meta) {

        my $meta = CPAN::Meta->load_file($project_meta);

        $project_name    = $meta->name;
        $project_version = $meta->version;

        @authors             = make_authors([$meta->author]);
        @external_references = make_external_references($meta->{resources});
        @licenses            = (SBOM::CycloneDX::License->new(id => cpan_meta_to_spdx_license($meta->license)));

        # Detect distribution author dependencies
        # TODO get the author-defined dependency version

        my $prereqs = $meta->effective_prereqs;
        my $reqs    = $prereqs->requirements_for("runtime", "requires");

        for my $module (sort $reqs->required_modules) {
            next if $module eq 'perl';
            push @dependencies, {module => $module};
        }

    }

    if ($project_license) {
        @licenses = (SBOM::CycloneDX::License->new(id => $project_license));
    }

    if (@{$project_author}) {
        @authors = make_authors($project_author);
    }

    my $bom_ref = "$project_name\@$project_version";
    $bom_ref =~ s/\s+/-/g;

    # Build root BOM component
    my $root_component = SBOM::CycloneDX::Component->new(
        type                => $project_type,
        name                => $project_name,
        version             => $project_version,
        bom_ref             => $bom_ref,
        licenses            => \@licenses,
        authors             => \@authors,
        external_references => \@external_references,
    );

    if ($project_description) {
        $root_component->description($project_description);
    }

    # Add root BOM component in metadata
    $bom->metadata->component($root_component);

    # Find dependencies from "cpanfile.snapshot" or "cpanfile"
    if (my @audit_deps = $audit_discover->discover($project_directory)) {
        @dependencies = @audit_deps;
    }

    foreach my $dependency (@dependencies) {

        make_dep_compoment(
            module           => $dependency->{module},
            dist             => $dependency->{dist},
            version          => $dependency->{version},
            bom              => $bom,
            parent_component => $root_component,
            maxdepth         => $options->{maxdepth}
        );
    }

    return $root_component;

}

sub make_sbom_from_dist {

    my (%params) = @_;

    my $distribution = $params{distribution};
    my $version      = $params{version};
    my $bom          = $params{bom};
    my $options      = $params{options} || {};

    say STDERR "Generate SBOM for $distribution\@$version";

    my $mcpan        = MetaCPAN::Client->new;
    my $release_data = $mcpan->release({all => [{distribution => $distribution}, {version => $version}]});

    my $dist_data = $release_data->next;

    unless ($dist_data) {
        Carp::carp("Unable to find release ($distribution\@$version) in Meta::CPAN");
        return;
    }

    my $metadata = $dist_data->metadata;

    my @authors = make_authors($metadata->{author});

    my $purl = URI::PackageURL->new(
        type      => 'cpan',
        namespace => $dist_data->author,
        name      => $dist_data->distribution,
        version   => $dist_data->version
    );

    my @external_references = make_external_references($dist_data->metadata->{resources});

    my $license      = join ' AND ', @{$metadata->{license}};
    my $spdx_license = cpan_meta_to_spdx_license($license);

    my $bom_license = SBOM::CycloneDX::License->new(($spdx_license) ? {id => $spdx_license} : {name => $license});

    my $root_component = SBOM::CycloneDX::Component->new(
        type                => 'library',
        name                => $dist_data->name,
        version             => $dist_data->version,
        licenses            => [$bom_license],
        authors             => \@authors,
        bom_ref             => $purl->to_string,
        purl                => $purl,
        external_references => \@external_references
    );

    if (my $abstract = $dist_data->abstract) {
        $root_component->description($abstract);
    }

    $bom->metadata->component($root_component);

    if ($options->{vulnerabilities}) {
        make_vulnerabilities(
            bom          => $bom,
            distribution => $dist_data->distribution,
            version      => $dist_data->version,
            bom_ref      => $purl->to_string
        );
    }

    foreach my $dependency (@{$dist_data->dependency}) {
        if ($dependency->{phase} eq 'runtime' and $dependency->{relationship} eq 'requires') {
            next if ($dependency->{module} eq 'perl');

            make_dep_compoment(
                module           => $dependency->{module},
                bom              => $bom,
                parent_component => $root_component,
                maxdepth         => $options->{maxdepth}
            );

        }
    }

    return $root_component;

}

sub make_external_references {

    my $resources = shift;

    my @external_references = ();

    if (defined $resources->{repository} && $resources->{repository}->{url}) {
        my $external_reference
            = SBOM::CycloneDX::ExternalReference->new(type => 'vcs', url => $resources->{repository}->{url});
        push @external_references, $external_reference;
    }

    if (defined $resources->{bugtracker} && $resources->{bugtracker}->{web}) {
        my $external_reference
            = SBOM::CycloneDX::ExternalReference->new(type => 'issue-tracker', url => $resources->{bugtracker}->{web});
        push @external_references, $external_reference;
    }

    return @external_references;

}

sub make_authors {

    my $metadata_authors = shift;

    my @authors = ();

    foreach my $metadata_author (@{$metadata_authors}) {
        if ($metadata_author =~ /(.*) <(.*)>/) {
            my ($name, $email) = $metadata_author =~ /(.*) <(.*)>/;
            push @authors, SBOM::CycloneDX::OrganizationalContact->new(name => $name, email => _clean_email($email));
        }
        elsif ($metadata_author =~ /(.*), (.*)/) {
            my ($name, $email) = $metadata_author =~ /(.*), (.*)/;
            push @authors, SBOM::CycloneDX::OrganizationalContact->new(name => $name, email => _clean_email($email));
        }
        else {
            push @authors, SBOM::CycloneDX::OrganizationalContact->new(name => $metadata_author);
        }
    }

    return @authors;

}

sub _clean_email {

    my $email = shift;

    $email =~ s/E<lt>//;
    $email =~ s/<lt>//;
    $email =~ s/<gt>//;
    $email =~ s/\[at\]/@/;

    return $email;

}

sub make_dep_compoment {

    my (%params) = @_;

    my $distribution     = $params{dist};
    my $module           = $params{module};
    my $version          = $params{version} || 0;
    my $author           = $params{author};
    my $bom              = $params{bom};
    my $parent_component = $params{parent_component};
    my $depth            = $params{depth}     || 1;
    my $maxdepth         = $params{maxdepth}  || 1;
    my $add_vulns        = $params{add_vulns} || 0;

    my $mcpan = MetaCPAN::Client->new;

    if ($module) {

        DEBUG
            and say STDERR sprintf '-- %s[%d] Collect module %s@%s info (parent component %s)',
            ("    " x ($depth - 1)), $depth, $module, $version, $parent_component->bom_ref;

        my $module_data = $mcpan->module($module);

        unless ($module_data) {
            Carp::carp("Unable to find module ($module) in Meta::CPAN");
            return;
        }

        $author //= $module_data->author;

        $distribution = $module_data->distribution;

        if ($version == 0) {
            $version = $module_data->version;
        }

    }

    my $release_data = $mcpan->release({
        either => [
            {all => [{distribution => $distribution}, {version => $version}]},
            {all => [{distribution => $distribution}, {version => "v$version"}]},
        ]
    });

    my $dist_data = $release_data->next;

    DEBUG
        and say STDERR sprintf '-- %s[%d] Collect distribution %s@%s info (parent component %s)',
        ("    " x ($depth - 1)), $depth, $distribution, $version, $parent_component->bom_ref;

    unless ($dist_data) {
        Carp::carp("Unable to find release ($distribution\@$version) in Meta::CPAN");
        return;
    }

    my $metadata = $dist_data->metadata;

    $author //= $dist_data->author;

    my @authors = make_authors($metadata->{author});

    my $license      = join ' AND ', @{$dist_data->metadata->{license}};
    my $spdx_license = cpan_meta_to_spdx_license($license);

    my $bom_license = SBOM::CycloneDX::License->new(($spdx_license) ? {id => $spdx_license} : {name => $license});

    my $purl = URI::PackageURL->new(type => 'cpan', namespace => $author, name => $distribution, version => $version);

    my @ext_refs = make_external_references($dist_data->metadata->{resources});

    my $hashes = SBOM::CycloneDX::List->new;

    if (my $checksum = $dist_data->checksum_sha256) {
        $hashes->add(SBOM::CycloneDX::Hash->new(alg => 'sha-256', content => $checksum));
    }

    if (my $checksum = $dist_data->checksum_md5) {
        $hashes->add(SBOM::CycloneDX::Hash->new(alg => 'md5', content => $checksum));
    }

    my $component = SBOM::CycloneDX::Component->new(
        type                => 'library',
        name                => $distribution,
        version             => $version,
        licenses            => [$bom_license],
        authors             => \@authors,
        bom_ref             => $purl->to_string,
        purl                => $purl,
        hashes              => $hashes,
        external_references => \@ext_refs,
    );

    if (my $abstract = $dist_data->abstract) {
        $component->description($abstract);
    }

    if (!$bom->get_component_by_bom_ref($purl->to_string)) {
        $bom->components->push($component);
    }

    if ($add_vulns) {
        make_vulnerabilities(
            bom          => $bom,
            distribution => $distribution,
            version      => $version,
            bom_ref      => $purl->to_string
        );
    }

    $bom->add_dependency($parent_component, [$component]);

    if ($depth < $maxdepth) {

        $depth++;

        foreach my $dependency (@{$dist_data->dependency}) {
            if ($dependency->{phase} eq 'runtime' and $dependency->{relationship} eq 'requires') {
                next if ($dependency->{module} eq 'perl');
                make_dep_compoment(
                    module           => $dependency->{module},
                    bom              => $bom,
                    parent_component => $component,
                    depth            => $depth
                );
            }
        }

    }

    return $component;

}

sub make_vulnerabilities {

    my (%params) = @_;

    my $bom          = $params{bom};
    my $distribution = $params{distribution};
    my $version      = $params{version};
    my $bom_ref      = $params{bom_ref};

    my $audit = CPAN::Audit->new;

    my $result = $audit->command('dist', $distribution, $version);

    return unless (defined $result->{dists}->{$distribution});

    foreach my $advisory (@{$result->{dists}->{$distribution}->{advisories}}) {

        my $description = $advisory->{description};
        my $severity    = $advisory->{severity} || 'unknown';
        my @cves        = @{$advisory->{cves}};
        my $cpansa      = $advisory->{id};
        my @references  = @{$advisory->{references}};

        foreach my $cve (@cves) {

            my $vulnerability = SBOM::CycloneDX::Vulnerability->new(
                id          => $cve,
                description => $description,
                source      => SBOM::CycloneDX::Vulnerability::Source->new(
                    name => 'NVD',
                    url  => "https://nvd.nist.gov/vuln/detail/$cve"
                ),
                affects => [SBOM::CycloneDX::Vulnerability::Affect->new(ref      => $bom_ref)],
                ratings => [SBOM::CycloneDX::Vulnerability::Rating->new(severity => $severity)]
            );

            $bom->vulnerabilities->add($vulnerability);
        }
    }

}

sub submit_bom {

    my (%params) = @_;

    my $bom     = $params{bom};
    my $options = $params{options} || {};

    $options->{'server-url'}        //= $ENV{DTRACK_URL};
    $options->{'api-key'}           //= $ENV{DTRACK_API_KEY};
    $options->{'project-id'}        //= $ENV{DTRACK_PROJECT_ID};
    $options->{'project-name'}      //= $ENV{DTRACK_PROJECT_NAME};
    $options->{'project-version'}   //= $ENV{DTRACK_PROJECT_VERSION};
    $options->{'parent-project-id'} //= $ENV{DTRACK_PARENT_PROJECT_ID};
    $options->{'skip-tls-check'}    //= $ENV{DTRACK_SKIP_TLS_CHECK};

    my $server_url = $options->{'server-url'};

    my $project_directory = File::Spec->rel2abs($options->{'project-directory'});
    my $project_name      = $options->{'project-name'}    || basename($project_directory);
    my $project_version   = $options->{'project-version'} || 'main';

    my $bom_string = $bom->to_string;

    $server_url =~ s/\/$//;
    $server_url .= '/api/v1/bom';

    my $bom_payload = {autoCreate => 'true', bom => encode_base64($bom_string, '')};

    if (defined $options->{'project-id'}) {
        $bom_payload->{project} = $options->{'project-id'};
    }

    unless (defined $options->{'project-id'}) {

        if ($project_name) {
            $bom_payload->{projectName} = $project_name;
        }

        if ($project_version) {
            $bom_payload->{projectVersion} = $project_version;
        }

    }

    if (defined $options->{'parent-project-id'}) {
        $bom_payload->{parentUUID} = $options->{'parent-project-id'};
    }

    my $verify_ssl = (defined $options->{'skip-tls-check'}) ? 0 : 1;

    my $ua = HTTP::Tiny->new(
        verify_SSL      => $verify_ssl,
        default_headers => {'Content-Type' => 'application/json', 'X-Api-Key' => $options->{'api-key'}}
    );

    say STDERR "Upload BOM in OSWASP Dependency Track ($server_url)";

    my $response = $ua->put($server_url, {content => encode_json($bom_payload)});

    DEBUG and say STDERR "-- Response <-- " . Dumper($response);

    unless ($response->{success}) {
        return cli_error(sprintf(
            'Failed to upload BOM file to OWASP Dependency Track: (%s) %s - %s',
            $response->{status}, $response->{reason}, $response->{content}
        ));
    }

}

1;

__END__

=encoding utf-8

=head1 NAME

App::CPAN::SBOM - CPAN SBOM (Software Bill of Materials) generator

=head1 SYNOPSIS

    use App::CPAN::SBOM qw(run);

    run(\@ARGV);

=head1 DESCRIPTION

L<App::CPAN::SBOM> is a "Command Line Interface" helper module for C<cpan-sbom(1)> command.

=head2 METHODS

=over

=item App::CPAN::SBOM->run(@args)

=back

Execute the command

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/giterlizzi/perl-App-CPAN-SBOM/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/giterlizzi/perl-App-CPAN-SBOM>

    git clone https://github.com/giterlizzi/perl-App-CPAN-SBOM.git


=head1 AUTHOR

=over 4

=item * Giuseppe Di Terlizzi <gdt@cpan.org>

=back


=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2025 by Giuseppe Di Terlizzi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
