package App::Spanel::BuildBindZones;

our $DATE = '2019-08-29'; # DATE
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

use File::chdir;
use List::Util qw(max);

our %SPEC;

$SPEC{build_bind_zones} = {
    v => 1.1,
    summary => 'Build BIND zones from YAML zones',
    description => <<'_',

This script will collect all YAML zones from user accounts (/u/*/sysetc/zone=*)
and build BIND zones then write them to the current directory with names db.*
(so /u/foo/sysetc/zone=example.com will become ./db.example.com).

Will not override existing files unless `--overwrite` (`-O`) is specified.

Will skip YAML zones that contain invalid data, e.g. name in record that
contains underscore (`_`), unknown record type, etc.

_
    args => {
        overwrite => {
            summary => 'Whether to overwrite existing output files',
            schema => 'bool*',
            cmdline_aliases => {O=>{}},
        },
    },
};
sub build_bind_zones {
    #require Data::Sah;
    require Data::Transmute;
    require DNS::Zone::Struct::To::BIND;
    require YAML::XS;

    my %args = @_;

    #my $code_validate_domain = Data::Sah::gen_validator(
    #    "net::hostname*",
    #    {return_type=>"str"},
    #);

    eval {
        local @INC = @INC;
        push @INC, "/c/lib/perl";
        push @INC, "/c/lib/perl/cpan";
        require Spanel::Utils;
        Spanel::Utils::load_config();
        Spanel::Utils::load_servers_config();
    };
    if ($@) {
        log_info "Cannot load servers config: $@";
    }

    my $orig_cwd = $CWD;
    local $CWD = "/u";
    for my $user (glob "*") {
        next unless -d $user;
        log_info "Processing user $user ...";
        if (-f "$user/sysetc/migrated") {
            log_info "User $user is migrated, skipping";
            next;
        }
        local $CWD = "$user/sysetc";
        for my $yaml_file (glob "zone=*") {
            # skip backup files
            next if $yaml_file =~ /~$/;

            log_info "Processing file $yaml_file ...";
            my ($domain) = $yaml_file =~ /^zone=(.+)/;
            #if (my $err = $code_validate_domain->($domain)) {
            #    log_warn "$domain is not a valid hostname, skipping file $yaml_file";
            #    next;
            #}

            my $output_file = "$orig_cwd/db.$domain";
            if (-f $output_file) {
                unless ($args{overwrite}) {
                    log_info "$yaml_file: Output file $output_file already exists (and we're not overwriting), skipped";
                    next;
                }
            }

            my $spanel_struct_zone;
            eval { $spanel_struct_zone = YAML::XS::LoadFile($yaml_file) };
            if ($@) {
                log_warn "$yaml_file cannot be loaded: $@, skipped";
                next;
            }

            # replace ^serverXXX in 'address' fields with the server's actual IP addresses
            for my $rec (@{ $spanel_struct_zone->{records} }) {
                next unless $rec->{address} && $rec->{address} =~ /^\^(.+)/;
                my $servername = $1;
                if    ($main::SPANEL_SERVERS->{$servername}) { $rec->{address} = $main::SPANEL_SERVERS->{$servername}{config}{local}{ip}[0] }
                elsif ($main::CPANEL_SERVERS->{$servername}) { $rec->{address} = $main::CPANEL_SERVERS->{$servername}{config}{local}{ip}[0] }
                elsif ($main::PLESK_SERVERS ->{$servername}) { $rec->{address} = $main::PLESK_SERVERS ->{$servername}{config}{local}{ip}[0] }
                else { log_warn "$yaml_file: Unknown server '$servername' mentioned in DNS records, using 0.0.0.0"; $rec->{address} = "0.0.0.0" }
            }

            my $struct_zone;
            eval {
                $struct_zone = Data::Transmute::transmute_data(
                    data => $spanel_struct_zone,
                    rules_module => "DNS::Zone::Struct::FromSpanel",
                );
            };
            if ($@) {
                log_warn "$yaml_file: cannot transmute data: $@, skipped";
                next;
            }

            my $bind_zone;
            eval {
                $bind_zone = DNS::Zone::Struct::To::BIND::gen_bind_zone_from_struct(
                    zone => $struct_zone,
                    master_host => $domain,
                );
            };
            if ($@) {
                log_warn "$yaml_file: cannot generate BIND zone: $@, skipped";
                next;
            }

            # insert header
            $bind_zone = join(
                "",
                "; This BIND zone is generated from YAML zone $yaml_file\n",
                "; on ", scalar(gmtime), " UTC by $0\n",
                $bind_zone);

            # insert metadata
            if ($main::SPANEL_CONFIG) {
                my $server_priority = $main::SPANEL_CONFIG->{dns}{zones_priority} // 0;
                my $zone_priority   = $struct_zone->{priority} // 0;
                my $priority = max($server_priority, $zone_priority);

                my $meta = "; meta: server=$main::SPANEL_CONFIG->{local}{id}; priority=$priority";
                $bind_zone =~ s/(\$TTL)/$meta\n$1/ or do {
                    log_warn "$yaml_file: Warning: cannot insert meta '$meta'";
                };
            }

            open my $fh, ">", $output_file or do {
                log_warn "$yaml_file: Cannot open $output_file: $!, skipped";
                next;
            };

            print $fh $bind_zone;
            close $fh;
            log_debug "$yaml_file: wrote $output_file";
        } # for zone=* file
    } # for user

    [200];
}


1;
# ABSTRACT: Build BIND zones from YAML zones

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Spanel::BuildBindZones - Build BIND zones from YAML zones

=head1 VERSION

This document describes version 0.002 of App::Spanel::BuildBindZones (from Perl distribution App-Spanel-BuildBindZones), released on 2019-08-29.

=head1 SYNOPSIS

See the included L<spanel-build-bind-zones> script.

=head1 FUNCTIONS


=head2 build_bind_zones

Usage:

 build_bind_zones(%args) -> [status, msg, payload, meta]

Build BIND zones from YAML zones.

This script will collect all YAML zones from user accounts (/u/I</sysetc/zone=>)
and build BIND zones then write them to the current directory with names db.*
(so /u/foo/sysetc/zone=example.com will become ./db.example.com).

Will not override existing files unless C<--overwrite> (C<-O>) is specified.

Will skip YAML zones that contain invalid data, e.g. name in record that
contains underscore (C<_>), unknown record type, etc.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<overwrite> => I<bool>

Whether to overwrite existing output files.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-Spanel-BuildBindZones>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-Spanel-BuildBindZones>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-Spanel-BuildBindZones>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
