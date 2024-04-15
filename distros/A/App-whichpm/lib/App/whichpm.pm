package App::whichpm;

=head1 NAME

App::whichpm - locate a Perl module and it's version

=head1 SYNOPSIS

	use App::whichpm 'which_pm';
	my ($filename, $version) = which_pm('App::whichpm');
	my $filename = App::whichpm::find('App::whichpm');

from shell:

	whichpm App::whichpm
	whichpm Universe::ObservableUniverse::Filament::SuperCluster::Cluster::Group::Galaxy::Arm::Bubble::InterstellarCloud::SolarSystem::Earth

=head1 DESCRIPTION

Loads a given module and reports it's location and version.

The similar function can be achieved via:

	perldoc -l Some::Module
	perl -MSome::Module -le 'print $INC{"Some/Module.pm"}'
	perl -MSome::Module -le 'print Some::Module->VERSION'
	pmpath Some::Module
	pmvers Some::Module

=cut

use warnings;
use strict;

our $VERSION = '0.06';

use File::Spec;

use base 'Exporter';
our @EXPORT_OK = qw(
    which_pm
);

=head1 EXPORTS

=head2 which_pm

same as L</find> only exported under C<which_pm> name.

=cut

*which_pm = *find;

=head1 FUNCTIONS

=head2 find($module_name)

Loads the C<$module_name>.

In scalar context returns filename corresponding to C<$module_name>.
In array context returns filename and version.

C<$module_name> can be either C<Some::Module::Name> or C<Some/Module/Name.pm>

=cut

sub find {
	my $module_name = shift;
	my $module_filename;

	if ($module_name =~ m/\.pm$/xms) {
		$module_name     = substr($module_name, 0, -3);
		$module_name     =~ s{[/\\]}{::}g;
	}

	$module_filename        = $module_name.'.pm';
	my $module_inc_filename = join('/', split('::', $module_filename));
	$module_filename        = File::Spec->catfile(split('::', $module_filename));

	eval "use $module_name;";
	my $filename = $INC{$module_inc_filename};

	# if the filename is not in %INC then try to search the @INC folders
	if (not $filename) {
		foreach my $inc_path (@INC) {
			my $module_full_filename = File::Spec->catfile($inc_path, $module_filename);
			return $module_full_filename
				if -f $module_full_filename;
		}
		return;
	}

	# MSWin32 has unix / in the %INC folder paths, so recreate the filename
	$filename = File::Spec->catfile(split(m{[/\\]}, $filename));

	if (wantarray) {
		my $version  = eval { $module_name->VERSION };
		return ($filename, (defined $version ? $version : ()));
	}

	return $filename
}

1;


__END__

=head1 SEE ALSO

L<http://perlmonks.org/?node=whichpm>, L<pmpath|http://search.cpan.org/perldoc?pmpath>,
L<Module::InstalledVersion>, L<Module::Info>

=head1 AUTHOR

Jozef Kutej

=head1 CONTRIBUTORS

The following people have contributed to the App::whichpm by committing their
code, sending patches, reporting bugs, asking questions, suggesting useful
advises, nitpicking, chatting on IRC or commenting on my blog (in no particular
order):

	Jerrad Pierce
	Skye Shaw
	Andreas Hadjiprocopis

=head1 LICENSE AND COPYRIGHT

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
