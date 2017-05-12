package App::Midgen::Role::Output::EUMM;

use constant {
	BLANK  => q{ },
	NONE   => q{},
	THREE  => q{   },
	SIX    => q{      },
	NINE   => q{         },
	TWELVE => q{            },
};

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
# header_eumm
#######
sub header_eumm {
	my $self = shift;
	my $package_name = shift || NONE;

	if ($package_name ne NONE) {

		print "\nuse strict;\n";
		print "use warnings;\n";
		print "use ExtUtils::MakeMaker 6.68;\n\n";

		print "WriteMakefile(\n";
		print THREE. "'NAME' => '$package_name',\n";
		$package_name =~ s{::}{/}g;
		print THREE. "'VERSION_FROM' => 'lib/$package_name.pm',\n";
		print THREE. "'ABSTRACT_FROM' => 'lib/$package_name.pm',\n";

		print BRIGHT_BLACK;
		print THREE. "'AUTHOR' => '...',\n";
		print THREE. "'LICENSE' => 'perl',\n";
		print CLEAR;
## 6.64 f***** RT#85406
		print THREE. "'BUILD_REQUIRES' => {\n";
		print SIX. "'ExtUtils::MakeMaker' => '6.68',\n";
		print THREE. "},\n";
		print THREE. "'CONFIGURE_REQUIRES' => {\n";
		print SIX. "'ExtUtils::MakeMaker' => '6.68',\n";
		print THREE. "},\n";
	}

	return;
}
#######
# body_eumm
#######
sub body_eumm {
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

	print THREE. "'MIN_PERL_VERSION' => '$App::Midgen::Min_Version',\n"
		if $title eq 'RuntimeRequires';

#	return if not %{$required_ref} and $title =~ m{(?:requires)\z};

	if ($title eq 'RuntimeRequires') {
		print THREE. "'PREREQ_PM' => {\n";
	}
	elsif ($title eq 'TestRequires') {
		print THREE. "'TEST_REQUIRES' => {\n";
	}
	elsif ($title eq 'recommends') {
		$self->_recommends($required_ref);
		return;
	}

	foreach my $module_name (sort keys %{$required_ref}) {

		next
			if $title eq 'TestRequires'
			&& $required_ref->{$module_name} =~ m/mcpan/;

		my $sq_key = q{'} . $module_name . q{'};
		printf SIX. " %-*s => '%s',\n", $pm_length + 2, $sq_key,
			$required_ref->{$module_name};
	}
	print THREE. "},\n";

	return;
}

sub _recommends {
	my $self         = shift;
	my $required_ref = shift;

	my $pm_length = 0;
	foreach my $module_name (sort keys %{$required_ref}) {
		if (length $module_name > $pm_length) {
			$pm_length = length $module_name;
		}
	}
	print THREE. "'META_MERGE' => {\n";
	print SIX. "'meta-spec' => { 'version' => '2' },\n";
	return if not %{$required_ref};
	print SIX. "'prereqs' => {\n";
	print NINE. "'test' => {\n";
	print TWELVE. "'suggests' => {\n";
	foreach my $module_name (sort keys %{$required_ref}) {

		my $sq_key = q{'} . $module_name . q{'};
		printf "%-15s %-*s => '%s',\n", BLANK, $pm_length + 2, $sq_key,
			$required_ref->{$module_name};
	}
	print TWELVE. "}\n";
	print NINE. "}\n";
	print SIX. "},\n";

}


#######
# footer_eumm
#######
sub footer_eumm {
	my $self = shift;
	my $package_name = shift || NONE;
	$package_name =~ s{::}{-}g;

	if ($self->verbose > 0) {
		print BRIGHT_BLACK;

		print SIX. "'resources' => {\n";

		print NINE. "'bugtracker' => {\n";
		print TWELVE. "'web' => 'https://github.com/.../$package_name/issues',\n";
		print NINE. "},\n";

		print NINE. "'homepage' => 'https://github.com/.../$package_name',\n";

		print NINE. "'repository' => {\n";
		print TWELVE. "'type' => 'git',\n";
		print TWELVE. "'url' => 'git://github.com/.../$package_name.git',\n";
		print TWELVE. "'web' => 'https://github.com/.../$package_name',\n";
		print NINE. "},\n";
		print SIX. "},\n";

		print SIX. "'x_contributors' => [\n";
		print NINE. "'brian d foy (ADOPTME) <brian.d.foy\@gmail.com>',\n";
		print NINE. "'Fred Bloggs <fred\@bloggs.org>',\n";
		print SIX. "],\n";

		print CLEAR;
		print THREE. "},\n";

	}

	if (defined -d File::Spec->catdir($App::Midgen::Working_Dir, 'script')) {
		print THREE. "'EXE_FILES' => [ (\n";
		print SIX. "'script/...'\n";
		print THREE. ") ],\n";
	}
	elsif (defined -d File::Spec->catdir($App::Midgen::Working_Dir, 'bin')) {
		print THREE. "'EXE_FILES' => [qw(\n";
		print SIX. "bin/...\n";
		print THREE. ")],\n";
	}

	print ")\n\n";

	return;
}

no Moo;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Midgen::Role::Output::EUMM - Output Format - ExtUtils::MakeMaker,
used by L<App::Midgen>

=head1 VERSION

version: 0.34

=head1 DESCRIPTION

The output format uses colour to add visualization of module version number
types, be that mcpan, dual-life or added distribution.

=head1 METHODS

=over 4

=item * header_eumm

=item * body_eumm

=item * footer_eumm

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

