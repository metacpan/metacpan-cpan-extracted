#!/usr/bin/perl

=head1 NAME

config_creator.pl - read a configuration description and prompt for value

=head1 SYNOPSIS

	config_creator.pl description_file

=head1 DESCRIPTION

The config_creator.pl program reads a configuration description file
and then prompts the user for values, creating a configuration file
in the process.

=head1 SOURCE AVAILABILITY

=head1 SOURCE AVAILABILITY

The source is in Github:

	http://github.com/briandfoy/ConfigReader-Simple/

=head1 AUTHORS

brian d foy, E<lt>bdfoy@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright © 2002-2018, brian d foy <bdfoy@cpan.org>. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

my $config = '';

while( <> )
	{
	next if m/\s*#/;
	chomp;
	my( $directive, $description ) = split m/\s+/, $_, 2;

	my $answer = prompt( $description );

	$config .= "$directive $answer\n";
	}

print $config;

sub prompt
	{
	my $message = shift;

	print "$message> ";

	my $answer = <STDIN>;
	chomp $answer;

	return $answer;
	}
