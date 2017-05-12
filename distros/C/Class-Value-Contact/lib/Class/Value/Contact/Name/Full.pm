use 5.008;
use strict;
use warnings;

package Class::Value::Contact::Name::Full;
our $VERSION = '1.100840';
# ABSTRACT: Contact-related value objects
use parent 'Class::Value::Contact';

# A name is well-formed if it consists of 2-5 whitespace-separated words, at
# least two of which must contain at least two [A-Za-z] characters. This is
# rather arbitrary; if you allow different forms of names, subclass this
# class.
#
# Note that we don't check whether the string only consists of valid
# characters - that's handled by the charset handler mechanism in
# Class::Value::String (i.e., when checking for the validity of the value -
# here we check for well-formedness).
sub is_well_formed_value {
    my ($self, $value) = @_;
    return 1 unless defined($value) && length($value);
    return 0 unless $self->SUPER::is_well_formed_value($value);
    local $_ = $value;
    my @words = split /\s+/;
    return 0 if @words < 2 || @words > 5;
    my $valid_words = 0;
    for (@words) {
        $valid_words++ if 2 <= (() = /[A-Za-z]/g);
    }
    return $valid_words >= 2;
}

sub send_notify_value_not_wellformed {
    my ($self, $value) = @_;
    local $Error::Depth = $Error::Depth + 2;
    $self->exception_container->record(
        'Class::Value::Contact::Exception::Name::NotWellformed',
        name => $value,);
}

sub send_notify_value_invalid {
    my ($self, $value) = @_;
    local $Error::Depth = $Error::Depth + 2;
    $self->exception_container->record(
        'Class::Value::Contact::Exception::Name::Invalid',
        name => $value,);
}
1;


__END__
=pod

=head1 NAME

Class::Value::Contact::Name::Full - Contact-related value objects

=head1 VERSION

version 1.100840

=head1 METHODS

=head2 is_well_formed_value

FIXME

=head2 send_notify_value_invalid

FIXME

=head2 send_notify_value_not_wellformed

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

