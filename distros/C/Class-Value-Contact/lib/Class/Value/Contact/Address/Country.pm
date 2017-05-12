use 5.008;
use strict;
use warnings;

package Class::Value::Contact::Address::Country;
our $VERSION = '1.100840';
# ABSTRACT: Contact-related value objects
use Error::Hierarchy::Util 'assert_defined';
use parent 'Class::Value::Contact::Address';

# Class method:
#
# Takes a potential country name which could be an alias and returns the
# normal country name for that country (e.g., 'Oesterreich' and 'Austria'
# both map to 'Austria') If the name is already the normal name, it isn't
# changed and returned. If the name given isn't a country name (or an
# alias), a false value is returned.
sub normalize_value {
    my ($self, $value) = @_;
    return unless $value;
    $self->get_short_country_name($value);
}

# get_normal_country_name() can be called as a class method with an argument,
# or as an object method without an argument (in which case it will act on the
# object's value).
sub get_normal_country_name {
    my ($self, $country) = @_;
    our %cache;
    $country = $self->value unless defined $country;
    $cache{normal_country_name}{$country} =
      $self->_get_normal_country_name($country)
      unless defined $cache{normal_country_name}{$country};
    $cache{normal_country_name}{$country};
}

sub _get_normal_country_name {
    my ($self, $country) = @_;
    $country;    # no normalizations defined
}

# get_short_country_name() can be called as a class method with an argument,
# or as an object method without an argument (in which case it will act on the
# object's value).
sub get_short_country_name {
    my ($self, $country) = @_;
    our %cache;
    $country = $self->value unless defined $country;
    $cache{short_country_name}{$country} =
      $self->_get_short_country_name($country)
      unless defined $cache{short_country_name}{$country};
    $cache{short_country_name}{$country};
}

sub _get_short_country_name {
    my ($self, $country) = @_;
    undef;    # no short country names defined
}

sub send_notify_value_normalized {
    my ($self, $value, $normalized) = @_;
    my $class = 'Class::Value::Contact::Exception::ReplaceAliasCountry';
    $self->exception_container->record(
        $class,
        original    => $value,
        replacement => $normalized,
    );
}

sub send_notify_value_invalid {
    my ($self, $value) = @_;
    local $Error::Depth = $Error::Depth + 2;
    $self->exception_container->record(
        'Class::Value::Contact::Exception::InvalidCountry',
        country => $value,);
}
1;


__END__
=pod

=head1 NAME

Class::Value::Contact::Address::Country - Contact-related value objects

=head1 VERSION

version 1.100840

=head1 METHODS

=head2 get_normal_country_name

FIXME

=head2 get_short_country_name

FIXME

=head2 normalize_value

FIXME

=head2 send_notify_value_normalized

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

