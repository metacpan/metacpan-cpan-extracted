
use strict;
use warnings;

use Test::More;

# FILENAME: 03-undef-prereq-report.t
# CREATED: 03/23/15 20:25:56 by Kent Fredric (kentnl) <kentfredric@gmail.com>
# ABSTRACT: Test undef in prereq reports

sub nowarn {
    my ( $reason, $code ) = @_;
    my @warns;
    {
        local $SIG{__WARN__} = sub { push @warns, $_[0] };
        $code->();
    };
    return 1 if ok( !scalar @warns, $reason );
    diag explain \@warns;
    return;
}

use CPAN::Testers::Common::Client;

my $rreqs = <<"EOF";
version 0
CPAN 0
ExtUtils::Command 0
ExtUtils::ParseXS 0
File::Spec 0
YAML 0
YAML::Syck 0
EOF

my $prereqs = { runtime => { requires => { split /\s+/sm, $rreqs } } };

{
    my $report;
    my $ok = nowarn "No warnings emitted from real report generation" => sub {
        $report =
          CPAN::Testers::Common::Client::_format_prereq_report($prereqs);
    };
    $ok ? note $report : diag $report;
}

{
    my $report;
    my $ok = nowarn "No warnings emitted in bad report generation" => sub {
        no warnings 'redefine';

        # Emulate a broken finder that returns an empty hash due
        # to silently SEGV/LD Sym fail.
        local *CPAN::Testers::Common::Client::_version_finder =
          sub { return {} };

        $report =
          CPAN::Testers::Common::Client::_format_prereq_report($prereqs);
    };
    $ok ? note $report : diag $report;
}

{
    my $report;
    my $installed = {
        good    => 1,
        another => 2,
        bad     => undef,
        zero    => 0,
    };
    my $ok = nowarn "No warnings emitted by toolchain report" => sub {
        $report =
          CPAN::Testers::Common::Client::_format_toolchain_report($installed);
    };
    $ok ? note $report : diag $report;
}

done_testing;

