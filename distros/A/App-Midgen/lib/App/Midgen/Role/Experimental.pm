package App::Midgen::Role::Experimental;

our $VERSION = '0.34';
$VERSION = eval $VERSION;    ## no critic

use constant {THREE => 3,};

use Types::Standard qw( Bool );
use Moo::Role;
#requires qw( debug );

use Try::Tiny;
use Data::Printer {caller_info => 1,};
use Term::ANSIColor qw( :constants colored colorstrip );
use List::MoreUtils qw(firstidx);


#######
# composed method degree of separation
# parent A::B - child A::B::C
#######
sub degree_separation {
	my $self   = shift;
	my $parent = shift;
	my $child  = shift;

	# Use of implicit split to @_ is deprecated
	my $parent_score = @{[split /::/, $parent]};
	my $child_score  = @{[split /::/, $child]};
	warn 'parent - ' . $parent . ' score - ' . $parent_score if $self->debug;
	warn 'child - ' . $child . ' score - ' . $child_score    if $self->debug;

	# switch around for a positive number
	return $child_score - $parent_score;
}


#######
# remove_noisy_children
#######
sub remove_noisy_children {
	my $self = shift;
	my $required_ref = shift || return;
	my @sorted_modules;

	foreach my $module_name (sort keys %{$required_ref}) {
		push @sorted_modules, $module_name;
	}

	p @sorted_modules if $self->debug;

	foreach my $parent_name (@sorted_modules) {
		my $outer_index = firstidx { $_ eq $parent_name } @sorted_modules;

		# inc so we don't end up with parent eq child
		$outer_index++;
		foreach my $inner_index ($outer_index .. $#sorted_modules) {
			my $child_name = $sorted_modules[$inner_index];

			# we just caught an undef
			next if not defined $child_name;
			if ($child_name =~ /^ $parent_name ::/x) {

				my $valied_seperation = 1;

				# as we only do this against -x, why not be extra vigilant
				$valied_seperation = THREE
					if $parent_name =~ /^Dist::Zilla|Moose|MooseX|Moo|Mouse/;

				# Checking for one degree of separation
				# ie A::B -> A::B::C is ok but A::B::C::D is not
				if ($self->degree_separation($parent_name, $child_name)
					<= $valied_seperation)
				{

					# Test for same version number
					if (colorstrip($required_ref->{$parent_name}) eq
						colorstrip($required_ref->{$child_name}))
					{
						if (not $self->quiet) {
							if ($self->verbose) {
								print BRIGHT_BLACK;
								print 'delete miscreant noisy child '
									. $child_name . ' => '
									. $required_ref->{$child_name};
								print CLEAR. "\n";
							}
						}
						try {
							delete $required_ref->{$child_name};
							splice @sorted_modules, $inner_index, 1;

							unless ($self->{modules}{$parent_name}) {
								$self->{modules}{$parent_name}{prereqs} = 'expermental';
								$self->{modules}{$parent_name}{version}
									= $required_ref->{$parent_name};
								$self->{modules}{$parent_name}{count} += 1;
							}
						};
						p @sorted_modules if $self->debug;

						# we need to redo as we just deleted a child
						redo;

					}
					else {

						# not my child so lets try the next one
						next;
					}
				}
			}
			else {

				# no more like the parent so lets start again
				last;
			}
		}
	}
	return;
}


#######
# remove_twins
#######
sub remove_twins {
	my $self = shift;
	my $required_ref = shift || return;
	my @sorted_modules;
	foreach my $module_name (sort keys %{$required_ref}) {
		push @sorted_modules, $module_name;
	}

	p @sorted_modules if $self->debug;

	# exit if only 1 Module found
	return if $#sorted_modules == 0;

	my $n = 0;
	while ($sorted_modules[$n]) {

		my $dum_name    = $sorted_modules[$n];
		my $dum_parient = $dum_name;
		$dum_parient =~ s/(::\w+)$//;

		my $dee_parient;
		my $dee_name;
		if (($n + 1) <= $#sorted_modules) {
			$n++;
			$dee_name    = $sorted_modules[$n];
			$dee_parient = $dee_name;
			$dee_parient =~ s/(::\w+)$//;
		}

		# Checking for same patient and score
		if ( $dum_parient eq $dee_parient
			&& $self->degree_separation($dum_name, $dee_name) == 0)
		{

			# Test for same version number
			if ($required_ref->{$sorted_modules[$n - 1]} eq
				$required_ref->{$sorted_modules[$n]})
			{
				if (not $self->quiet) {
					if ($self->verbose) {
						print BRIGHT_BLACK;

						# stdout - 'i have found twins';
						print $dum_name . ' => '
							. $required_ref->{$sorted_modules[$n - 1]};
						print BRIGHT_BLACK ' <-twins-> '
							. $dee_name . ' => '
							. $required_ref->{$sorted_modules[$n]};
						print CLEAR "\n";
					}
				}

				#Check for valid parent
				my $version;

				$version = $self->get_module_version($dum_parient);

				if (version::is_lax($version)) {

					#Check parent version against a twins version
					if ($version eq $required_ref->{$sorted_modules[$n]}) {
						print $dum_parient . ' -> '
							. $version
							. " is the parent of these twins\n"
							if $self->verbose;
						$required_ref->{$dum_parient} = $version;
						$self->_set_found_twins(1);
					}
				}
			}
		}
		$n++ if ($n == $#sorted_modules);
	}
	return;
}

no Moo::Role;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Midgen::Roles::Experimental - used by L<App::Midgen>

=head1 VERSION

version: 0.34

=head1 METHODS

=over 4

=item * degree_separation

now a separate Method, returns an integer.

=item * remove_noisy_children

Parent A::B has noisy Children A::B::C and A::B::D all with same version number.

=item * remove_twins

Twins E::F::G and E::F::H  have a parent E::F with same version number,
 so we add a parent E::F and re-test for noisy children,
 catching triplets along the way.

=item * run

=back

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










