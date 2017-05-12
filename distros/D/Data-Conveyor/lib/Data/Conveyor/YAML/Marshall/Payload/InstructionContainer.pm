use 5.008;
use strict;
use warnings;

package Data::Conveyor::YAML::Marshall::Payload::InstructionContainer;
BEGIN {
  $Data::Conveyor::YAML::Marshall::Payload::InstructionContainer::VERSION = '1.103130';
}
# ABSTRACT: Stage-based conveyor-belt-like ticket handling system
use YAML::Marshall 'payload/instructioncontainer';
use YAML 'Dump';
use parent 'Class::Scaffold::YAML::Marshall';

sub yaml_load {
    my $self = shift;
    my $node = $self->SUPER::yaml_load(@_);
    my $instruction_container =
      $self->delegate->make_obj('payload_instruction_container');
    our $instruction_factory ||=
      $self->delegate->make_obj('payload_instruction_factory');

    # expect an ordered list of instructions, each with name and value. The
    # YAML::Active plugin uses the payload_instruction_factory to
    # generate the right instruction object, then sets the value on it
    # and inserts it into the container. The name is prepended by 'u-'
    # for IC_UPDATE, 'a-' for IC_ADD and 'd-' for IC_DELETE to provide a
    # concise notation.
    #
    # Example:
    #
    # - u-value_person_company_no: &COMPANYNO 1234
    # - u-value_person_name_title: &TITLE Grunz
    # - u-value_person_name_firstname: &FIRSTNAME Franz
    # - u-value_person_name_lastname: &LASTNAME Testler
    # - a-value_person_email_address: &EMAIL fh@univie.ac.at
    # - a-value_person_fax_number: &FAX1 '+4311234566'
    # - a-value_person_fax_number: &FAX2 '+431242342343'
    # - clear: 1
    # - foo: 1
    for my $spec (@$node) {
        unless (ref $spec eq 'HASH' && scalar(keys %$spec) == 1) {
            throw Error::Hierarchy::Internal::CustomMessage(custom_message =>
                  "expected a single-item hash with the instruction, got:\n"
                  . Dump($spec));
        }
        my ($key, $value) = %$spec;
        if ($key =~ /^([a-z])-(.*)/) {
            my ($abbrev_command, $type) = ($1, $2);
            my $command = $self->word_complete($abbrev_command, $self->delegate->IC)
              or throw Error::Hierarchy::Internal::CustomMessage(custom_message =>
                  "can't determine instruction command from [$abbrev_command]");
            $instruction_container->items_push(
                $instruction_factory->gen_instruction(
                    $type,
                    command => $command,
                    value   => $value,
                )
            );
        } else {
            $instruction_container->items_push(
                $instruction_factory->gen_instruction($key, value => $value));
        }
    }
    $instruction_container;
}

sub word_complete {
    my ($self, $word, @candidates) = @_;
    for (@candidates) {
        return $_ if index($_, $word) == 0;
    }
}
1;


__END__
=pod

=head1 NAME

Data::Conveyor::YAML::Marshall::Payload::InstructionContainer - Stage-based conveyor-belt-like ticket handling system

=head1 VERSION

version 1.103130

=head1 METHODS

=head2 word_complete

FIXME

=head2 yaml_load

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

