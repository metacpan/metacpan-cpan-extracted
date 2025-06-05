# Copyright (c) 2023-2025 Löwenfelsen UG (haftungsbeschränkt)

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: format independent identifier object


package Data::Identifier::Interface::Known;

use v5.20;
use strict;
use warnings;

use Carp;
use Data::Identifier;

our $VERSION = v0.16;

my @_subobjects = qw(db extractor store fii);


sub known {
    my ($pkg, $class, %opts) = @_;
    my $as = $opts{as} // 'raw';
    my ($list, %extra) = eval {$pkg->_known_provider($class)};
    my $listas = $opts{listas};

    if (defined $list) {
        if ($extra{not_identifiers}) {
            if (!defined($listas)) {
                if ($as eq 'raw' || (defined($extra{rawtype}) && $as eq $extra{rawtype})) {
                    return @{$list};
                }
            }
        } else {
            my @res;

            if ($opts{skip_invalid}) {
                @res = grep {defined} map {eval {$_->Data::Identifier::as($as, %opts{@_subobjects, qw(no_defaults)}, %extra{qw(rawtype)})}} @{$list};
            } else {
                @res = map {$_->Data::Identifier::as($as, %opts{@_subobjects, qw(no_defaults)}, %extra{qw(rawtype)})} @{$list};
            }

            if (defined($listas)) {
                require Data::Identifier::Cloudlet;
                return Data::Identifier::Cloudlet->new(root => \@res, %opts{@_subobjects})->as($listas, %opts{@_subobjects});
            }

            return @res;
        }
    }

    return @{$opts{default}} if exists $opts{default};
    croak 'Unsupported class or options';
}


sub _known_provider {
    my ($pkg, $class, %opts) = @_;
    croak 'Unsupported options passed' if scalar(keys %opts);
    return ([]) if $class eq ':all';
    croak 'Unsupported class';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Identifier::Interface::Known - format independent identifier object

=head1 VERSION

version v0.16

=head1 SYNOPSIS

    use parent 'Data::Identifier::Interface::Known';

Interface for modules implementing C<known()>.

B<Note:>
This interface is considered B<stable since v0.13> but for the details marked as experimental below.
Ignoring experimental details and considering the C<store> parameter to L</known> being C<undef> this interface has not changed between v0.08 and v0.13.

=head1 METHODS

=head2 known

    my @list = Some::Package->known($class [, %opts ] );
    # or:
    my @list = $obj->known($class [, %opts ] );

Returns a list of known tags (subjects, keys, ...) for the given C<$class>.
If the C<$class> is unknown or unsupported this method C<die>s.

C<$class> is a string with the name of the class to return known items for.

Strings that do not contain colons (C<:>) have a meaning defined by the module.
Classes that include a colon are defined by this interface.
The only such class currently defined is C<:all> which should return known entries
for all classes known by the module.

Future version of this module might allow for non-string values.
If they are encountered but not supported the implementation should C<die> as with other unknown classes.

The implementation should avoid returning the same entry multiple times. However the caller must not assume:

=over

=item *

Entries to be unique within the returned list.

=item *

Entries to be in any specific order.

=item *

The returned entries to be the same for any two calls.

=back

The following (all optional) options are supported:

=over

=item C<as>

The type to be used for returned items.
It must be one of
C<raw> (the return type is defined by the module and the class),
C<uuid>, or C<oid>, or C<uri> (returning the tag's identifier as UUID, OID, or URI),
C<ise> (returning the tag's identifier as ISE),
C<URI> (the same as C<uri> but the value is returned as an instance of L<URI> rather than as string),
C<Data::Identifier> (as an instance of L<Data::Identifier>),
or any other package name (containing two C<::> or starting with a upper case letter).

If a value is given that is not supported for all items to be returned the method must C<die>.

=item C<db>

An instance of L<Data::TagDB>. See L<Data::Identifier/as> for more details.

=item C<default>

The default value to be returned if the class is unknown or unsupported.
This must be an array reference.
It is common to set this to C<[]> to return an empty list when this method would otherwise C<die>.

=item C<extractor>

An instance of L<Data::URIID>. See L<Data::Identifier/as> for more details.

=item C<fii>

A L<File::Information> instance.

=item C<listas>

The package the list should be returned as.

Supported values are those as C<$as> of L<Data::Identifier::Cloudlet/as>.
All restrictions of L<Data::Identifier::Cloudlet/new> apply.
Defaults to C<undef>.

B<Note:>
This option is experimental.

=item C<no_defaults>

See L<Data::Identifier/as> for the use of C<no_defaults>.

=item C<skip_invalid>

If set true, entries that cannot satisfy the given requirements (most likely C<as>)
are skipped from the output without C<die>ing.

=item C<store>

A L<File::FStore> instance.

=back

The default implementation fits the above requirements.
It calls L</_known_provider>. Return values are automatically converted as needed.
The returned list is protected against mutation.

=head2 _known_provider

    my ($list, %extra) = $pkg->_known_provider($class, %opts);

This method is used by the default implementation of L</known> to get the required list.
If you override L</known> this method can stay unimplemented.

This method should return a list of known objects matching C<$class> as it's first return value.
(Automatic type conversion is performed by L</known>, but see also extra values below.)
It may also return extra information as a hash (not a hash reference).

If C<$class> is unknown or unsupported the method should C<die>.

The default implementation returns an empty list for the class C<:all> and C<die>s otherwise.

Optionally options are passed. If an option is passed that is not supported this method should C<die>.
Currently no options are defined. An implementation can therefore use:

    die 'Unsupported options passed' if scalar(keys %opts);

The following extra values are supported:

=over

=item C<rawtype>

The type assumed when L</known> is passed C<as =E<gt> 'raw'>

=item C<not_identifiers>

If true the returned list contains non-identifier values.
A non-identifier value is defined as any value that cannot be passed
to L<Data::Identifier/new> via C<from>.

=back

=head1 AUTHOR

Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2023-2025 by Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
