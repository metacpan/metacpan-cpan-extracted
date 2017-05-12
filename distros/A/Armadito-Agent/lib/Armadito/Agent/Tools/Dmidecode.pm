package Armadito::Agent::Tools::Dmidecode;

use strict;
use warnings;
use base 'Exporter';

use English qw(-no_match_vars);
use Memoize;

use Armadito::Agent::Tools qw(trimWhitespaces);
use IPC::System::Simple qw(capture $EXITVAL EXIT_ANY);

our @EXPORT_OK = qw(
	getDmidecodeInfos
);

memoize('getDmidecodeInfos');

sub getDmidecodeInfos {
	my (%params) = @_;

	my $output = capture( EXIT_ANY, "dmidecode" );
	my ( $info, $block, $type );
	my @lines = split( /\n/, $output );

	foreach my $line (@lines) {
		chomp $line;

		if ( $line =~ /DMI type (\d+)/ ) {

			# push previous block in list
			if ($block) {
				push( @{ $info->{$type} }, $block );
				undef $block;
			}

			# switch type
			$type = $1;

			next;
		}

		next unless defined $type;

		next unless $line =~ /^\s+ ([^:]+) : \s (.*\S)/x;

		next
			if $2 eq 'N/A'
			|| $2 eq 'Not Specified'
			|| $2 eq 'Not Present'
			|| $2 eq 'Unknown'
			|| $2 eq '<BAD INDEX>'
			|| $2 eq '<OUT OF SPEC>'
			|| $2 eq '<OUT OF SPEC><OUT OF SPEC>';

		$block->{$1} = trimWhitespaces($2);
	}

	# do not return anything if dmidecode output is obviously truncated
	return if keys %$info < 2;

	return $info;
}
1;
__END__

=head1 NAME

Armadito::Agent::Tools::Dmidecode - Dmidecode OS-independent function

=head1 DESCRIPTION

This module provides an OS-independent function for extracting system information with dmidecode.

=head1 FUNCTIONS

=head2 getDmidecodeInfos

Returns a structured view of dmidecode output. Each information block is turned
into an hashref, block with same DMI type are grouped into a list, and each
list is indexed by its DMI type into the resulting hashref.

$info = {
    0 => [
        { block }
    ],
    1 => [
        { block },
        { block },
    ],
    ...
}
