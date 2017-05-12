package App::Midgen::Role::Output::METAjson;

use constant {
	BLANK  => q{ },
	NONE   => q{},
	THREE  => q{   },
	SIX    => q{      },
	NINE   => q{         },
	TWELVE => q{            },
};

use Moo::Role;
requires qw( no_index verbose );

# Load time and dependencies negate execution time
# use namespace::clean -except => 'meta';

our $VERSION = '0.34';
$VERSION = eval $VERSION; ## no critic

use English qw( -no_match_vars );    # Avoids reg-ex performance penalty
local $OUTPUT_AUTOFLUSH = 1;

use Term::ANSIColor qw( :constants colored );
use Data::Printer {caller_info => 1,};
use File::Spec;

#######
# header_metajson
#######
sub header_metajson {
	my $self = shift;
	my $package_name = shift || NONE;
	$package_name =~ s{::}{-}g;

	print "{\n";
	if ($self->verbose > 0) {
		print BRIGHT_BLACK THREE
			. '"abstract" : "This is a short description of the purpose of the distribution.",' . "\n";
		print THREE . '"author" : "...",' . "\n";
		print THREE . '"dynamic_config" : "0|1",' . "\n";
		print THREE . '"generated_by" : "...",' . "\n";
		print THREE . '"license" : [' . "\n";
		print SIX . '"perl_5"' . "\n";
		print THREE . "],\n";
		print THREE . '"meta-spec" : {' . "\n";
		print SIX . '"url" : "http://search.cpan.org/perldoc?CPAN::Meta::Spec",' . "\n";
		print SIX . '"version" : "2"' . "\n";
		print THREE . '},';
	}
	print CLEAR THREE . '"name" : "' . $package_name . q{",} . "\n";


	if ($self->verbose > 0) {
		print BRIGHT_BLACK THREE . '"release_status" : "stable|testing|unstable",' . "\n";
		print THREE . '"version" : "...",' . "\n";
	}

	return;
}

#######
# body_metajson
#######
sub body_metajson {
	my $self         = shift;
	my $title        = shift;
	my $required_ref = shift || return;

	return if not %{$required_ref};

		if ( $title eq 'RuntimeRequires') {
			print CLEAR THREE . '"prereqs" : {' . "\n";
			print SIX . '"runtime" : {' . "\n";
			print NINE . '"requires" : {' . "\n";

			$required_ref->{'perl'} = $App::Midgen::Min_Version;

			foreach my $module_name (sort keys %{$required_ref}) {
				print TWELVE . "\"$module_name\" : \"$required_ref->{$module_name}\",\n"
					if $required_ref->{$module_name} !~ m/mcpan/;
			}
			print NINE . '}';

			if ($self->verbose > 0) {
				print BRIGHT_BLACK ",\n" . NINE . '"suggests" : {...},' . "\n";
			}
			print CLEAR;

		}
		elsif ( $title eq 'RuntimeRecommends') {
			print NINE . '"recommends" : {' . "\n";
			foreach my $module_name (sort keys %{$required_ref}) {
				print TWELVE . "\"$module_name\" : \"$required_ref->{$module_name}\",\n"
					if $required_ref->{$module_name} !~ m/mcpan/;
			}
			print NINE . "}\n";
		}
		elsif ( $title eq 'TestRequires') {
			print SIX . '"test" : {' . "\n";
			print NINE . '"requires" : {' . "\n";
			foreach my $module_name (sort keys %{$required_ref}) {
				print TWELVE
					. "\"$module_name\" : \""
					. $required_ref->{$module_name} . '",' . "\n"
					if $required_ref->{$module_name} !~ m/mcpan/;
			}
			print NINE . '}';
		}
		elsif ( $title eq 'TestSuggests') {
			if ($required_ref) {
				print ",\n";
				print NINE . '"suggests" : {' . "\n";
				foreach my $module_name (sort keys %{$required_ref}) {
					print TWELVE
						. "\"$module_name\" : \""
						. $required_ref->{$module_name} . '",' . "\n"
						if $required_ref->{$module_name} !~ m/mcpan/;

				}
				print NINE . "}\n";
				print SIX . '}';
			}
			else {
				print "\n";
				print SIX . '}';

			}
		}
		elsif ( $title eq 'DevelopRequires') {
			if ($required_ref) {

				print ",\n";
				print SIX . '"develop" : {' . "\n";
				print NINE . '"requires" : {' . "\n";
				foreach my $module_name (sort keys %{$required_ref}) {
					print TWELVE
						. "\"$module_name\" : \""
						. $required_ref->{$module_name} . '",' . "\n"
						if $required_ref->{$module_name} !~ m/mcpan/;

				}
				print NINE . "}\n";
				print SIX . '}';
			}
		}
#	}

	return;
}

#######
# footer_metajson
#######
sub footer_metajson {
	my $self = shift;
	my $package_name = shift || NONE;
	$package_name =~ s{::}{-}g;

	print "\n";

	print THREE . "},\n";
	my @no_index = $self->no_index;
	if (@no_index) {
		print THREE . '"no_index" : {' . "\n";
		print SIX . '"directory" : [' . "\n";
		foreach my $no_idx (@no_index) {
			print NINE . q{"} . $no_idx . q{",} . "\n";
		}
		print SIX . "]\n";
	}

	if ($self->verbose > 0) {
		print THREE . '},' . "\n";
		print BRIGHT_BLACK THREE . '"resources" : {' . "\n";
		print SIX . '"bugtracker" : {' . "\n";
		print NINE
			. '"web" : "https://github.com/.../'
			. $package_name
			. '/issues"' . "\n";
		print SIX . "},\n";
		print SIX . '"homepage" : "https://github.com/.../' . $package_name . q{",} . "\n";
		print SIX . '"repository" : {' . "\n";
		print NINE . '"type" : "git",' . "\n";
		print NINE . '"url" : "https://github.com/.../' . $package_name . q{.git",} . "\n";
		print NINE . '"web" : "https://github.com/.../' . $package_name . q{"} . "\n";
		print SIX . "}\n";
		print THREE . "},\n";
		print THREE . '"x_contributors" : [' . "\n";
		print SIX . '"brian d foy (ADOPTME) <brian.d.foy@gmail.com>",' . "\n";
		print SIX . '"Fred Bloggs <fred@bloggs.org>"' . "\n";
		print THREE . q{]} . "\n";
	}
	else {
		print THREE . "}\n";
	}

	print CLEAR . "}\n";
	print qq{\n};
	return;
}


no Moo;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Midgen::Role::Output::METAjson - Output Format - META.json,
used by L<App::Midgen>

=head1 VERSION

version: 0.34

=head1 DESCRIPTION

The output format uses colour to add visualization of module version number
types, be that mcpan, dual-life or added distribution.

=head1 METHODS

=over 4

=item * header_metajson

=item * body_metajson

=item * footer_metajson

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

255:	To save a full .LOG file rerun with -g
