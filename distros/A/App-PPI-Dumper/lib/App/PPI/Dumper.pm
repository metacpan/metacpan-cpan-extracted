package App::PPI::Dumper;

our $VERSION = "1.026";

=encoding utf8

=head1 NAME

App::PPI::Dumper - Use the PPI to dump the structure of a Perl file

=head1 SYNOPSIS

	use App::PPI::Dumper;

	App::PPI::Dumper->run( @ARGV );

=head1 DESCRIPTION

Parse a Perl document with PPI and dump the Perl Document Object Model (PDOM).
This script is a command-line interface to PPI::Dumper.

=head2 Methods

=over 4

=item run( OPTIONS, INPUT_FILE )

Parse INPUT_FILE with the given PPI::Dumper options, then print the result to
standard output.

=over 4

=item -m

Show the memory address of each PDOM element.

=item -i N

Ident each level of output by N spaces. The default is 2.

=item -P

Do not show the full package name for each PPI class.

=item -T

Do not show the original source token that goes with each PPI object.

=item -W

Do not show whitespace tokens.

=item -C

Do not show comment tokens.

=item -l

Show the source code location of each PPI token.

=item -r

Parse the input in readonly mode. See PPI::Document::new() for the details.

=back

=back

=head1 SEE ALSO

Most behaviour, including environment variables and configuration,
comes directly from PPI::Dumper. I just made a command-line tool for it.

=head1 SOURCE AVAILABILITY

This code is in Github:

	https://github.com/briandfoy/app-ppi-dumper.git

=head1 AUTHOR

brian d foy, C<< <briandfoy@pobox.com> >>

=head1 COPYRIGHT

Copyright © 2009-2025, brian d foy <briandfoy@pobox.com>. All rights reserved.

You may redistribute this under the terms of the Artistic License 2.0.

=cut

use Getopt::Std qw(getopts);
use PPI;
use PPI::Dumper;

__PACKAGE__->run(@ARGV) unless caller;

# same defaults as PPI::Dumper
sub run {
	my $self = shift;

	local @ARGV = @_;

	my %opts = (
		'm' => 0, # memaddr
		'i' => 2, # indent
		'P' => 0, # class
		'D' => 0, # content
		'W' => 0, # whitespace
		'C' => 0, # comments
		'l' => 0, # locations
		'r' => 0, # read-only, for PPI::Document
		);

	getopts('mPDWCli:', \%opts);

	my $Module = PPI::Document->new(
		$ARGV[0],
		readonly => $opts{'r'},
		);

	die "Could not parse [$ARGV[0]] for PPI: " . PPI::Document->errstr . "\n"
		if PPI::Document->errstr;

	my $Dumper = PPI::Dumper->new( $Module,
		memaddr    =>   $opts{'m'},
		indent     =>   $opts{'i'},
		class      => ! $opts{'P'},
		content    => ! $opts{'D'},
		whitespace => ! $opts{'W'},
		comments   => ! $opts{'C'},
		locations  =>   $opts{'l'},
		);

	$Dumper->print;
	}

1;

__END__
