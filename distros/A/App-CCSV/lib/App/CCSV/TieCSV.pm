package TieCSV;

use strict;

require Tie::Handle;

our @ISA = qw(Tie::Handle);

our $VERSION = 0.01;

my $csv;
sub TIEHANDLE 
{
	my $class = shift;
	$csv = shift;
	my $fh = local *ARGV;
	bless \$fh, $class;
}

sub READLINE
{
	my $self = shift;
	my $line = <$self>;
	if ($line)
	{
		my $status = $csv->parse($line);
		@::f = $csv->fields();
		return $line;
	}
	return;
}

1;

__END__

=pod

=head1 NAME

App::CCSV::TieCSV.

=head1 VERSION

Version 0.01

=head1 DESCRIPTION

Helper class for L<App::CCSV>.

=head1 SEE ALSO

L<App::CCSV>

=head1 BUGS

There surely are ...

Please send bug reports or feature requests to Karlheinz Zoechling <kh at ibeatgarry dot com>.

=head1 COPYRIGHT & LICENSE

Copyright 2008 Karlheinz Zoechling. All rights reserved.

This is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
