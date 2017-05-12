package App::Midgen::Role::Output::MB;

use constant {NONE => q{},};

use Moo::Role;

# Load time and dependencies negate execution time
# use namespace::clean -except => 'meta';

our $VERSION = '0.34';
$VERSION = eval $VERSION;    ## no critic

use English qw( -no_match_vars );    # Avoids reg-ex performance penalty
local $OUTPUT_AUTOFLUSH = 1;

use File::Spec;

#######
# header_mb
#######
sub header_mb {
	my $self = shift;
	my $package_name = shift || NONE;

	if ($package_name ne NONE) {
		$package_name =~ s{::}{-}g;
		print "\n" . '"dist_name" => "' . $package_name . q{",} . "\n";
	}

	return;
}
#######
# body_mb
#######
sub body_mb {
	my $self         = shift;
	my $title        = shift;
	my $required_ref = shift || return;

	return if not %{$required_ref};

	print "\n";

	my $pm_length = 0;
	foreach my $module_name (sort keys %{$required_ref}) {
		if (length $module_name > $pm_length) {
			$pm_length = length $module_name;
		}
	}

	$title =~ s/^RuntimeRequires/requires/;
	$title =~ s/^TestRequires/test_requires/;

	print q{"} . lc $title . '" => {' . "\n";

	foreach my $module_name (sort keys %{$required_ref}) {

		next
			if $title eq 'test_requires'
			&& $required_ref->{$module_name} =~ m/mcpan/;

		my $sq_key = "\"$module_name\"";
		printf "\t %-*s => \"%s\",\n", $pm_length + 2, $sq_key,
			$required_ref->{$module_name};

	}
	print "},\n";

	return;
}
#######
# footer_mb
#######
sub footer_mb {
	my $self = shift;

	if (defined -d File::Spec->catdir($App::Midgen::Working_Dir, 'script')) {
		print "\n" . '"script_files" => [' . "\n";
		print "\t\"script/...\"\n";
		print "],\n";
	}
	elsif (defined -d File::Spec->catdir($App::Midgen::Working_Dir, 'bin')) {
		print "\n" . '"script_files" => [' . "\n";
		print "\t\"bin/...\"\n";
		print "],\n";
	}

	print "\n";

	return;
}

no Moo;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Midgen::Role::Output::MB - Output Format - Module::Build,
used by L<App::Midgen>

=head1 VERSION

version: 0.34

=head1 DESCRIPTION

The output format uses colour to add visualization of module version number
types, be that mcpan, dual-life or added distribution.

=head1 METHODS

=over 4

=item * header_mb

=item * body_mb

=item * footer_mb

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

