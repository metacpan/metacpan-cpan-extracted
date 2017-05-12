package Dancer2::Plugin::PageHistory::Page;

=head1 NAME

Dancer2::Plugin::PageHistory::Page - Page object for Dancer2::Plugin::PageHistory

=cut

use Carp qw(croak);
use Dancer2::Core::Types qw(Str HashRef InstanceOf);
use Moo;
use namespace::clean;

=head1 ATTRIBUTES

=head2 attributes

Extra attributes as a hash reference, e.g.: SKU for a product page.

=cut

has attributes => (
    is        => 'ro',
    isa       => HashRef,
    predicate => 1,
);

=head2 path

Absolute path of the page. This is the path as seen by the Dancer2 application
so if the app is not mounted on '/' then this will be different from
L</request_path>.

If not passed in the constructor will be set from L</request>.

=cut

has path => (
    is      => 'ro',
    isa     => Str,
    lazy    => 1,
    default => sub {
        return $_[0]->request->path
    },
);

=head2 request

The L<Dancer2::Core::Request> object. Optional.

=cut

has request => (
    is      => 'ro',
    isa     => InstanceOf ['Dancer2::Core::Request'],
    clearer => '_clear_request',
);

=head2 request_path

The original request path but without the query string.

If this was not supplied to the constructor then what this returns varies:

If L</request> was supplied then this is used to determine the appropriate
path to return.

Otherwise L</path> is returned.

=cut

has request_path => (
    is      => 'ro',
    isa     => Str,
    lazy    => 1,
    default => sub {
        my $self = shift;
        if ( $self->request ) {
            my $base = $self->request->base->path;
            my $path = $self->path;
            $base =~ s|/$||;
            $path =~ s|^/||;
            return "$base/$path";
        }
        else {
            return $self->path;
        }
    },
);

=head2 query_string

The original query string.

=cut

has query_string => (
    is      => 'ro',
    isa     => Str,
    lazy    => 1,
    default => sub {
        my $self = shift;
        return $self->request ? $self->request->env->{QUERY_STRING} : '';
    },
);

=head2 title

Page title.

=cut

has title => (
    is        => 'ro',
    isa       => Str,
    predicate => 1,
);

=head1 METHODS

=head2 BUILDARGS

Checks that at least one of 'request' and 'path' have been supplied or croaks.

=cut

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;
    my %args  = @_ == 1 && ref( $_[0] ) eq 'HASH' ? %{ $_[0] } : @_;

    croak "Either 'request' or 'path' must be supplied as arg to new"
      unless $args{request} || $args{path};

    return $class->$orig(%args);
};

sub BUILD {
    my $self = shift;
    if ( $self->request ) {
        $self->path;
        $self->request_path;
        $self->query_string;
        $self->_clear_request;
    }
}

=head2 predicates

The following predicate methods are defined:

=over

=item * has_attributes

=item * has_title

=back

=head2 uri

Returns the string URI for L</path> and L</query_string>.

=cut

sub uri {
    my $self = shift;
    my $uri = $self->path;
    $uri .= '?' . $self->query_string if $self->query_string;
    return "$uri";
}

=head2 request_uri

Returns the string URI for L</request_path> and L</query_string>.

=cut

sub request_uri {
    my $self = shift;
    my $uri = $self->request_path;
    $uri .= '?' . $self->query_string if $self->query_string;
    return "$uri";
}

1;
