use 5.008;

package CPAN::PackageDetails::Entries;
use strict;
use warnings::register;

our $VERSION = '0.263';

use Carp;
use version;

sub DESTROY { }

=encoding utf8

=head1 NAME

CPAN::PackageDetails::Entries - Handle the collection of records of 02packages.details.txt.gz

=head1 SYNOPSIS

Used internally by CPAN::PackageDetails

=head1 DESCRIPTION

=head2 Methods

=over 4

=item new

Creates a new Entries object. This doesn't do anything fancy. To add
to it, use C<add_entry>.

	entry_class => the class to use for each entry object
	columns     => the column names, in order that you want them in the output

If you specify the C<allow_packages_only_once> option with a true value
and you try to add that package twice, the object will die. See C<add_entry>.

=cut

sub new {
	my( $class, %args ) = @_;

	my %hash = (
		entry_class              => 'CPAN::PackageDetails::Entry',
		allow_packages_only_once => 1,
		allow_suspicious_names   => 0,
		columns                  => [],
		entries                  => {},
		%args
		);

	$hash{max_widths} = [ (0) x @{ $hash{columns} } ];

	bless \%hash, $_[0]
	}

=item entry_class

Returns the class that Entries uses to make a new Entry object.

=cut

sub entry_class { $_[0]->{entry_class} }

=item columns

Returns a list of the column names in the entry

=cut

sub columns { @{ $_[0]->{columns} } };

=item column_index_for( COLUMN )

Returns the list position of the named COLUMN.

=cut

sub column_index_for {
	my( $self, $column ) = @_;


	my $index = grep {
		$self->{columns}[$_] eq $column
		} 0 .. @{ $self->columns };

	return unless defined $index;
	return $index;
	}

=item count

Returns the number of entries. This is not the same as the number of
lines that would show up in the F<02packages.details.txt> file since
this method counts duplicates as well.

=cut

sub count {
	my $self = shift;

	my $count = 0;
	foreach my $package ( keys %{ $self->{entries} } ) {
		$count += keys %{ $self->{entries}{$package} };
		}

	return $count;
	}

=item entries

DEPRECATED: use C<get_hash>

=item get_hash

Returns the list of entries as an hash reference. The hash key is the
package name.

=cut

sub entries  {
	carp "entries is deprecated. Use get_hash instead";
	&get_hash;
	}

sub get_hash { $_[0]->{entries} }

=item allow_packages_only_once( [ARG] )

Set or retrieve the value of the allow_packages_only_once setting. It's
a boolean.

=cut

sub allow_packages_only_once {
	$_[0]->{allow_packages_only_once} = !! $_[1] if defined $_[1];

	$_[0]->{allow_packages_only_once};
	}

=item allow_suspicious_names( [ARG] )

Allow an entry to accept an illegal name. Normally you shouldn't use this,
but PAUSE has made bad files before.

=cut

sub allow_suspicious_names {
	$_[0]->{allow_suspicious_names} = !! $_[1] if defined $_[1];

	$_[0]->{allow_suspicious_names};
	}

=item disallow_alpha_versions( [ARG] )

Set or retrieve the value of the disallow_alpha_versions settings. It's
a boolean.

=cut

sub disallow_alpha_versions {
	$_[0]->{disallow_alpha_versions} = !! $_[1] if defined $_[1];

	$_[0]->{disallow_alpha_versions};
	}

=item add_entry

Add an entry to the collection. Call this on the C<CPAN::PackageDetails>
object and it will take care of finding the right handler.

If you've set C<allow_packages_only_once> to a true value (which is the
default, too), C<add_entry> will die if you try to add another entry with
the same package name even if it has a different or greater version. You can
set this to a false value and add as many entries as you like then use
C<as_unqiue_sorted_list> to get just the entries with the highest
versions for each package.

=cut

sub _parse_version {
	my( $self, $version ) = @_;

	my $warning;
	local $SIG{__WARN__} = sub { $warning = join "\n", @_ };

	my( $parsed, $alpha ) = eval {
		die "Version string is undefined\n" unless defined $version;
		die "Version string is empty\n"     if '' eq $version;
		my $v = version->parse($version);
		map { $v->$_() } qw( numify is_alpha );
		};
	do {
		no warnings 'uninitialized';
		my $at = $@;
		chomp, s/\s+at\s+.*// for ( $at, $warning );
		$warning = undef if $warning =~ m/numify\(\) is lossy/i;
		   if( $at )              { ( 0,       $alpha, $at      ) }
		elsif( defined $warning ) { ( $parsed, $alpha, $warning ) }
		else                      { ( $parsed, $alpha, undef    ) }
		};
	}

sub add_entry {
	my( $self, %args ) = @_;

	$self->_mark_as_dirty;

	# The column name has a space in it, but that looks weird in a
	# hash constructor and I keep doing it wrong. If I type "package_name"
	# I'll just make it work.
	if( exists $args{package_name} ) {
		$args{'package name'} = $args{package_name};
		delete $args{package_name};
		}

	my( $parsed, $alpha, $warning ) = $self->_parse_version( $args{'version'} );

	if( defined $warning and warnings::enabled() ) {
		$warning = "add_entry has a problem parsing [$args{'version'}] for package [$args{'package name'}]: [$warning] I'm using [$parsed] as the version for [$args{'package name'}].\n";
		warnings::warn( $warning );
		}

	if( $self->disallow_alpha_versions && $alpha ) {
		croak "add_entry interprets [$parsed] as an alpha version, and disallow_alpha_versions is on";
		}

	unless( defined $args{'package name'} ) {
		croak "No 'package name' parameter!";
		return;
		}

	unless( $args{'package name'} =~ m/
		^
		[A-Za-z0-9_]+
		(?:
			(?:\::|')
			[A-Za-z0-9_]+
		)*
		\z
		/x || $self->allow_suspicious_names ) {
		croak "Package name [$args{'package name'}] looks suspicious. Not adding it!";
		return;
		}

	if( $self->allow_packages_only_once and $self->already_added( $args{'package name'} ) ) {
		croak "$args{'package name'} was already added to CPAN::PackageDetails!";
		return;
		}

	# should check for allowed columns here
	# XXX: this part needs to change based on storage
	$self->{entries}{
		$args{'package name'}
		}{$args{'version'}
			} = $self->entry_class->new( %args );

	return 1;
	}

sub _mark_as_dirty {
	delete $_[0]->{sorted};
	}

=item already_added( PACKAGE )

Returns true if there is already an entry for PACKAGE.

=cut

# XXX: this part needs to change based on storage
sub already_added { exists $_[0]->{entries}{$_[1]} }

=item as_string

Returns a text version of the Entries object. This calls C<as_string>
on each Entry object, and concatenates the results for all Entry objects.

=cut

sub as_string {
	my( $self ) = @_;

	my $string;

	my( $return ) = $self->as_unique_sorted_list;

	foreach my $entry ( @$return ) {
		$string .= $entry->as_string( $self->columns );
		}

	$string || '';
	}

=item as_unique_sorted_list

In list context, this returns a list of entries sorted by package name
and version. Each package exists exactly once in the list and with the
largest version number seen.

In scalar context this returns the count of the number of unique entries.

Once called, it caches its result until you add more entries.

=cut

sub VERSION_PM () { 9 }
sub as_unique_sorted_list {
	my( $self ) = @_;

	unless( ref $self->{sorted} eq ref [] ) {
		$self->{sorted} = [];

		my %Seen;

		my( $k1, $k2 ) = ( $self->columns )[0,1];

		my $e = $self->get_hash;

		# We only want the latest versions of everything:
		foreach my $package ( sort keys %$e ) {
			my $entries = $e->{$package};
			eval {
				eval { require version } or die "Could not load version.pm!";
				die "Your version of the version module doesn't handle the parse method!"
					unless version->can('parse');
				} or croak( {
					message         => $@,
					have_version    => eval { version->VERSION },
					need_version    => 0.74,
					inc             => [ @INC ],
					error           => VERSION_PM,
					}
				);

			my( $highest_version ) =
				map  { $_->[0] }
				sort { $b->[1] <=> $a->[1] } # sort on version objects
				map  {
					my $w;
					local $SIG{__WARN__} = sub { $w = join "\n", @_ };
					my $v = eval { version->new( $_ ) };
					$w = $w || $@;
					$w = s/\s+at\s+//;
					carp "Version [$_] for package [$package] parses with a warning: [$w]. Using [$v] as the version."
						if $w;
					if( $self->disallow_alpha_versions and $v->is_alpha ) {
						carp "Skipping alpha version [$v] for [$package] while sorting versions.";
						()
						}
					else { [ $_, $v ] }
					}
				keys %$entries;

			push @{ $self->{sorted} }, $entries->{$highest_version};
			}
		}

	my $return = wantarray ?
		$self->{sorted}
			:
		scalar  @{ $self->{sorted} };

	return $return;
	}

=item get_entries_by_distribution( DISTRIBUTION )

Returns the entry objects for the named DISTRIBUTION.

=cut

sub get_entries_by_distribution {
	require CPAN::DistnameInfo;
	my( $self, $distribution ) = @_;
	croak "You must specify a distribution!" unless defined $distribution;

	my @entries =
		grep  { # $_ is the entry hash
			my $info = CPAN::DistnameInfo->new( $_->{'path'} );
			defined $info->dist && $info->dist eq $distribution;
			}
		map { # $_ is the package name
			values %{ $self->{entries}{$_} }
			}
		keys %{ $self->{entries} };
	}

=item get_entries_by_package( PACKAGE )

Returns the entry objects for the named PACKAGE.

=cut

sub get_entries_by_package {
	my( $self, $package ) = @_;

	my @entries =
		map   { values %{$self->{entries}{$package}} }
		grep  { $_ eq $package }
		keys %{ $self->{entries} };
	}

=item get_entries_by_path( PATH )

Returns the entry objects for any entries with PATH.

=cut

sub get_entries_by_path {
	my( $self, $path ) = @_;

	my @entries =
		map   { $self->{entries}{$_}{$path} }
		grep  { exists $self->{entries}{$_}{$path} }
		keys %{ $self->{entries} };
	}

=item get_entries_by_version( VERSION )

Returns the entry objects for any entries with VERSION.

=cut

sub get_entries_by_version {
	my( $self, $version ) = @_;

	my @entries =
		map   { $self->{entries}{$_}{$version} }
		grep  { exists $self->{entries}{$_}{$version} }
		keys %{ $self->{entries} };
	}

=back

=head1 TO DO

=head1 SEE ALSO


=head1 SOURCE AVAILABILITY

This source is in Github:

	https://github.com/briandfoy/cpan-packagedetails

=head1 AUTHOR

brian d foy, C<< <briandfoy@pobox.com> >>

=head1 COPYRIGHT AND LICENSE

Copyright © 2009-2025, brian d foy <briandfoy@pobox.com>. All rights reserved.

You may redistribute this under the terms of the Artistic License 2.0.

=cut

1;

