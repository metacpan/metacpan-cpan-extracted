#Copyright barry king <barry@wyrdwright.com> and released under the GPL.
#See http://www.gnu.org/licenses/gpl.html#TOC1 for details
use 5.006;
use strict;
use warnings;
no warnings qw(uninitialized);

package Apache::Wyrd::Interfaces::Mother;
use base qw(Apache::Wyrd::Interfaces::Setter);
our $VERSION = '0.98';

=pod

=head1 NAME

Apache::Wyrd::Interfaces::Mother - Reverse-parsing interface for Wyrds

=head1 SYNOPSIS

NONE

=head1 DESCRIPTION

If the enclosing Wyrd is the parent of an enclosed wyrd, the Mother
interface allows "children" of a Wyrd to be processed AFTER the parent,
reversing the normal flow of interpretation and calling the C<output>
method.

This is used, for example, in Forms, where the C<Apache::Wyrd::Form>
will need to alter values in the enclosed C<Apache::Wyrd::Input>s and
similar children after they have been parsed.

To accomplish this, every child must call the C<register_child> method. 
This will give the mother a private attribute C<_children> containing an
arrayref to the child objects.

When the mother has manipulated its children via access to the
C<_children> arrayref, it calls C<_set_children> to output the children
to their place within the enclosed HTML.  For this to function, each
child must have a C<final_output> method to call, and must output
C<'$:'>+ the id returned by the C<_register_child> method.  Typically
this is done with the following code:

    $self->_data('$:' . $id);

=head1 METHODS

I<(format: (returns) name (accepts))>

=over

=item (void) C<_set_children> ([string])

Prior to producing output, the mother should, assuming C<_data> contains
the enclosed data at the time, call C<_set_children> to perform the
delayed processing of its children.  Set children operates on the _data
attribute, so be sure the children's placemarkers are in _data before
calling this method.

When used with the optional argument, that attribute is assumed to be the
storage place for the children rather than _data.

=cut

sub _set_children {
	my ($self, $attribute) = @_;
	$attribute ||= '_data';
	my $out = $self->{$attribute};
	my $children = $self->_child_hash;
	$self->{$attribute} = $self->_set($children, $out);
}

=pod

=item (scalar) C<register_child> (void)

Adds the child to the mother's C<_children> attribute and returns a
placemarker string the mother will use to find it.  Every child of the
mother should call register_child.  In so doing, it should set it's
output (usually during the C<_generate_output> phase) with the string
"$:B<idname>" where B<idname> is the id returned by this method.  It can
do this in any way it likes, for example by replacing it's _data
attribute, as long as it's C<output> method returns this value.

=cut

sub register_child {
	my ($self, $child) = @_;
	$self->{'_children'} = [] unless ($self->{'_children'});
	my $child_count = $#{$self->{'_children'}} + 1;
	my $id = $self->_name_child;
	push @{$self->{'_children'}}, $child;
	$self->{'_child_index'}->{$id} = $child_count;
	$self->_process_child($child);
	return $id;
}

=pod

=item (scalar) C<_process_child> (Apache::Wyrd-derived object)

Hook method for performing some action on or using each child.

=cut

sub _process_child {
	#hook for child processing
	return;
}

=pod

=back

=head1 BUGS/CAVEATS/RESERVED METHODS

The methods C<_name_child>, C<_generate_id>, C<_set_children>, and
C<_child_hash> are reserved by this interface.

Children must ensure that the '$:' string before the ID string is not
interpreted by perl as the $: variable, i.e. use single quotes/q()
around the string.  See C<Apache::Wyrd::Interfaces::Setter>.

=head1 AUTHOR

Barry King E<lt>wyrd@nospam.wyrdwright.comE<gt>

=head1 SEE ALSO

=over

=item Apache::Wyrd

General-purpose HTML-embeddable perl object

=back

=head1 LICENSE

Copyright 2002-2007 Wyrdwright, Inc. and licensed under the GNU GPL.

See LICENSE under the documentation for C<Apache::Wyrd>.

=cut

sub _name_child {
	my ($self) = @_;
	my $id = $self->_generate_id($self->{'_current_identifier'});
	$self->{'_current_identifier'} = $self->{'_current_identifier'} + 1;
	return $id;
}

sub _generate_id {
	my ($self, $sequence) = @_;
	return '_PLACEMARKER_' . substr("000000$sequence", -6);
}

sub _child_hash {
	my ($self) = @_;
	my %children = ();
	foreach my $child (keys(%{$self->{'_child_index'}})) {
		$self->_verbose("processing child $child :" . $self->{'_child_index'}->{$child} . ' : ' . $self->{'_children'}->[$self->{'_child_index'}->{$child}]->{'name'});
		my $object = $self->{'_children'}->[$self->{'_child_index'}->{$child}];
		my $output = $object->final_output;
		$children{$child} = $output;
	}
	return \%children;
}

1;