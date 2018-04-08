package App::cryp::Masternode::zcoin;

our $DATE = '2018-04-06'; # DATE
our $VERSION = '0.003'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

use IPC::System::Options qw(system);
use JSON::MaybeXS;
use String::ShellQuote;

use Role::Tiny::With;
with 'App::cryp::Role::Masternode';

sub new {
    my ($package, %args) = @_;

    bless \%args, $package;
}

sub list_masternodes {
    my ($self, %args) = @_;

    my $crypconf = $args{-cmdline_r}{_cryp};
    my $conf     = $args{-cmdline_r}{config};

    my @res;

    # XXX read from cryp config

    # read from local wallet masternode config
    {
        my $conf_path = "$ENV{HOME}/.zcoin/znode.conf";
        unless (-f $conf_path) {
            log_debug "Couldn't find local wallet masternode configuration ".
                "file '$conf_path', skipped";
            last;
        }

        my $fh;
        unless (open $fh, "<", $conf_path) {
            log_error "Can't open '$conf_path': $!, skipped reading ".
                "local wallet masternode configuration file";
            last;
        }

        my $linum = 0;
        while (my $line = <$fh>) {
            $linum++;
            $line =~ /\S/ or next;
            $line =~ /^\s*#/ and next;
            $line =~ /^(\S+)\s+([0-9]+(?:\.[0-9]+){3}):([0-9]+)\s+(\S+)\s+(\S+)\s+(\d+)\s*$/ or do {
                log_warn "$conf_path:$linum: Doesn't match pattern, ignored";
                next;
            };
            push @res, {
                name => $1,
                ip   => $2,
                port => $3,
                collateral_txid => $5,
                collateral_oidx => $6,
            };
        }
        close $fh;

      CHECK_STATUS:
        {
            last unless $args{detail} && $args{with_status} && @res;

            # pick one masternode to ssh into
            my $rec = $res[rand @res];

            my $ssh_user =
                $crypconf->{masternodes}{zcoin}{$rec->{name}}{ssh_user} //
                $crypconf->{masternodes}{zcoin}{default}{ssh_user} //
                "root";
            my $mn_user  =
                $crypconf->{masternodes}{zcoin}{$rec->{name}}{mn_user} //
                $crypconf->{masternodes}{zcoin}{default}{mn_user} //
                $ssh_user; # XXX can also detect

            log_trace "ssh_user=<$ssh_user>, mn_user=<$mn_user>";

            if ($ssh_user ne 'root' && $ssh_user ne $mn_user) {
                log_error "Won't be able to access zcoin-cli (user $mn_user) while we SSH as $ssh_user, skipped";
                last;
            }

            my $ssh_timeout =
                $crypconf->{masternodes}{zcoin}{$rec->{name}}{ssh_timeout} //
                $crypconf->{masternodes}{zcoin}{default}{ssh_timeout} //
                $conf->{GLOBAL}{ssh_timeout} // 300;

            log_trace "SSH-ing to $rec->{name} ($rec->{ip}) as $ssh_user to query masternode status (timeout=$ssh_timeout) ...";

            eval {
                local $SIG{ALRM} = sub { die "Timeout\n" };
                # XXX doesn't cleanup ssh process when timeout triggers. same
                # with IPC::Cmd, or System::Timeout (which is based on
                # IPC::Cmd). IPC::Run's timeout doesn't work?
                alarm $ssh_timeout;

                my $ssh_cmd = $ssh_user eq $mn_user ?
                    "zcoin-cli znode list" :
                    "su $mn_user -c ".shell_quote("zcoin-cli znode list");

                my $output;
                system({log=>1, shell=>0, capture_stdout=>\$output},
                       "ssh", "-l", $ssh_user, $rec->{ip}, $ssh_cmd);

                my $output_decoded;
                eval { $output_decoded = JSON::MaybeXS->new->decode($output) };
                if ($@) {
                    log_error "Can't decode JSON output '$output', skipped";
                    last CHECK_STATUS;
                }

                for my $rec (@res) {
                    my $key = "COutPoint($rec->{collateral_txid}, $rec->{collateral_oidx})";
                    if (exists $output_decoded->{$key}) {
                        $rec->{status} = $output_decoded->{$key};
                    } else {
                        $rec->{status} = "(not found)";
                    }
                }
            };
            if ($@) {
                log_error "SSH timeout: $@, skipped";
                last;
            }
        } # CHECK_STATUS

        unless ($args{detail}) {
            @res = map {$_->{name}} @res;
        }

        [200, "OK", \@res];
    }
}

1;

# ABSTRACT: Zcoin (XZC) Masternode driver for App::cryp

__END__

=pod

=encoding UTF-8

=head1 NAME

App::cryp::Masternode::zcoin - Zcoin (XZC) Masternode driver for App::cryp

=head1 VERSION

This document describes version 0.003 of App::cryp::Masternode::zcoin (from Perl distribution App-cryp-mn), released on 2018-04-06.

=for Pod::Coverage ^(.+)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-cryp-mn>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-cryp-mn>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-cryp-mn>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
