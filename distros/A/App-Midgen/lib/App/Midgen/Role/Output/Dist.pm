package App::Midgen::Role::Output::Dist;

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
# header_dist
#######
sub header_dist {
	my $self = shift;
	my $package_name = shift || NONE;

	if ($package_name ne NONE) {
		$package_name =~ s{::}{-}g;
		print "\nname        = $package_name\n";
		$package_name =~ tr{-}{/};
		print "main_module = lib/$package_name.pm\n";
	}

	return;
}

#######
# body_dist
#######
sub body_dist {
	my $self         = shift;
	my $title        = shift || return;
	my $required_ref = shift || return;

	return if not %{$required_ref};

	print "\n";

	my $pm_length = 0;
	foreach my $module_name (sort keys %{$required_ref}) {
		if (length $module_name > $pm_length) {
			$pm_length = length $module_name;
		}
	}

	if ($title eq 'RuntimeRequires') {
		print "[Prereqs]\n";
		printf "%-*s = %s\n", $pm_length, 'perl', $App::Midgen::Min_Version;
	}
	elsif ($title eq 'RuntimeRecommends') {
		print "[Prereqs / RuntimeRecommends]\n";
	}
	elsif ($title eq 'TestRequires') {
		print "[Prereqs / TestRequires]\n";
	}
	elsif ($title eq 'TestSuggests') {
		print "[Prereqs / TestSuggests]\n";
	}
	elsif ($title eq 'DevelopRequires') {
		print "[Prereqs / DevelopRequires]\n";
	}

	foreach my $module_name (sort keys %{$required_ref}) {

		next
			if $title eq 'TestRequires'
			&& $required_ref->{$module_name} =~ m/mcpan/;

		printf "%-*s = %s\n", $pm_length, $module_name,
			$required_ref->{$module_name};
	}

	return;
}

#######
# footer_dist
#######
sub footer_dist {
	my $self = shift;
	my $package_name = shift || NONE;
	$package_name =~ s{::}{-}g;

	print "\n";
	my @no_index = $self->no_index;
	if (@no_index) {
		print "[MetaNoIndex]\n";
		foreach (@no_index) {
			print "directory = $_\n" if $_ ne 'inc';
		}
		print "\n";
	}

	if (defined -d File::Spec->catdir($App::Midgen::Working_Dir, 'share')) {
		print "[ShareDir]\n";
		print "dir = share\n\n";
	}

	if (defined -d File::Spec->catdir($App::Midgen::Working_Dir, 'script')) {
		print "[ExecDir]\n";
		print "dir = script\n\n";
	}
	elsif (defined -d File::Spec->catdir($App::Midgen::Working_Dir, 'bin')) {
		print "[ExecDir]\n";
		print "dir = bin\n\n";
	}

	if ($self->verbose > 0) {
		print BRIGHT_BLACK;
		print "[MetaResources]\n";
		print "homepage          = https://github.com/.../$package_name\n";
		print "bugtracker.web    = https://github.com/.../$package_name/issues\n";
		print "bugtracker.mailto = ...\n";
		print "repository.url    = git://github.com/.../$package_name.git\n";
		print "repository.type   = git\n";
		print "repository.web    = https://github.com/.../$package_name";
		print "\n";

		print "[Meta::Contributors]\n";
		print "contributor = brian d foy (ADOPTME) <brian.d.foy\@gmail.com>\n";
		print "contributor = Fred Bloggs <fred\@bloggs.org>\n";
		print CLEAR "\n";
	}

	return;
}


no Moo;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Midgen::Role::Output::Dist - Output Format - dist.ini,
used by L<App::Midgen>

=head1 VERSION

version: 0.34

=head1 DESCRIPTION

The output format uses colour to add visualization of module version number
types, be that mcpan, dual-life or added distribution.

=head1 METHODS

=over 4

=item * header_dist

=item * body_dist

=item * footer_dist

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

