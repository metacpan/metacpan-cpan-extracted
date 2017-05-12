package App::Midgen::Role::Output::Infile;

use constant {
	BLANK => q{ },
	NONE => q{},
	THREE => 3,
	EIGHT => 8,
	NINE => 9,
	TEN => 10
};

use Moo::Role;
requires qw( core dual_life debug );
use Try::Tiny;

# Load time and dependencies negate execution time
# use namespace::clean -except => 'meta';

our $VERSION = '0.34';
$VERSION = eval $VERSION;    ## no critic

use English qw( -no_match_vars );
local $OUTPUT_AUTOFLUSH = 1;

use Term::ANSIColor qw( :constants colored );
use Data::Printer {caller_info => 1,};
use File::Spec;

#######
# header_infile
#######
sub header_infile {
	my $self = shift;

	print qq{\n};

	return;
}
#######
# body_infile
#######
sub body_infile {
	my $self = shift;

	return;
}
#######
# footer_infile
#######
sub footer_infile {
	my $self = shift;

	p $self->{modules} if $self->debug;

	# Let's work out our padding
	my $pm_length  = 0;
	my $dir_length = 0;
	foreach my $module_name (sort keys %{$self->{modules}}) {

		if (length $module_name > $pm_length) {
			$pm_length = length $module_name;
		}
		try {
			foreach my $foundin (sort @{$self->{modules}{$module_name}{infiles}}) {
				if (length $foundin->[0] > $dir_length) {
					$dir_length = length $foundin->[0];
				}
			}
		};

	}

	print "  "
		. "-" x $pm_length
		. "-" x EIGHT
		. "-" x TEN
		. "-" x $dir_length
		. "-" x TEN . "\n";


	printf " | %-*s | %-*s | %-*s | %-*s |\n", $pm_length, 'Module', EIGHT,
		'Version ', EIGHT, 'Installed', $dir_length, 'Found in';
	print "  "
		. "-" x $pm_length
		. "-" x EIGHT
		. "-" x TEN
		. "-" x $dir_length
		. "-" x TEN . "\n";


	foreach my $module_name (sort keys %{$self->{modules}}) {

		# honnor options dual-life and core module display
		if ($self->core) {

			# do nothing
		}
		elsif ($self->dual_life) {
			next
				if ($self->{modules}{$module_name}{corelist}
				and not $self->{modules}{$module_name}{dual_life});
		}
		else {
			next if $self->{modules}{$module_name}{corelist};
		}

		try {
			foreach my $foundin (sort @{$self->{modules}{$module_name}{infiles}}) {
				my $dir_relative = $foundin->[0];
				$dir_relative =~ s{^/}{};
				printf " | %-*s | %-*s | %-*s | %-*s |\n", $pm_length, $module_name,
					EIGHT, $foundin->[1], NINE, $self->in_local_lib($module_name),
					$dir_length, $dir_relative,;
			}
		};
	}

	print "  "
		. "-" x $pm_length
		. "-" x EIGHT
		. "-" x TEN
		. "-" x $dir_length
		. "-" x TEN . "\n";

	print qq{\n};

	return;
}

no Moo;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Midgen::Role::Output::Infile - Modules and files they were found in,
used by L<App::Midgen>

=head1 VERSION

version: 0.34

=head1 DESCRIPTION

This output format list modules found against the files they were Included in.

=head1 METHODS

=over 4

=item * header_infile

=item * body_infile

=item * footer_infile

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
