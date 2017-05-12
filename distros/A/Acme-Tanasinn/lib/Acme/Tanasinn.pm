package Acme::Tanasinn;

use warnings;
use strict;

use 5.008;


=encoding utf-8

=head1 NAME

Acme::Tanasinn - Don't think. Feel and you'll be tanasinn.

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

    use Acme::Tanasinn;

    my $tanasinn = "Don't think. Feel.\n";
    print tanasinn($tanasinn);

=cut

BEGIN
{
	use base 'Exporter';
	our @EXPORT = ('tanasinn');
}

=head1 METHODS

=head2 tanasinn()

    tanasinn() will do everything. Leave everything to tanasinn. Tanasinn exports tanasinn.

=cut

sub tanasinn
{

	my $string = shift;
	
	my @replace_range = 1..3;

	my $pos  = 0;
	my $step = '';

	while(1)
	{
		return $string if $pos >= length($string);

		my $count = $replace_range[rand(@replace_range)];

		for(1..$count)
		{
			$step .= "\x{2235}";
		}
			
		substr($string,	$pos, length($step), $step);

		$pos += length($step) + $replace_range[rand(@replace_range)];

	}

}


=head1 AUTHOR

The Elitist Superstructure of DQN, L<http://4-ch.net/dqn/>

=head1 BUGS

P∵∵∵s∵∵∵∵∵r∵∵∵∵b∵∵∵∵∵∵∵∵∵∵∵e∵∵∵∵∵<∵∵∵∵∵∵∵a∵i∵∵∵∵∵∵∵∵∵∵∵o∵∵∵∵∵∵∵∵∵∵∵
nt∵∵∵∵∵∵∵∵∵∵∵∵∵∵∵Au∵∵∵∵∵∵g∵∵∵∵∵∵∵∵∵∵∵∵∵∵∵∵∵∵∵∵∵. ∵∵∵∵∵∵ n∵∵∵∵∵∵∵d∵∵a∵∵∵∵∵∵ ∵∵∵∵∵∵
aut∵∵∵∵∵∵∵∵b∵∵∵∵∵∵∵f∵∵∵∵∵∵s∵∵∵∵∵∵∵∵b∵∵∵∵a∵∵∵∵∵∵∵∵∵∵∵∵∵∵.∵

=head1 LICENSE AND COPYRIGHT

Copyright 2009 The Elitist Superstructure.

This program is free software; you may use this software under the terms of Perl itself, 
providing you do not affiliate as "Affiliation" carries a connotation that some find unpleasant.

=cut

1;
