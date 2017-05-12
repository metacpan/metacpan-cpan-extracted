package App::Midgen::Role::Output::MI;

use constant {NONE => q{},};

use Moo::Role;
requires qw( no_index verbose );

# Load time and dependencies negate execution time
# use namespace::clean -except => 'meta';

our $VERSION = '0.34';
$VERSION = eval $VERSION;    ## no critic

use English qw( -no_match_vars );    # Avoids reg-ex performance penalty
local $OUTPUT_AUTOFLUSH = 1;

use Term::ANSIColor qw( :constants colored );
use File::Spec;


#######
# header_mi
#######
sub header_mi {
	my $self         = shift;
	my $package_name = shift || NONE;
	my $mi_ver       = shift || NONE;

	print "\nuse strict;\n";
	print "use warnings;\n";
	print "use inc::Module::Install " . colored($mi_ver, 'yellow') . ";\n";

	if ($package_name ne NONE) {
		$package_name =~ s{::}{-}g;
		print "name '$package_name';\n";
		$package_name =~ tr{-}{/};
		print "all_from 'lib/$package_name.pm';\n";
	}

	print BRIGHT_BLACK . "license 'perl';" . CLEAR . "\n";
	return;
}
#######
# body_mi
#######
sub body_mi {
	my $self         = shift;
	my $title        = shift;
	my $required_ref = shift || return;

	return if not %{$required_ref};

	my $pm_length = 0;
	foreach my $module_name (sort keys %{$required_ref}) {
		if (length $module_name > $pm_length) {
			$pm_length = length $module_name;
		}
	}

	print "perl_version '$App::Midgen::Min_Version';\n" if $title eq 'RuntimeRequires';
	print "\n";

	$title =~ s/^RuntimeRequires/requires/;
	$title =~ s/^TestRequires/test_requires/;

	foreach my $module_name (sort keys %{$required_ref}) {

		next
			if $title eq 'test_requires'
			&& $required_ref->{$module_name} =~ m/mcpan/;

		if ($module_name =~ /^Win32/sxm) {
			my $sq_key = "'$module_name'";
			printf "%s %-*s => '%s' %s;\n", $title, $pm_length + 2, $sq_key,
				$required_ref->{$module_name}, colored('if win32', 'bright_green');
		}
		elsif ($module_name =~ /XS/sxm) {
			my $sq_key = "'$module_name'";
			printf "%s %-*s => '%s' %s;\n", $title, $pm_length + 2, $sq_key,
				$required_ref->{$module_name}, colored('if can_xs', 'bright_blue');
		}
		elsif ($module_name eq 'MRO::Compat') {
			my $sq_key = "'$module_name'";
			printf "%s %-*s => '%s' %s;\n", $title, $pm_length + 2, $sq_key,
				$required_ref->{$module_name},
				colored('if $] < 5.009005', 'bright_blue');
		}
		else {
			my $sq_key = "'$module_name'";
			printf "%s %-*s => '%s';\n", lc $title, $pm_length + 2, $sq_key,
				$required_ref->{$module_name};
		}

	}

	return;
}
#######
# footer_mi
#######
sub footer_mi {
	my $self = shift;
	my $package_name = shift || NONE;
	$package_name =~ s{::}{-}g;

	if ($self->verbose > 0) {
		print BRIGHT_BLACK "\n";
		print "homepage    'https://github.com/.../$package_name';\n";
		print "bugtracker  'https://github.com/.../$package_name/issues';\n";
		print "repository  'git://github.com/.../$package_name.git';\n";
		print "\n";
		print "Meta->add_metadata(\n";
		print "\tx_contributors => [\n";
		print "\t\t'brian d foy (ADOPTME) <brian.d.foy\@gmail.com>',\n";
		print "\t\t'Fred Bloggs <fred\@bloggs.org>',\n";
		print "\t],\n";
		print ");\n";
		print CLEAR;
	}

	print "\n";

	if (defined -d File::Spec->catdir($App::Midgen::Working_Dir, 'share')) {
		print "install_share;\n\n";
	}

	if (defined -d File::Spec->catdir($App::Midgen::Working_Dir, 'script')) {
		print "install_script 'script/...';\n\n";
	}
	elsif (defined -d File::Spec->catdir($App::Midgen::Working_Dir, 'bin')) {
		print "install_script 'bin/...';\n\n";
	}

	my @no_index = $self->no_index;
	if (@no_index) {
		print "no_index 'directory' => qw{ @no_index };\n\n";
	}

	print "WriteAll\n\n";

	return;
}

no Moo;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Midgen::Role::Output::MI - Output Format - Module::Install,
used by L<App::Midgen>

=head1 VERSION

version: 0.34

=head1 DESCRIPTION

The output format uses colour to add visualization of module version number
types, be that mcpan, dual-life or added distribution.

=head1 METHODS

=over 4

=item * header_mi

=item * body_mi

=item * footer_mi

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

