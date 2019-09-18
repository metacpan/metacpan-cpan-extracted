package DNS::Zone::Struct::Common::BIND;

our $DATE = '2019-09-17'; # DATE
our $VERSION = '0.004'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

use Exporter 'import';
our @EXPORT_OK = qw(
               );

our %arg_workaround_root_cname = (
    workaround_root_cname => {
        summary => "Whether to avoid having CNAME record for a name as well as other record types",
        description => <<'_',

CNAME on a root node (host='') does not make sense, so the workaround is to
ignore the root CNAME.

_
        schema => 'bool*',
        default => 1,
        tags => ['category:workaround'],
    },
);

sub _workaround_root_cname {
    my $recs = shift;

    my @orig_recs = @$recs;
    splice @$recs, 0;
    for (@orig_recs) {
        if ($_->{type} eq 'CNAME' && $_->{name} eq '') {
            log_warn "There is a CNAME record for host '', assuming misconfiguration, adding workaround: skipping this CNAME record (%s)", $_;
            next;
        }
        push @$recs, $_;
    }
}

our %arg_workaround_cname_and_other_data = (
    workaround_cname_and_other_data => {
        summary => "Whether to avoid having CNAME record for a name as well as other record types",
        description => <<'_',

This is a workaround for a common misconfiguration. Bind will reject the whole
zone if there is CNAME record for a name (e.g. 'www') as well as other record
types (e.g. 'A' or 'TXT'). The workaround is to skip those A/TXT records and
only keep the CNAME record.

_
        schema => 'bool*',
        default => 1,
        tags => ['category:workaround'],
    },
);

sub _workaround_cname_and_other_data {
    my $recs = shift;

    my %cname_for; # key=host(name)
    for (@$recs) {
        next unless $_->{type} eq 'CNAME';
        $cname_for{ $_->{name} }++;
    }

    my @orig_recs = @$recs;
    splice @$recs, 0;
    for (@orig_recs) {
        goto PASS if $_->{type} eq 'CNAME';
        if ($cname_for{ $_->{name} }) {
            log_warn "There is a CNAME for name=%s as well as %s record, assuming misconfiguration, adding workaround: skipping the %s record (%s)",
                $_->{name}, $_->{type}, $_->{type}, $_;
            next;
        }
      PASS:
        push @$recs, $_;
    }
}

our %arg_workaround_no_ns = (
    workaround_no_ns => {
        summary => "Whether to add some NS records for '' when there are no NS records for it",
        description => <<'_',

This is a workaround for a common misconfiguration in PowerDNS DB. This will add
some NS records specified in `default_ns`.

_
        schema => 'bool*',
        default => 1,
        tags => ['category:workaround'],
    },
    default_ns => {
        schema => ['array*', of=>'net::hostname*'],
    },
);

sub _workaround_no_ns {
    my ($recs, $default_ns) = @_;

    my $has_ns_record_for_domain;
    for (@$recs) {
        if ($_->{type} eq 'NS' && $_->{name} eq '') { $has_ns_record_for_domain++; last }
    }

    return if $has_ns_record_for_domain;

    die "Please specify one or more default NS (`default_ns`) for --workaround-no-ns"
        unless $default_ns && @$default_ns;

    log_warn "There are no NS records for host '', assuming misconfiguration, adding workaround: some default NS: %s", $default_ns;
    for my $ns (@$default_ns) {
        push @$recs, {type=>'NS', name=>'', content=>$ns};
    }
}

# bind requires the records in a specific order
sub _sort_records {
    my $recs = shift;

    my @sorted_recs = sort {
        my $cmp;

        # sorting by host

        # root (host='') node first
        my $a_is_root = $a->{name} eq '' ? 0 : 1;
        my $b_is_root = $b->{name} eq '' ? 0 : 1;
        return $cmp if $cmp = $a_is_root <=> $b_is_root;

        # wildcard last
        my $a_has_wildcard = $a->{name} =~ /\*/ ? 1 : 0;
        my $b_has_wildcard = $b->{name} =~ /\*/ ? 1 : 0;
        return $cmp if $cmp = $a_has_wildcard <=> $b_has_wildcard;

        # sort by host
        return $cmp if $cmp = $a->{name} cmp $b->{name};

        # just to be nice: sort by record type: SOA first, then NS, then A, then
        # MX, then the rest
        my $a_type = $a->{type} eq 'SOA' ? 0 : $a->{type} eq 'NS' ? 1 : $a->{type} eq 'A' ? 2 : $a->{type} eq 'MX' ? 3 : $a->{type};
        my $b_type = $b->{type} eq 'SOA' ? 0 : $b->{type} eq 'NS' ? 1 : $b->{type} eq 'A' ? 2 : $b->{type} eq 'MX' ? 3 : $b->{type};
        return $cmp if $cmp = $a_type cmp $b_type;

        0;
    } @$recs;

    splice @$recs, 0, scalar(@$recs), @sorted_recs;
}

1;
# ABSTRACT: BIND-related DNS zone routines

__END__

=pod

=encoding UTF-8

=head1 NAME

DNS::Zone::Struct::Common::BIND - BIND-related DNS zone routines

=head1 VERSION

This document describes version 0.004 of DNS::Zone::Struct::Common::BIND (from Perl distribution DNS-Zone-Struct-Common), released on 2019-09-17.

=head1 SYNOPSIS

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/DNS-Zone-Struct-Common>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-DNS-Zone-Struct-Common>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=DNS-Zone-Struct-Common>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
