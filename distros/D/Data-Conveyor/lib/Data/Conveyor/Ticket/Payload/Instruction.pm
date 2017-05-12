use 5.008;
use strict;
use warnings;

package Data::Conveyor::Ticket::Payload::Instruction;
BEGIN {
  $Data::Conveyor::Ticket::Payload::Instruction::VERSION = '1.103130';
}
# ABSTRACT: Stage-based conveyor-belt-like ticket handling system

# ptags: DCTPI
use Class::Value;
use parent 'Class::Scaffold::Storable';
use overload
  'eq' => 'eq',
  '""' => 'stringify';
__PACKAGE__
    ->mk_scalar_accessors(qw(command))
    ->mk_object_accessors('Class::Value' => 'value');

# Override type() in subclasses. Override value() as well; should be a value
# object corresponding to the type of instruction.
use constant type => '';

sub eq {
    my ($lhs, $rhs) = @_;
    (sprintf "%s", $lhs) eq (sprintf "%s", $rhs);
}

sub stringify {
    my $self = shift;
    sprintf 'command [%s], type [%s], value [%s]',
      $self->command, $self->type, $self->value;
}

sub check {
    my ($self, $exception_container) = @_;
    $self->value->run_checks_with_exception_container($exception_container);
}
1;


__END__
=pod

=head1 NAME

Data::Conveyor::Ticket::Payload::Instruction - Stage-based conveyor-belt-like ticket handling system

=head1 VERSION

version 1.103130

=head1 METHODS

=head2 check

FIXME

=head2 eq

FIXME

=head2 stringify

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

