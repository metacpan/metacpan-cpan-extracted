use strict; # make CPANTS happy
package CPAN::Reporter::FAQ;

our $VERSION = '1.2018';

1;

# ABSTRACT: Answers and tips for using CPAN::Reporter

__END__

=pod

=encoding UTF-8

=head1 NAME

CPAN::Reporter::FAQ - Answers and tips for using CPAN::Reporter

=head1 VERSION

version 1.2018

=head1 REPORT GRADES

=head2 Why did I receive a report? 

Historically, CPAN Testers was designed to have each tester send a copy of
reports to authors.  This philosophy changed in September 2008 and CPAN Testers
tools were updated to no longer copy authors, but some testers may still be
using an older version.

=head2 Why was a report sent if a prerequisite is missing?

As of CPAN::Reporter 0.46, FAIL and UNKNOWN reports with unsatisfied 
prerequisites are discarded.  Earlier versions may have sent these reports 
out by mistake as either an NA or UNKNOWN report.

PASS reports are not discarded because it may be useful to know when tests
passed despite a missing prerequisite.  NA reports are sent because information
about the lack of support for a platform is relevant regardless of
prerequisites.

=head1 SENDING REPORTS

=head2 Why did I get an error sending a test report?

Historically, test reports were sent via ordinary email.
The most common reason for errors sending a report back then was that
many Internet Service Providers (ISP's) would block
outbound SMTP (email) connections as part of their efforts to fight spam.

Since 2010, test reports are sent to the CPAN Testers Metabase over HTTPS. The
most common reason for failures are systems which upgraded CPAN::Reporter but
are still configured to use the deprecated and unsupported email system instead
of Metabase for transport.

If you are unsure which transport mechanism you're using, look for the
C<<< transport >>> rule in the C<<< .cpanreporter/config.ini >>> file, in the
user's home directory.  See L<CPAN::Reporter::Config> for details on how
to set the C<<< transport >>> option for Metabase.

Other errors could be caused by the absence of the
C<<< .cpanreporter/metabase_id.json >>> file in the user's home directory. This file
should be manually created prior to sending any reports, via the
C<<< metabase-profile >>> program. Simply run it and fill in the information
accordingly, and it will create the C<<< metabase_id.json >>> file for you. Move that
file to your C<<< .cpanreporter >>> directory and you're all set.

If you experience intermittent network issues, you can set the
'retry_submission' option to make a second attempt at sending the report
a few seconds later, in case the first one fails. This could be useful for
extremely slow connections.

Finally, lack of Internet connection or firewall filtering will prevent
the report from reaching the CPAN Testers servers. If you are experiencing
HTTPS issues or messages complaining about SSL modules, try installing
the L<LWP::Protocol::https> module and trying again. If all fails, you
may still change the transport uri to use HTTP instead of HTTPS, though
this is I<not> recommended.

=head2 Why didn't my test report show up on CPAN Testers?

There is a delay between the time reports are sent to the Metabase and when
they they appear on the CPAN Testers website. There is a further delay before
summary statistics appear on search.cpan.org.  If your reports do not appear
after 24 hours, please contact the cpan-testers-discuss email list
(L<http://lists.perl.org/list/cpan-testers-discuss.html>) or join the
C<<< #cpantesters-discuss >>> IRC channel on C<<< irc.perl.org >>>.

=head1 CPAN TESTERS

=head2 Where can I find out more about CPAN Testers?

A good place to start is the CPAN Testers Wiki: 
L<http://wiki.cpantesters.org/>

=head2 Where can I find statistics about reports sent to CPAN Testers?

CPAN Testers statistics are compiled at L<http://stats.cpantesters.org/>

=head2 How do I make sure I get credit for my test reports?

To get credit in the statistics, use the same Metabase profile file
and the same email address wherever you run tests.

=head1 SEE ALSO

=over

=item *

L<CPAN::Testers>

=item *

L<CPAN::Reporter>

=item *

L<Test::Reporter>

=back

=head1 AUTHOR

David Golden <dagolden@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2006 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
