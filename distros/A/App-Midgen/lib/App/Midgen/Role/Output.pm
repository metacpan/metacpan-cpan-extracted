package App::Midgen::Role::Output;

use Moo::Role;
with qw(
	App::Midgen::Role::Output::CPANfile
	App::Midgen::Role::Output::Dist
	App::Midgen::Role::Output::EUMM
	App::Midgen::Role::Output::Infile
	App::Midgen::Role::Output::MB
	App::Midgen::Role::Output::METAjson
	App::Midgen::Role::Output::MIdsl
	App::Midgen::Role::Output::MI
);
requires qw( format distribution_name get_module_version verbose );

# Load time and dependencies negate execution time
# use namespace::clean -except => 'meta';

our $VERSION = '0.34';
$VERSION = eval $VERSION;    ## no critic

use English qw( -no_match_vars );    # Avoids reg-ex performance penalty
local $OUTPUT_AUTOFLUSH = 1;

use Try::Tiny;


#######
# output_header
#######
sub output_header {
	my $self = shift;

	if ($self->format eq 'dsl') {
		$self->header_dsl($self->distribution_name,
			$self->get_module_version('inc::Module::Install::DSL'));
	}
	elsif ($self->format eq 'mi') {
		$self->header_mi($self->distribution_name,
			$self->get_module_version('inc::Module::Install'));
	}
	elsif ($self->format eq 'dist') {
		$self->header_dist($self->distribution_name);
	}
	elsif ($self->format eq 'cpanfile') {
		$self->header_cpanfile($self->distribution_name,
			$self->get_module_version('inc::Module::Install'))
			if not $self->quiet;
	}
	elsif ($self->format eq 'eumm') {
		$self->header_eumm($self->distribution_name);
	}
	elsif ($self->format eq 'mb') {
		$self->header_mb($self->distribution_name);
	}
	elsif ($self->format eq 'metajson') {
		$self->header_metajson($self->distribution_name);
	}
	elsif ($self->format eq 'infile') {
		$self->header_infile($self->distribution_name);
	}

	return;
}

#######
# output_main_body
#######
sub output_main_body {
	my $self         = shift;
	my $title        = shift || 'title missing';
	my $required_ref = shift;

	if ($self->format eq 'dsl') {
		$self->body_dsl($title, $required_ref);
	}
	elsif ($self->format eq 'mi') {
		$self->body_mi($title, $required_ref);
	}
	elsif ($self->format eq 'dist') {
		$self->body_dist($title, $required_ref);
	}
	elsif ($self->format eq 'cpanfile') {
		$self->body_cpanfile($title, $required_ref);
	}
	elsif ($self->format eq 'eumm') {
		$self->body_eumm($title, $required_ref);
	}
	elsif ($self->format eq 'mb') {
		$self->body_mb($title, $required_ref);
	}
	elsif ($self->format eq 'metajson') {
		$self->body_metajson($title, $required_ref);
	}
	elsif ($self->format eq 'infile') {
		$self->body_infile($title, $required_ref);
	}

	return;
}

#######
# output_footer
#######
sub output_footer {
	my $self = shift;

	if ($self->format eq 'dsl') {
		$self->footer_dsl($self->distribution_name);
	}
	elsif ($self->format eq 'mi') {
		$self->footer_mi($self->distribution_name);
	}
	elsif ($self->format eq 'dist') {
		$self->footer_dist($self->distribution_name);
	}
	elsif ($self->format eq 'cpanfile') {
		$self->footer_cpanfile($self->distribution_name);
	}
	elsif ($self->format eq 'eumm') {
		$self->footer_eumm($self->distribution_name);
	}
	elsif ($self->format eq 'mb') {
		$self->footer_mb($self->distribution_name);
	}
	elsif ($self->format eq 'metajson') {
		$self->footer_metajson($self->distribution_name);
	}
	elsif ($self->format eq 'infile') {
		$self->footer_infile($self->distribution_name);
	}

	return;
}

#######
# no_index
#######
sub no_index {
	my $self = shift;

	#ToDo add more options as and when
	my @dirs_to_check
		= qw( corpus eg examples fbp inc maint misc privinc share t xt );
	my @dirs_found;

	foreach my $dir (@dirs_to_check) {

		#ignore syntax warning for global
		push @dirs_found, $dir
			if -d File::Spec->catdir($App::Midgen::Working_Dir, $dir);
	}
	return @dirs_found;
}

#######
# in_local_lib
#######
sub in_local_lib {
	my $self         = shift;
	my $found_module = shift;

	# exemption for perl :)
	# return $PERL_VERSION if $found_module eq 'perl';
	return $] if $found_module eq 'perl';

	try {
		# Show installed version-string
		# hack from Module::Vesrion
		require ExtUtils::MakeMaker;
		return MM->parse_version(MM->_installed_file_for_module($found_module));
	}
	catch {
		# module not installed in local-lib
		return colored('Missing  ', 'red');
	};
	#return; don't follow pbp as it F's-up
}


no Moo;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Midgen::Role::Output - A collection of output orientated methods used by L<App::Midgen>

=head1 VERSION

version: 0.34

=head1 DESCRIPTION

The output format uses colour to add visualization of module version number
types, be that mcpan, dual-life or added distribution.

=head1 METHODS

=over 4

=item * output_header

=item * output_main_body

=item * output_footer

=item * no_index

Suggest some of your local directories you can 'no_index'

=item * in_local_lib

version string from local-lib or corelist

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

