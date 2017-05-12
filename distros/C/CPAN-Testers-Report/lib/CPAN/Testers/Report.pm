use 5.006;
use strict;
use warnings;

package CPAN::Testers::Report;
# ABSTRACT: CPAN Testers report object

our $VERSION = '1.999003';

use Metabase::Report 0.016 ();
our @ISA = qw/Metabase::Report/;
CPAN::Testers::Report->load_fact_classes;

sub report_spec {
    return {
        'CPAN::Testers::Fact::LegacyReport'     => 1,
        'CPAN::Testers::Fact::TestSummary'      => 1,    # include date
        'CPAN::Testers::Fact::TestOutput'       => '0+', # eventually by phase
        'CPAN::Testers::Fact::TesterComment'    => '0+',
        'CPAN::Testers::Fact::PerlConfig'       => '0+',
        'CPAN::Testers::Fact::TestEnvironment'  => '0+',
        'CPAN::Testers::Fact::Prereqs'          => '0+', # declared versions
        'CPAN::Testers::Fact::InstalledModules' => '0+',
        # XXX needs NNTP_ID for old reports -- dagolden, 2009-06-24
        # future goals
        # 'CPAN::Testers::Fact::TAPArchive' => 1,
    };
}

sub content_metadata {
    my ($self) = @_;
    for my $fact ( $self->facts ) {
        next unless $fact->type eq 'CPAN-Testers-Fact-LegacyReport';
        return $fact->content_metadata;
    }
}

sub content_metadata_types {
    require CPAN::Testers::Fact::LegacyReport;
    return CPAN::Testers::Fact::LegacyReport->content_metadata_types;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CPAN::Testers::Report - CPAN Testers report object

=head1 VERSION

version 1.999003

=head1 SYNOPSIS

  my $report = CPAN::Testers::Report->open(
    resource => 'cpan:///distfile/RJBS/CPAN-Metabase-Fact-0.001.tar.gz',
  );

  $report->add( CPAN::Testers::Fact::LegacyReport => {
    grade         => $tr->grade,
    osname        => $tr->osname,
    osversion     => $tr->osversion
    archname      => $tr->archname
    perlversion   => $tr->perl_version_number
    textreport    => $tr->report
  });

  # TestSummary happens to be the same as content metadata 
  # of LegacyReport for now
  $report->add( CPAN::Testers::Fact::TestSummary =>
    $report->facts->[0]->content_metadata()
  );
    
  $report->close();

=head1 DESCRIPTION

Metabase report class encapsulating Facts about a CPAN Testers report

=head1 USAGE

CPAN::Testers::Report subclasses L<Metabase::Report>.  See that module for API.
See L<Test::Reporter::Transport::Metabase> for an example of usage.

=head1 BUGS

Please report any bugs or feature using the CPAN Request Tracker.  
Bugs can be submitted through the web interface at 
L<http://rt.cpan.org/Dist/Display.html?Queue=CPAN-Testers-Report>

When submitting a bug or request, please include a test-file or a patch to an
existing test-file that illustrates the bug or desired feature.

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/dagolden/CPAN-Testers-Report/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/dagolden/CPAN-Testers-Report>

  git clone https://github.com/dagolden/CPAN-Testers-Report.git

=head1 AUTHOR

David Golden <dagolden@cpan.org>

=head1 CONTRIBUTORS

=for stopwords Brian Fraser David Steinbrunner

=over 4

=item *

Brian Fraser <brian.fraser@booking.com>

=item *

David Steinbrunner <dsteinbrunner@pobox.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
