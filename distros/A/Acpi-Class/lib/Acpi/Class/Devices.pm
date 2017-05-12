package Acpi::Class::Devices;
{
  $Acpi::Class::Devices::VERSION = '0.003';
} 
#ABSTRACT: Gives an ArrayRef with the directores in a folder.

# use modules {{{
use strict;
use warnings;
use Object::Tiny::XS qw{ dir pattern };
use Carp;
# }}}

sub devices    #{{{
{ 
	my $self = shift;
	my $dir     = $self->dir;
	my $pattern = $self->pattern;
	opendir(my $device_dir, $dir) or croak "Cannot open $dir : $!";
	my @devices;
	while(readdir($device_dir))
	{
		push @devices, $_ if ($_ =~ /$pattern/x);
	}
	closedir($device_dir);

	# die "No elements found in $dir" unless (scalar @devices > 0);
	return \@devices;
} #}}}

1;

__END__

=pod

=head1 NAME

Acpi::Class::Devices - Gives an ArrayRef with the directores in a folder.

=cut
