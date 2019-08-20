package DNS::Zone::PowerDNS::To::BIND;

our $DATE = '2019-08-19'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

use Exporter 'import';
our @EXPORT_OK = qw(
                       gen_bind_zone_from_powerdns_db
               );

our %SPEC;

# XXX
sub _encode_txt {
    my $text = shift;
    qq("$text");
}

$SPEC{gen_bind_zone_from_powerdns_db} = {
    v => 1.1,
    summary => 'Generate BIND zone configuration from '.
        'information in PowerDNS database',
    args => {
        db_dsn => {
            schema => 'str*',
            tags => ['category:database'],
            default => 'DBI:mysql:database=pdns',
        },
        db_user => {
            schema => 'str*',
            tags => ['category:database'],
        },
        db_password => {
            schema => 'str*',
            tags => ['category:database'],
        },
        domain => {
            schema => ['net::hostname*'], # XXX domainname
            req => 1,
            pos => 0,
        },
        master_host => {
            schema => ['net::hostname*'],
            req => 1,
            pos => 1,
        },
    },
    result_naked => 1,
};
sub gen_bind_zone_from_powerdns_db {
    my %args = @_;
    my $domain = $args{domain};

    require DBIx::Connect::Any;
    my $dbh = DBIx::Connect::Any->connect(
        $args{db_dsn}, $args{db_user}, $args{db_password}, {RaiseError=>1});

    my $sth_sel_domain = $dbh->prepare("SELECT * FROM domains WHERE name=?");
    $sth_sel_domain->execute($domain);
    my $domain_rec = $sth_sel_domain->fetchrow_hashref
        or die "No such domain in the database: '$domain'";

    my @res;
    push @res, '; generated from PowerDNS database on '.scalar(gmtime)." UTC\n";

    my $sth_sel_soa_record = $dbh->prepare("SELECT * FROM records WHERE domain_id=? AND disabled=0 AND type='SOA'");
    $sth_sel_soa_record->execute($domain_rec->{id});
    my $soa_rec = $sth_sel_soa_record->fetchrow_hashref
        or die "Domain '$domain' does not have SOA record";
    push @res, '$TTL ', $soa_rec->{ttl}, "\n";
    $soa_rec->{content} =~ s/(\S+)(\s+)(\S+)(\s+)(.+)/$1.$2$3.$4($5)/;
    push @res, "\@ IN $soa_rec->{ttl} SOA $soa_rec->{content};\n";

    my $sth_sel_record = $dbh->prepare("SELECT * FROM records WHERE domain_id=? AND disabled=0 ORDER BY id");
    $sth_sel_record->execute($domain_rec->{id});
    while (my $rec = $sth_sel_record->fetchrow_hashref) {
        my $type = $rec->{type};
        next if $type eq 'SOA';
        my $name = $rec->{name};
        $name =~ s/\.?\Q$domain\E\z//;
        push @res, "$name ", ($rec->{ttl} ? "$rec->{ttl} ":""), "IN ";
        if ($type eq 'A') {
            push @res, "A $rec->{content}\n";
        } elsif ($type eq 'CNAME') {
            push @res, "CNAME $rec->{content}.\n";
        } elsif ($type eq 'MX') {
            push @res, "MX $rec->{prio} $rec->{content}.\n";
        } elsif ($type eq 'NS') {
            push @res, "NS $rec->{content}.\n";
        } elsif ($type eq 'TXT') {
            push @res, "TXT ", _encode_txt($rec->{content}), "\n";
        } else {
            die "Can't dump record with type $type";
        }
    }

    join "", @res;
}

1;
# ABSTRACT: Generate BIND zone configuration from information in PowerDNS database

__END__

=pod

=encoding UTF-8

=head1 NAME

DNS::Zone::PowerDNS::To::BIND - Generate BIND zone configuration from information in PowerDNS database

=head1 VERSION

This document describes version 0.001 of DNS::Zone::PowerDNS::To::BIND (from Perl distribution DNS-Zone-PowerDNS-To-BIND), released on 2019-08-19.

=head1 SYNOPSIS

 use DNS::Zone::PowerDNS::To::BIND qw(gen_bind_zone_from_powerdns_db);

 say gen_bind_zone_from_powerdns_db(
     db_dsn => 'dbi:mysql:database=pdns',
     domain => 'example.com',
     master_host => 'dns1.example.com',
 );

will output something like:

 $TTL 300
 @ IN 300 SOA ns1.example.com. hostmaster.example.org. (
   2019072401 ;serial
   7200 ;refresh
   1800 ;retry
   12009600 ;expire
   300 ;ttl
   )
  IN NS ns1.example.com.
  IN NS ns2.example.com.
  IN A 1.2.3.4
 www IN CNAME @

=head1 FUNCTIONS


=head2 gen_bind_zone_from_powerdns_db

Usage:

 gen_bind_zone_from_powerdns_db(%args) -> any

Generate BIND zone configuration from information in PowerDNS database.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<db_dsn> => I<str> (default: "DBI:mysql:database=pdns")

=item * B<db_password> => I<str>

=item * B<db_user> => I<str>

=item * B<domain>* => I<net::hostname>

=item * B<master_host>* => I<net::hostname>

=back

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/DNS-Zone-PowerDNS-To-BIND>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-DNS-Zone-PowerDNS-To-BIND>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=DNS-Zone-PowerDNS-To-BIND>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Sah::Schemas::DNS>

L<DNS::Zone::Struct::To::BIND>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
