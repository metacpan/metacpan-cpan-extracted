package Data::HAL::Link;
use strictures;
use boolean qw(false true);
use Data::HAL::URI qw();
use HTTP::Headers::Util qw(join_header_words);
use JSON qw();
use Log::Any qw($log);
use MIME::Type qw();
use Moo; # has
use Safe::Isa qw($_can $_isa);
use Types::Standard qw(InstanceOf Str);

our $VERSION = '1.000';

my $uri_from_str = sub {
    my ($val) = @_;
    return $val->$_isa('Data::HAL::URI') ? $val : Data::HAL::URI->new($val);
};

my $boolean_from_perlbool = sub {
    my ($val) = @_;
    return $val ? true : false;
};

has('relation', is => 'rw', isa => InstanceOf['Data::HAL::URI'], coerce => $uri_from_str, required => 1);
has('href',     is => 'rw', isa => InstanceOf['Data::HAL::URI'], coerce => $uri_from_str, required => 1);
has('templated',   is => 'rw', isa => InstanceOf['boolean'], coerce => $boolean_from_perlbool);
has('type',        is => 'rw', isa => InstanceOf['MIME::Type']);
has('deprecation', is => 'rw', isa => InstanceOf['Data::HAL::URI'], coerce => $uri_from_str);
has('name',        is => 'rw', isa => Str);
has('profile',     is => 'rw', isa => InstanceOf['Data::HAL::URI'], coerce => $uri_from_str);
has('title',       is => 'rw', isa => Str);
has('hreflang',    is => 'rw', isa => Str);

sub BUILD {
    my ($self) = @_;
    if ($self->deprecation) {
        $log->warn(sprintf 'The link (relation: "%s", href: "%s") is deprecated, see <%s>',
            $self->relation->as_string, $self->href->as_string, $self->deprecation->as_string);
    }
    return;
}

sub _to_nested {
    my ($self, $root) = @_;
    my $hal;
    for my $attr (map { $_->accessor } $self->meta->get_all_attributes) {
        my $val = $self->$attr;
        if (defined $val) {
            $hal->{$attr} = $val->$_can('as_string') ? $val->as_string($root) : $val;
        }
    }
    my $r = delete $hal->{relation};
    return($hal, $r);
}

sub as_http_link_value {
    my ($self) = @_;
    return if 'curies' eq $self->relation->as_string;
    return join_header_words(
        '<'.$self->href->as_string.'>' => undef,
        rel => $self->relation->as_string,
        $self->hreflang ? (hreflang => $self->hreflang) : (),
        $self->title ? (title => $self->title) : (),
        $self->type ? (type => $self->type) : (),
        $self->name ? (name => $self->name) : (),
        $self->profile ? (profile => $self->profile->as_string) : (),
    );
}

1;

__END__

=encoding UTF-8

=head1 NAME

Data::HAL::Link - Hypertext Application Language link

=head1 VERSION

This document describes Data::HAL::Link version 1.000

=head1 SYNOPSIS

    map { +{
        href => $_->href->uri->as_string,
        rel  => $_->relation->uri->as_string
    } } @{ $resource->links }

=head1 DESCRIPTION

This section is completely quoted from the specification:

A Link Object represents a hyperlink from the containing resource to
a URI.

=head1 INTERFACE

=head2 Composition

None.

=head2 Constructors

=head3 C<new>

When the L</deprecation> attribute is set, the constructor logs a L<Log::Any> warning:

C<< The link (relation: "%s", href: "%s") is deprecated, see <%s> >>

You can consume it with a L<Log::Any::Adapter> of your choice, e.g.

    use Log::Any::Adapter 'Stderr';

Otherwise the constructor behaves like the default L<Moo> constructor. Returns a C<Data::HAL::Link> object.

=head2 Attributes

Perl strings are coerced to the L<Data::HAL::URI> type in the attributes L</relation>, L</href>, L</deprecation>,
L</profile>.

=head3 C<relation>

Type L<Data::HAL::URI>, B<required>,
L<link relation|http://tools.ietf.org/html/draft-kelly-json-hal#section-8.2>

=head3 C<href>

Type L<Data::HAL::URI>, B<required>,
L<link target URI or URI template|http://tools.ietf.org/html/draft-kelly-json-hal#section-5.1>

=head3 C<templated>

Type L<boolean>,
L<< whether C<href> is a URI template|http://tools.ietf.org/html/draft-kelly-json-hal#section-5.2 >>

Perl boolean values are coerced to the L<boolean> type.

=head3 C<type>

Type L<MIME::Type>,
L<< media type of the C<href> resource|http://tools.ietf.org/html/draft-kelly-json-hal#section-5.3 >>

=head3 C<deprecation>

Type L<Data::HAL::URI>, if existing
L<< indicates the link is deprecated|http://tools.ietf.org/html/draft-kelly-json-hal#section-5.4 >>

Setting the attribute triggers a log message in the constructor L</new>.

=head3 C<name>

Type C<Str>, L<< secondary key for selecting link objects which share the same relation
type|http://tools.ietf.org/html/draft-kelly-json-hal#section-5.5 >>

=head3 C<profile>

Type L<Data::HAL::URI>,
L<< RFC 6906 profile of the target resource|http://tools.ietf.org/html/draft-kelly-json-hal#section-5.6 >>

=head3 C<title>

Type C<Str>, L<< labels the link with a human-readable
identifier|http://tools.ietf.org/html/draft-kelly-json-hal#section-5.7 >>

=head3 C<hreflang>

Type C<Str>,
L<< indicates the language of the target resource|http://tools.ietf.org/html/draft-kelly-json-hal#section-5.8 >>

=head2 Methods

=head3 C<as_http_link_value>

Returns the link as a L<< RFC 5988 C<link-value>|http://tools.ietf.org/html/rfc5988#section-5 >> string, e.g.
C<< </orders?page=2>;rel="next" >>.

=head2 Exports

None.

=head1 DIAGNOSTICS

See L</new> constructor.

=head1 CONFIGURATION AND ENVIRONMENT

Requires no configuration files or environment variables.
