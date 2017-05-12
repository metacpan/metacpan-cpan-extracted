use strict;
use warnings;
package App::Whatsit;
BEGIN {
  $App::Whatsit::VERSION = '0.0.1';
}

# ABSTRACT: Easily find out package details from the command line.

use base qw(App::Cmd::Simple);


sub validate_args
{
	my $self = shift;
	my $options = shift;
	my $args = shift;
	
	$self->usage_error("At least one package name is required") unless @$args;
}

sub execute
{
	my $self = shift;
	my $options = shift;
	my $args = shift;
	
	foreach (@$args)
	{
		_find_details($_);
	}
}

sub _find_details
{
	my $package = shift;
	
	eval "use $package";
	if($@)
	{
		# TODO bail out (completely)
	}
	else
	{
		my $version = $package->VERSION;
		$version = 'Unknown' unless defined $version;
		
		my $package_file = $package.'.pm';
		$package_file =~ s/::/\//g;
		my $path = $INC{$package_file};
		$path = 'Unknown' unless defined $path;
		
		print "$package:\n\tVersion: $version\n\tPath: $path\n";
	}
}

1;

__END__
=pod

=head1 NAME

App::Whatsit - Easily find out package details from the command line.

=head1 VERSION

version 0.0.1

=head1 SYNOPSIS

  $ whatsit [package name]

=head1 AUTHOR

Glenn Fowler <cebjyre@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Glenn Fowler.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

