package Amazon::SimpleDB::Item;
use strict;
use warnings;

use Amazon::SimpleDB::Response;
use Carp qw( croak );

sub new {
    my $class = shift;
    my $args  = shift || {};
    my $self  = bless $args, $class;
    croak "No account"     unless $self->{account};
    croak "No domain"      unless $self->{domain};
    croak "No (item) name" unless $self->{name};
    return $self;
}

sub account { return $_[0]->{account} }
sub name    { return $_[0]->{name} }
sub domain  { return $_[0]->{domain} }

sub get_attributes {
    my ($self, $name) = @_;
    my $params = {DomainName => $self->{domain}, ItemName => $self->{name}};
    $params->{AttributeName} = $name
      if defined $name;    # specific attribute request
    my $account = $self->{account};
    return
      Amazon::SimpleDB::Response->new(
                   http_response => $account->request('GetAttributes', $params),
                   domain        => $self,
                   account       => $self->{account},
      );
}

sub put_attributes {
    my ($self, $attr) = @_;
    my $params = _process_attribute_params($self, $attr);
    my $account = $self->{account};
    return
      Amazon::SimpleDB::Response->new(
                   http_response => $account->request('PutAttributes', $params),
                   domain        => $self,
                   account       => $self->{account},
      );
}

sub post_attributes {
    my ($self, $attr) = @_;
    my $params = _process_attribute_params($self, $attr, 1);
    my $account = $self->{account};
    return
      Amazon::SimpleDB::Response->new(
                   http_response => $account->request('PutAttributes', $params),
                   domain        => $self,
                   account       => $self->{account},
      );
}

sub delete_attributes {
    my ($self, $attr) = @_;
    my $params = _process_attribute_params($self, $attr);
    my $account = $self->{account};
    return
      Amazon::SimpleDB::Response->new(
                http_response => $account->request('DeleteAttributes', $params),
                domain        => $self,
                account       => $self->{account},
      );
}

#--- utility

sub _process_attribute_params {
    my ($self, $attr, $replace) = @_;
    my $params = {DomainName => $self->{domain}, ItemName => $self->{name}};
    return $params unless $attr;    # no attributes means the entire item.
    if (ref $attr eq 'HASH') {      # put/delete params with values.
        my $i = 0;
        for my $name (keys %$attr) {
            $attr->{$name} = [$attr->{$name}]
              unless ref $attr->{$name} eq 'ARRAY';
            for (@{$attr->{$name}}) {
                $params->{"Attribute.${i}.Name"}    = $name;
                $params->{"Attribute.${i}.Value"}   = $_;
                $params->{"Attribute.${i}.Replace"} = 'true'
                  if $replace;
                $i++;
            }
        }
    } elsif (ref $attr eq 'ARRAY') {    # delete multiple attributes, all values
        my $i = 0;
        for (@$attr) {
            $params->{"Attribute.${i}.Name"} = $_;
            $i++;
        }
    } else {                            # delete single attribute, all values
        $params->{AttributeName} = $attr;
    }
    return $params;
}

1;

__END__

=head1 NAME

Amazon::SimpleBD::Item - A class representing a domain in SimpleDB

=head1 DESCRIPTION

B<This is code is in the early stages of development. Do not
consider it stable. Feedback and patches welcome.>

=head1 METHODS

=head2 Amazon::SimpleDB::Item->new($args)

Constructor for a domain. Takes a required HASHREF with three required keys:

=over

=item account

An L<Amazon::SimpleDB> account object the item is to be associated.

=item domain

The domain the object is to be associated.

=item name

The name of the item for the constructed object.

=back

Typically this method will not be called directly by a
developer, but rather other parts of the L<Amazon::SimpleDB>
package.

This method does not check if an item exists and is accessible.

=head2 $item->account

Returns a reference to the L<Amazon::SimpleDB> account object.

=head2 $item->domain

=head2 $item->name

Returns the domain name of the object.

=head2 $item->get_attributes([$name])

NOTE: Suspect this is broken and that this should support
something between 1 or all.

=head2 $item->put_attributes($args)

Take a required HASHREF of attributes to create. Multiple
values should be stored as an ARRAY reference.

This method will return an error response if any of
attributes already exist.

=head2 $item->post_attributes($args)

Take a required HASHREF of attributes to modify. Multiple
values should be stored as an ARRAY reference.

Unlike C<put_attributes> this method will overwrite any
existing attributes and their values without complaint. If
an attribute doesn't exist this method won't complain
either.

=head2 $item->delete_attributes([\%attributes|\@attributes])

Takes an optional HASHREF or ARRAYREF that define the
attributes to delete. If nothing is passed, the default is
to delete all attributes for the item are deleted. (Items are
automatically deleted when they no longer have any
attributes.)

Using an HASHREF will only delete attributes (defined by the
HASH's keys) with a matching value. Multiple values should
be stored as an ARRAYREF.

=head1 SEE ALSO

L<Amazon::SimpleDB>, L<Amazon::SimpleDB::QueryResponse>

=head1 AUTHOR & COPYRIGHT

Please see the L<Amazon::SimpleDB> manpage for author, copyright, and
license information.
