package App::Spanel::BuildBindZonesFromPowerDNSDB;

our $DATE = '2019-08-29'; # DATE
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

use DNS::Zone::PowerDNS::To::BIND qw(gen_bind_zone_from_powerdns_db);

my $gbzfpd_meta = $DNS::Zone::PowerDNS::To::BIND::SPEC{gen_bind_zone_from_powerdns_db};
my %args_common = (
    %{ $gbzfpd_meta->{args} },
);
delete $args_common{domain};
delete $args_common{dbh};
delete $args_common{master_host};

our %SPEC;

$SPEC{build_bind_zones} = {
    v => 1.1,
    summary => 'Build BIND zones from PowerDNS zones in database',
    description => <<'_',

This script will export domains in your PowerDNS database as BIND zones then
write them to the current directory with names <servername>/db.<domainname> (so
`example.com` from `server123` will be written to `./server123/db.example.com`).

Will not override existing files unless `--overwrite` (`-O`) is specified.

You can select domains to export using `include-domain` option.

_
    args => {
        %args_common,
        overwrite => {
            summary => 'Whether to overwrite existing output files',
            schema => 'bool*',
            cmdline_aliases => {O=>{}},
        },
        include_domains => {
            'x.name.is_plural' => 1,
            'x.name.singular' => 'include_domain',
            schema => ['array*', of=>'net::hostname*'],
            tags => ['category:filtering'],
        },
        include_servers => {
            'x.name.is_plural' => 1,
            'x.name.singular' => 'include_server',
            schema => ['array*', of=>'net::hostname*'],
            tags => ['category:filtering'],
        },
        exclude_servers => {
            'x.name.is_plural' => 1,
            'x.name.singular' => 'exclude_server',
            schema => ['array*', of=>'net::hostname*'],
            tags => ['category:filtering'],
        },
    },
    args_rels => {
    },
};
sub build_bind_zones {
    my %args = @_;

    my $overwrite = delete $args{overwrite};

    require DBIx::Connect::Any;
    my $dbh = DBIx::Connect::Any->connect(
        delete $args{db_dsn}, delete $args{db_user}, delete $args{db_password}, {RaiseError=>1});

    my $sql_sel_domain = "SELECT id,name,account FROM domains";
    my @wheres;
    my @binds;
    if (my $include_domains = delete $args{include_domains}) {
        push @wheres, "name IN (".
            join(",", ("?") x @$include_domains).")";
        push @binds , @$include_domains;
    }
    if (my $include_servers = delete $args{include_servers}) {
        for my $server (@$include_servers) {
            push @wheres, "account LIKE ?";
            push @binds , "s${server};%";
        }
    }
    if (my $exclude_servers = delete $args{exclude_servers}) {
        for my $server (@$exclude_servers) {
            push @wheres, "account NOT LIKE ?";
            push @binds , "s${server};%";
        }
    }
    $sql_sel_domain .= " WHERE ".join(" AND ", @wheres) if @wheres;
    $sql_sel_domain .= " ORDER BY name";

    # collect all the domains first
    log_trace "Selecting domains from database ...";
    my $sth_sel_domain = $dbh->prepare($sql_sel_domain);
    $sth_sel_domain->execute(@binds);
    my @records;
    while (my $record = $sth_sel_domain->fetchrow_hashref) {
        push @records, $record;
    }
    log_trace "Found %d domain(s)", scalar(@records);

    #eval {
    #    local @INC = @INC;
    #    push @INC, "/c/lib/perl";
    #    push @INC, "/c/lib/perl/cpan";
    #    require Spanel::Utils;
    #    Spanel::Utils::load_config();
    #    #Spanel::Utils::load_servers_config();
    #};
    #if ($@) {
    #    log_info "Cannot load server config: $@";
    #}

    for my $i (0..$#records) {
        my $record = $records[$i];
        log_info "[%d/%d] Processing domain %s ...",
            $i+1, scalar(@records), $record->{name};

        $record->{account} =~ /^s([^;]+);p([^;]+)/ or do {
            log_warn "Domain '$record->{name}' (ID $record->{id}): Warning: cannot extract metadata from 'account' field, setting server=UNKNOWN, priority=0";
        };
        my ($server, $priority) = ($1 // "UNKNOWN", $2 // 0);

        my $bind_zone;
        eval {
            $bind_zone = gen_bind_zone_from_powerdns_db(
                dbh => $dbh,
                domain_id => $record->{id},
                master_host => $record->{name},
                %args,
            );
        };
        if ($@) {
            log_warn "Domain '$record->{name}' (ID $record->{id}): Cannot generate BIND zone: $@, skipping domain";
            next;
        }

        my $output_dir = "spanel-server.$server.d";
        unless (-d $output_dir) {
            mkdir $output_dir or do {
                log_warn "Domain '$record->{name}' (ID $record->{id}): Cannot mkdir $output_dir: skipping domain";
                next;
            };
        }
        my $output_file = "$output_dir/db.$record->{name}";
        if (-f $output_file) {
            unless ($overwrite) {
                log_info "Domain '$record->{name}' (ID $record->{id}): Output file $output_file already exists (and we're not overwriting), skipping domain";
                next;
            }
        }

      INSERT_METADATA:
        {
            my $meta = "; meta: server=$server; priority=$priority";
            $bind_zone =~ s/(\$TTL)/$meta\n$1/ or do {
                log_warn "Domain '$record->{name}' (ID $record->{id}): Warning: cannot insert meta '$meta'";
            };
        }

        open my $fh, ">", $output_file or do {
            log_warn "Domain '$record->{name}' (ID $record->{id}): Cannot open $output_file: $!, skipping domain";
            next;
        };

        print $fh $bind_zone;
        close $fh;
        log_debug "Domain '$record->{name}' (ID $record->{id}): Wrote $output_file";
    } # for domain

    [200];
}


1;
# ABSTRACT: Build BIND zones from PowerDNS zones in database

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Spanel::BuildBindZonesFromPowerDNSDB - Build BIND zones from PowerDNS zones in database

=head1 VERSION

This document describes version 0.002 of App::Spanel::BuildBindZonesFromPowerDNSDB (from Perl distribution App-Spanel-BuildBindZonesFromPowerDNSDB), released on 2019-08-29.

=head1 SYNOPSIS

See the included L<spanel-build-bind-zones> script.

=head1 FUNCTIONS


=head2 build_bind_zones

Usage:

 build_bind_zones(%args) -> [status, msg, payload, meta]

Build BIND zones from PowerDNS zones in database.

This script will export domains in your PowerDNS database as BIND zones then
write them to the current directory with names <servername>/db.<domainname> (so
C<example.com> from C<server123> will be written to C<./server123/db.example.com>).

Will not override existing files unless C<--overwrite> (C<-O>) is specified.

You can select domains to export using C<include-domain> option.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<db_dsn> => I<str> (default: "DBI:mysql:database=pdns")

=item * B<db_password> => I<str>

=item * B<db_user> => I<str>

=item * B<default_ns> => I<array[net::hostname]>

=item * B<domain_id> => I<uint>

=item * B<exclude_servers> => I<array[net::hostname]>

=item * B<include_domains> => I<array[net::hostname]>

=item * B<include_servers> => I<array[net::hostname]>

=item * B<overwrite> => I<bool>

Whether to overwrite existing output files.

=item * B<workaround_cname_and_other_data> => I<bool> (default: 1)

Whether to avoid having CNAME record for a name as well as other record types.

This is a workaround for a common misconfiguration in PowerDNS DB. Bind will
reject the whole zone if there is CNAME record for a name (e.g. 'www') as well
as other record types (e.g. 'A' or 'TXT'). The workaround is to skip those A/TXT
records and only keep the CNAME record.

=item * B<workaround_no_ns> => I<bool> (default: 1)

Whether to add some NS records for '' when there are no NS records for it.

This is a workaround for a common misconfiguration in PowerDNS DB. This will add
some NS records specified in C<default_ns>.

=item * B<workaround_root_cname> => I<bool> (default: 1)

Whether to avoid having CNAME record for a name as well as other record types.

CNAME on a root node (host='') does not make sense, so the workaround is to
ignore the root CNAME.

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

Please visit the project's homepage at L<https://metacpan.org/release/App-Spanel-BuildBindZonesFromPowerDNSDB>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-Spanel-BuildBindZonesFromPowerDNSDB>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-Spanel-BuildBindZonesFromPowerDNSDB>

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
