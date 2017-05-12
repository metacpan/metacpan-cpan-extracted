package DPKG::Log::Analyse::Package;
BEGIN {
  $DPKG::Log::Analyse::Package::VERSION = '1.20';
}


=head1 NAME

DPKG::Log::Analyse::Package - Describe a package as analysed from a dpkg.log

=head1 VERSION

version 1.20

=head1 SYNOPSIS

use DPKG::Log;

my $package = DPKG::Log::Analyse::Package->new('package' => 'foobar');

=head1 DESCRIPTION

This module is used to analyse a dpkg log.

=head1 METHODS

=over 4

=cut

use strict;
use warnings;
use 5.010;

use Carp;
use DPKG::Log;
use Dpkg::Version;
use Params::Validate qw(:all);

use overload (
    '""' => 'as_string',
    'eq' => 'equals',
    'cmp' => 'compare',
    '<=>' => 'compare'
);

=item $package = DPKG::Log::Analyse::Package->new('package' => 'foobar')

Returns a new DPKG::Log::Analyse::Package object.

=cut
sub new {
    my $package = shift;
    $package = ref($package) if ref($package);

    my %params = validate(
        @_, {
                'package' => { 'type' => SCALAR },
                'version' => 0,
                'previous_version' => 0,
                'status' => 0
            }
    );
    
    my $self = {
        version => "",
        previous_version => "",
        status => "",
        %params
    };

    bless($self, $package);
    return $self;
}

=item $package_name = $package->name;

Returns the name of this package.

=cut
sub name {
    my $self = shift;
    return $self->{package};
}

=item $package->version

Return or set the version of this package.

=cut
sub version {
    my ($self, $version) = @_;
    if ($version) {
        my $version_obj = Dpkg::Version->new($version);
        $self->{version} = $version_obj;
    } else {
        $version = $self->{version};
    }
    return $version;
}

=item $package->previous_version

Return or set the previous version of this package.

=cut
sub previous_version {
    my ($self, $previous_version) = @_;
    if ($previous_version) {
        my $version_obj = Dpkg::Version->new($previous_version);
        $self->{previous_version} = $version_obj;
    } else {
        $previous_version = $self->{previous_version};
    }
    return $previous_version;
}

=item $package->status

Return or set the status of this package.

=cut
sub status {
    my ($self, $status) = @_;
    if ($status) {
        $self->{status} = $status;
    } else {
        $status = $self->{status}
    }
    return $status;
}

=item equals($package1, $package2);

=item print "equal" if $package1 eq $package2

Compares two packages in their string representation.

=cut
sub equals {
    my ($first, $second) = @_;
    return ($first->as_string eq $second->as_string);
}


=item compare($package1, $package2)

=item print "greater" if $package1 > $package2

Compare two packages. See B<OVERLOADING> for details on how
the comparison works.
=cut
sub compare {
    my ($first, $second) = @_;
    return -1 if ($first->name ne $second->name);
    if ((not $first->previous_version) and (not $second->previous_version)) {
        return ($first->version <=> $second->version);
    } elsif ((not $first->previous_version) or (not $second->previous_version)) {
        return -1;
    } elsif ($first->previous_version != $second->previous_version) {
        return -1;
    }
    
    return (($first->version <=> $second->version));

}

=item $package_str = $package->as_string

=item printf("Package name: %s", $package);

Return this package as a string. This will return the package name
and the version (if set) in the form package_name/version.
If version is not set, it will return the package name only.

=cut
sub as_string {
    my $self = shift;

    my $string = $self->{package};
    if ($self->version) {
        $string = $string . "/" . $self->version;
    }
    return $string;
}

=back

=head1 Overloading

This module explicitly overloads some operators.
Each operand is expected to be a DPKG::Log::Analyse::Package object.

The string comparison operators, "eq" or "ne" will use the string value for the
comparison.

The numerical operators will use the package name and package version for
comparison. That means a package1 == package2 if package1->name equals
package2->name AND package1->version == package2->version.

The module stores versions as Dpkg::Version objects, therefore sorting
different versions of the same package will work.

This module also overloads stringification returning either the package
name if no version is set or "package_name/version" if a version is set. 

=cut

=head1 SEE ALSO

L<DPKG::Log>, L<DPKG::Version>

=head1 AUTHOR

Patrick Schoenfeld <schoenfeld@debian.org>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 Patrick Schoenfeld <schoenfeld@debian.org>

This library is free software.
You can redistribute it and/or modify it under the same terms as perl itself.

=cut

1;
# vim: expandtab:ts=4:sw=4