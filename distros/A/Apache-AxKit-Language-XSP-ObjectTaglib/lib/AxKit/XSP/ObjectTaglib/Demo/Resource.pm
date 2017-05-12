# $Id: /local/CPAN/Apache-AxKit-Language-XSP-ObjectTaglib/lib/AxKit/XSP/ObjectTaglib/Demo/Resource.pm 1508 2005-03-10T02:56:40.581331Z claco  $
package AxKit::XSP::ObjectTaglib::Demo::Resource;
use strict;
use warnings;

sub new {
    my $class = shift;
    my $attr = shift || {};
    my $self = bless $attr, $class;

    return $self;
};

sub name {
    return shift->{name};
};

1;
__END__

=head1 NAME

AxKit::XSP::ObjectTaglib::Demo::Resource - A mock course resource object

=head1 SYNOPSIS

    use AxKit::XSP::ObjectTaglib::Demo::Resource;
    use strict;

    my $resource = AxKit::XSP::ObjectTaglib::Demo::Resource->new();
    print $resource->name;

=head1 DESCRIPTION

This module represents a generic Resource object returned by
C<AxKit::XSP::ObjectTaglib::Demo::Course-E<gt>resources> for use within the
C<AxKit::XSP::ObjectTaglib::Demo> Taglib.

=head1 METHODS

=head2 new( [\%attr] )

Returns a new C<AxKit::XSP::ObjectTaglib::Demo::Resource> object. You can also
pass in an optional hashref to be blessed into the new object.

    my $resource = AxKit::XSP::ObjectTaglib::Demo::Resource->new({
        name => 'My Resource'
    });

=head2 name

Returns the name of the given C<AxKit::XSP::ObjectTaglib::Demo::Resource>
object.

    print $resource->name;

=head1 SEE ALSO

L<AxKit::XSP::ObjectTaglib::Demo>, L<Apache::AxKit::Language::XSP::ObjectTaglib>

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    claco@chrislaco.com
    http://today.icantfocus.com/blog/
