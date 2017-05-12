package Apache::FormatLog::Combined;

=head1 NAME

Apache::FormatLog::Combined -- Format Apache access log entry in common format from mod_perl handlers.

=head1 SYNOPSIS

use Apache::FormatLog::Combined;

$lf = Apache::FormatLog::Combined->new($r);
$combinedLogLine = $lf->toString();

=head1 DESCRIPTION

Apache::FormatLog::Combined is an extension of the Apache::FormatLog module.
Use it to construct log entries in combined format.

=head1 METHODS

Because this module is an extension, look at the POD of Apache::FormatLog for a description of all methods.

=head1 SEE ALSO

perl(1), mod_perl(3), Apache(3),
Apache::FormatLog, Apache::FormatLog::Common

=head1 AUTHOR

Leendert Bottelberghs <lbottel@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2005, Leendert Bottelberghs.  All rights reserved.

This module is free software.  It may be used, redistributed
and/or modified under the same terms as Perl itself.

=cut

use strict;
require Apache::FormatLog;
use vars qw($VERSION @ISA);

$VERSION = '0.01';
@ISA = qw(Apache::FormatLog);

sub toString{
	my $class = shift;
	my $logdata = $class->getLogData();
	return join(' ', (
		$logdata->{remotehost},
		$logdata->{remotelogname},
		$logdata->{remoteuser},
		$logdata->{formattedtime},
		"\"$logdata->{request}\"",
		$logdata->{status},
		$logdata->{bytes},
		"\"$logdata->{referer}\"",
		"\"$logdata->{browser}\""));
}

1;
