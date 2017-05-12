use 5.008;
use strict;
use warnings;

package Data::Conveyor::Value::Ticket::Stage;
BEGIN {
  $Data::Conveyor::Value::Ticket::Stage::VERSION = '1.103130';
}
# ABSTRACT: Stage-based conveyor-belt-like ticket handling system


# we need a delegate and therefore need the proper subclasses
use parent qw(
  Class::Value
  Class::Scaffold::Storable
);
__PACKAGE__->mk_scalar_accessors(qw(name position));

# Alternative constructor: only takes a name, sets start position
sub pos_name_start {
    my $self = shift;
    $self->delegate->STAGE_START;
}

sub pos_name_active {
    my $self = shift;
    $self->delegate->STAGE_ACTIVE;
}

sub pos_name_end {
    my $self = shift;
    $self->delegate->STAGE_END;
}

sub new_from_name {
    my ($self, $name, %args) = @_;
    $self->new(
        value => sprintf('%s_%s', $self->pos_name_start, $name),
        %args
    );
}

sub new_start {
    my $self = shift;
    $self->new_from_name(@_)->set_start;
}

sub new_active {
    my $self = shift;
    $self->new_from_name(@_)->set_active;
}

sub new_end {
    my $self = shift;
    $self->new_from_name(@_)->set_end;
}

sub get_value {
    my $self = shift;
    return unless $self->position && $self->name;
    sprintf '%s_%s', $self->position, $self->name;
}

sub set_value {
    my ($self,     $value) = @_;
    my ($position, $name)  = $self->split_value($value);
    $self->position($position);
    $self->name($name);
    $self;
}

# expects a string like 'ende_policy'
sub is_well_formed_value {
    my ($self, $value) = @_;
    $self->SUPER::is_well_formed_value($value)
      && defined $self->split_value($value);
}

sub split_value {
    my ($self, $value) = @_;
    our $pos_re ||= join '|' =>
      ($self->pos_name_start, $self->pos_name_active, $self->pos_name_end);
    return unless defined($value) && length($value);
    return unless $value =~ /^($pos_re)_([\w_]+)$/;
    return ($1, $2);
}

# these methods return $self to allow chaining
sub set_start  { $_[0]->position($_[0]->pos_name_start);  $_[0] }
sub set_active { $_[0]->position($_[0]->pos_name_active); $_[0] }
sub set_end    { $_[0]->position($_[0]->pos_name_end);    $_[0] }
sub is_start  { $_[0]->position eq $_[0]->pos_name_start }
sub is_active { $_[0]->position eq $_[0]->pos_name_active }
sub is_end    { $_[0]->position eq $_[0]->pos_name_end }
1;


__END__
=pod

=head1 NAME

Data::Conveyor::Value::Ticket::Stage - Stage-based conveyor-belt-like ticket handling system

=head1 VERSION

version 1.103130

=head1 METHODS

=head2 get_value

FIXME

=head2 is_active

FIXME

=head2 is_end

FIXME

=head2 is_start

FIXME

=head2 is_well_formed_value

FIXME

=head2 new_active

FIXME

=head2 new_end

FIXME

=head2 new_from_name

FIXME

=head2 new_start

FIXME

=head2 pos_name_active

FIXME

=head2 pos_name_end

FIXME

=head2 pos_name_start

FIXME

=head2 set_active

FIXME

=head2 set_end

FIXME

=head2 set_start

FIXME

=head2 set_value

FIXME

=head2 split_value

FIXME

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org/Public/Dist/Display.html?Name=Data-Conveyor>.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<http://search.cpan.org/dist/Data-Conveyor/>.

The development version lives at L<http://github.com/hanekomu/Data-Conveyor>
and may be cloned from L<git://github.com/hanekomu/Data-Conveyor>.
Instead of sending patches, please fork this project using the standard
git and github infrastructure.

=head1 AUTHORS

=over 4

=item *

Marcel Gruenauer <marcel@cpan.org>

=item *

Florian Helmberger <fh@univie.ac.at>

=item *

Achim Adam <ac@univie.ac.at>

=item *

Mark Hofstetter <mh@univie.ac.at>

=item *

Heinz Ekker <ek@univie.ac.at>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2004 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

