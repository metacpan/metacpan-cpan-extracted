use 5.008;
use strict;
use warnings;

package Data::Conveyor::YAML::Active::Payload::Instruction::Container;
BEGIN {
  $Data::Conveyor::YAML::Active::Payload::Instruction::Container::VERSION = '1.103130';
}
# ABSTRACT: Stage-based conveyor-belt-like ticket handling system

use YAML::Active qw/assert_arrayref array_activate/;
use YAML;

# FIXME cleanup: this seems to generate an array reference. later on, somebody
# tries to call ->__phase on that array reference, which doesn't work
# (warning: pseudo-hashes are deprecated; error: no such element '__phase' in
# pseudo-hash or something like that)
#
# it seems to work that way, but I don't know if it's perfect.
#    for my $spec ($self->__array) {
# gr's version
#use YAML::Active qw/assert_hashref hash_activate/;
#use parent 'Class::Scaffold::YAML::Active::Array';
#
#sub run_plugin {
#    my $self = shift;
#    $self->SUPER::run_plugin(@_);
#
#    my $instruction_container =
#        $self->delegate->make_obj('payload_instruction_container');
#
#    my $instruction_factory =
#        $self->delegate->make_obj('payload_instruction_factory');
# my version
use parent 'Class::Scaffold::YAML::Active';

sub yaml_activate {
    my ($self, $phase) = @_;
    assert_arrayref($self);
    my $array = array_activate($self, $phase);
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
    for my $spec (@$array) {
        unless (ref $spec eq 'HASH' && scalar(keys %$spec) == 1) {
            throw Error::Hierarchy::Internal::CustomMessage(custom_message =>
                  "expected a single-item hash with the instruction, got:\n"
                  . Dump($spec));
        }
        my ($key, $value) = %$spec;
        if ($key eq 'clear') {
            $instruction_container->items_push(
                $instruction_factory->gen_instruction('clear'));
            next;
        }
        unless ($key =~ /^([a-z])-(.*)/) {
            throw Error::Hierarchy::Internal::CustomMessage(
                custom_message => "can't parse instruction key [$key]");
        }
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

Data::Conveyor::YAML::Active::Payload::Instruction::Container - Stage-based conveyor-belt-like ticket handling system

=head1 VERSION

version 1.103130

=head1 METHODS

=head2 word_complete

FIXME

=head2 yaml_activate

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

