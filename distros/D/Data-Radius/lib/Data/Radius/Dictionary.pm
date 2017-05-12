package Data::Radius::Dictionary;

use v5.10;
use strict;
use warnings;

use base qw(Class::Accessor::Fast);
__PACKAGE__->mk_accessors(qw(attr_id attr_name const_name const_value vnd_name vnd_id));

use Data::Radius::DictionaryParser ();

sub new {
    my ($class, %h) = @_;
    return bless({ %h }, $class);
}

sub load_file {
    my ($class, $file) = @_;
    return Data::Radius::DictionaryParser->new()->parse_file($file);
}

sub attribute {
    my ($self, $attr_name) = @_;
    return undef if (! $attr_name);
    # hash-ref with {id, type, vendor, parent}
    return $self->attr_name()->{ $attr_name };
}

sub attribute_name {
    my ($self, $vendor_name, $id) = @_;
    return $self->attr_id()->{ $vendor_name // '' }{$id};
}

sub tlv_attribute_name {
    my ($self, $parent, $id) = @_;
    return $parent->{tlv_attr_id}{ $id };
}

sub vendor_id {
    my ($self, $vendor_name) = @_;
    return undef if (! $vendor_name);
    return $self->vnd_name()->{ $vendor_name };
}

sub vendor_name {
    my ($self, $vendor_id) = @_;
    return undef if (! $vendor_id);
    return $self->vnd_id()->{ $vendor_id };
}

# VALUE    Service-Type Login-User 1
# Convert 'Login-User' to 1
sub value {
    my ($self, $attr_name, $const_name) = @_;
    return undef if (! defined $const_name);
    return $self->const_value()->{ $attr_name } ? $self->const_value()->{ $attr_name }{ $const_name } : undef;
}

sub constant {
    my ($self, $attr_name, $const_value) = @_;
    return undef if (! defined $const_value);
    return $self->const_name()->{ $attr_name } ? $self->const_name()->{ $attr_name }{ $const_value } : undef;
}

1;

__END__

=head1 NAME

Data::Radius::Dictionary - parse and load RADIUS dictionary files

=head1 SYNOPSIS

    use Data::Radius::Constants;
    my $dictionary = Data::Radius::Constants->load_file('path-to-dictionary');

=head1 SEE ALSO

L<Data::Radius::Packet>

=head1 AUTHOR

Sergey Leschenko <sergle.ua at gmail.com>

PortaOne Development Team <perl-radius at portaone.com> is the current module's maintainer at CPAN.

=cut


