package Complete::MAC;

our $DATE = '2016-10-18'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::Any::IfLOG '$log';

use Complete::Common qw(:all);

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
                       complete_known_mac
               );

our $COMPLETE_MAC_TRACE = $ENV{COMPLETE_MAC_TRACE} // 0;

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Completion routines related to MAC addresses',
};

$SPEC{'complete_known_mac'} = {
    v => 1.1,
    summary => 'Complete a known hostname',
    description => <<'_',

Complete from a list of "known" MAC addresses.

Known MAC addresses will be searched from: ifconfig output, ARP cache,
`/etc/ethers`.

_
    args => {
        %arg_word,
    },
    result_naked => 1,
    result => {
        schema => 'array',
    },
};
sub complete_known_mac {
    my %args = @_;

    my %macs;

    # from ifconfig output (TODO: alternatively from "ip link show")
    {
        require IPC::System::Options;
        for my $prog ("/sbin/ifconfig") {
            next unless -x $prog;
            $log->tracef("[compmac] Checking %s output", $prog) if $COMPLETE_MAC_TRACE;
            my @lines = IPC::System::Options::readpipe(
                {lang=>"C"}, "$prog -a");
            next if $?;
            for my $line (@lines) {
                if ($line =~ /\bHWaddr\s+(\S+)/) {
                    $log->tracef("[compmac]   Adding %s", $1) if $COMPLETE_MAC_TRACE;
                    $macs{$1}++;
                }
            }
            last;
        }
    }

    # from ARP cache (TODO: alternatively from "ip neigh show")
    {
        $log->tracef("[compmac] Checking arp -an output") if $COMPLETE_MAC_TRACE;
        require IPC::System::Options;
      PROG:
        for my $prog ("/usr/sbin/arp") {
            next unless -x $prog;
            my @lines = IPC::System::Options::readpipe(
                {lang=>"C"}, "$prog -an");
            next if $?;
            for my $line (@lines) {
                if ($line =~ / at (\S+) \[ether\]/) {
                    $log->tracef("[compmac]   Adding %s", $1) if $COMPLETE_MAC_TRACE;
                    $macs{$1}++;
                }
            }
            last PROG;
        }
    }

    # TODO: from /etc/ethers

    require Complete::Util;
    Complete::Util::complete_hash_key(word => $args{word}, hash=>\%macs);
}

1;
# ABSTRACT: Completion routines related to MAC addresses

__END__

=pod

=encoding UTF-8

=head1 NAME

Complete::MAC - Completion routines related to MAC addresses

=head1 VERSION

This document describes version 0.001 of Complete::MAC (from Perl distribution Complete-MAC), released on 2016-10-18.

=for Pod::Coverage .+

=head1 FUNCTIONS


=head2 complete_known_mac(%args) -> array

Complete a known hostname.

Complete from a list of "known" MAC addresses.

Known MAC addresses will be searched from: ifconfig output, ARP cache,
C</etc/ethers>.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<word>* => I<str> (default: "")

Word to complete.

=back

Return value:  (array)

=head1 ENVIRONMENT

=head2 COMPLETE_MAC_TRACE => bool

If set to true, will display more log statements for debugging.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Complete-MAC>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Complete-MAC>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Complete-MAC>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Complete>

Other C<Complete::*> modules.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
