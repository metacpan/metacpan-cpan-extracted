use 5.008;
use strict;
use warnings;

package Class::Value::Contact::EmailAddress;
our $VERSION = '1.100840';
# ABSTRACT: Contact-related value objects
use Email::Valid;
use parent 'Class::Value::Contact';

sub is_well_formed_value {
    my ($self, $value) = @_;
    return
         $self->SUPER::is_well_formed_value($value)
      && Email::Valid->address($value)
      && $value =~ /^[^\@]+\@[^\@]+$/
      &&    # only one '@' sign
      length($value) <= 255;
}

sub send_notify_value_not_wellformed {
    my ($self, $value) = @_;
    local $Error::Depth = $Error::Depth + 2;
    $self->exception_container->record(
        'Class::Value::Contact::Exception::Email::NotWellformed',
        email => $value,);
}

sub send_notify_value_invalid {
    my ($self, $value) = @_;
    local $Error::Depth = $Error::Depth + 2;
    $self->exception_container->record(
        'Class::Value::Contact::Exception::Email::Invalid',
        email => $value,);
}
1;


__END__
=pod

=head1 NAME

Class::Value::Contact::EmailAddress - Contact-related value objects

=head1 VERSION

version 1.100840

=head1 METHODS

=head2 is_well_formed_value

FIXME

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org/Public/Dist/Display.html?Name=Class-Value-Contact>.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see
L<http://search.cpan.org/dist/Class-Value-Contact/>.

The development version lives at
L<http://github.com/hanekomu/Class-Value-Contact/>.
Instead of sending patches, please fork this project using the standard git
and github infrastructure.

=head1 AUTHOR

  Marcel Gruenauer <marcel@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2004 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

