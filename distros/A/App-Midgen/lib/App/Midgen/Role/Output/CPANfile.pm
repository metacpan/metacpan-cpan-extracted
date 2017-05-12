package App::Midgen::Role::Output::CPANfile;

use constant {NONE => q{}, THREE => 3,};

use Moo::Role;
requires qw( verbose );

# Load time and dependencies negate execution time
# use namespace::clean -except => 'meta';

our $VERSION = '0.34';
$VERSION = eval $VERSION;    ## no critic

use English qw( -no_match_vars );    # Avoids reg-ex performance penalty
local $OUTPUT_AUTOFLUSH = 1;

use Term::ANSIColor qw( :constants colored );
use File::Spec;

#######
# header_cpanfile
#######
sub header_cpanfile {
	my $self         = shift;
	my $package_name = shift || NONE;
	my $mi_ver       = shift || NONE;

	return;
}

#######
# body_cpanfile
#######
sub body_cpanfile {
	my $self         = shift;
	my $title        = shift || return;
	my $required_ref = shift || return;

	my $pm_length = 0;
	foreach my $module_name (sort keys %{$required_ref}) {
		if (length $module_name > $pm_length) {
			$pm_length = length $module_name;
		}
	}

	if ($title eq 'RuntimeRequires') {
		print "\n";

		$required_ref->{'perl'} = $App::Midgen::Min_Version;
		foreach my $module_name (sort keys %{$required_ref}) {

			my $mod_name = "'$module_name',";
			printf "%s %-*s '%s';\n", 'requires', $pm_length + THREE, $mod_name,
				$required_ref->{$module_name}
				if $required_ref->{$module_name} !~ m/mcpan/;
		}
	}
	elsif ($title eq 'RuntimeRecommends') {
		print "\n";
		foreach my $module_name (sort keys %{$required_ref}) {

			my $mod_name = "'$module_name',";
			printf "%s %-*s '%s';\n", 'recommends', $pm_length + THREE, $mod_name,
				$required_ref->{$module_name}
				if $required_ref->{$module_name} !~ m/mcpan/;
		}
	}
	elsif ($title eq 'TestRequires') {
		print "\non test => sub {\n";
		foreach my $module_name (sort keys %{$required_ref}) {
			my $mod_name = "'$module_name',";
			printf "\t%s %-*s '%s';\n", 'requires', $pm_length + THREE, $mod_name,
				$required_ref->{$module_name}
				if $required_ref->{$module_name} !~ m/mcpan/;

		}
		print "\n" if %{$required_ref};
	}
	elsif ($title eq 'TestSuggests') {
		foreach my $module_name (sort keys %{$required_ref}) {
			my $mod_name = "'$module_name',";
			printf "\t%s %-*s '%s';\n", 'suggests', $pm_length + THREE, $mod_name,
				$required_ref->{$module_name}
				if $required_ref->{$module_name} !~ m/mcpan/;

		}
	}
	elsif ($title eq 'Close') {
		print "};\n";
	}
	elsif ($title eq 'DevelopRequires') {
		print "\non develop => sub {\n";
		foreach my $module_name (sort keys %{$required_ref}) {
			my $mod_name = "'$module_name',";
			printf "\t%s %-*s '%s';\n", 'recommends', $pm_length + THREE,
				$mod_name, $required_ref->{$module_name}
				if $required_ref->{$module_name} !~ m/mcpan/;

		}
		print "};\n";
	}

	return;
}

#######
# footer_cpanfile
#######
sub footer_cpanfile {
	my $self = shift;
	my $package_name = shift || NONE;
	$package_name =~ s{::}{-}g;

	print "\n";

	return;
}


no Moo;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Midgen::Role::Output::CPANfile - Output Format - cpanfile,
used by L<App::Midgen>

=head1 VERSION

version: 0.34

=head1 DESCRIPTION

The output format uses colour to add visualization of module version number
types, be that mcpan, dual-life or added distribution.

=head1 METHODS

=over 4

=item * header_cpanfile

=item * body_cpanfile

=item * footer_cpanfile

=back

=head1 DEPENDENCIES

L<Term::ANSIColor>

=head1 SEE ALSO

L<App::Midgen>

=head1 AUTHOR

See L<App::Midgen>

=head2 CONTRIBUTORS

See L<App::Midgen>

=head1 COPYRIGHT

See L<App::Midgen>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

