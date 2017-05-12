package Data::Partial::Google;
# ABSTRACT: Filter data structures for "partial responses," Google style
our $VERSION = '0.02'; # VERSION
our $AUTHORITY = 'cpan:ARODLAND'; # AUTHORITY
use Moo;

use Data::Partial::Google::Parser;
use Data::Partial::Google::Filter;

has rule => (
	is => 'ro',
);

has filter => (
	is => 'ro',
	lazy => 1,
	default => sub {
		Data::Partial::Google::Parser->parse(shift->rule)
	},
);

# Allow Data::Partial::Google->new("a,b(c/d)")
sub BUILDARGS {
	my ($class, @args) = @_;
	unshift @args, "rule" if @args % 2;
	return { @args };
}

sub has_rule {
	my ($self) = @_;
	my $rule = $self->rule;
	return defined $rule && length $rule;
}

sub BUILD {
	my ($self) = @_;
	$self->filter if $self->has_rule;
}

sub mask {
	my ($self, $obj) = @_;
	if ($self->has_rule) {
		return $self->filter->mask($obj);
	} else {
		return $obj;
	}
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Partial::Google - Filter data structures for "partial responses," Google style

=head1 VERSION

version 0.02

=head1 SYNOPSIS

    my $data = {
        artist => "Alice In Chains",
        title  => "Sap",
        year   => 1992,
        tracks => [
            { title => "Brother",      length => "4:27" },
            { title => "Got Me Wrong", length => "4:12" },
            { title => "Right Turn",   length => "3:17" },
            { title => "Am I Inside",  length => "5:09" },
        ]
    };

    my $filter = Data::Partial::Google->new('artist,title,tracks/title');
    my $filtered = $filter->mask($data);

    cmp_deeply($data, {
        artist => "Alice In Chains",
        title  => "Sap",
        tracks => [
            { title => "Brother" },
            { title => "Got Me Wrong" },
            { title => "Right Turn" },
            { title => "Am I Inside" },
        ]
    });

    # ok 1

=head1 DESCRIPTION

This module filters data structures without changing their shape, making
it easy to expose only the parts of interest to a consumer. It aims to be
compatible with Google's implementation of partial responses using the C<fields>
parameter, and it is based on the node module "json-mask".

=head1 RULES

=head2 Properties

Select one or more properties from an object by seprating them with commas:

    foo,bar,baz

=head2 Descendants

Use the slash operator to select properties within properties:

   foo/bar/baz

will return the 'baz' property of the 'bar' property of the 'foo' property.

Arrays are handled transparently: if 'foo' is an array, then the rule
'bar/baz' will be applied to every entry in 'foo'.

=head2 Sub-selection

Use the parentheses to select specific properties from inside another:

    foo(bar,baz)

selects the 'bar' and 'baz' properties from 'foo' (or from each element in
'foo').

=head2 Wildcards

Use the asterisk to select all sub-properties of a property:

    foo/*/baz

selects the 'baz' property from every property of 'foo' that has a 'baz'.

=head1 METHODS

=head2 mask

C<< $filter->mask($data) >> returns C<$data>, as modified by C<$filter>'s rules.
In most senses the returned value will be a deep copy of C<$data>, as hashes
and arrays will have been reconstructed, but other values, such as code
references and glob references, will be copied directly, so be cautious.

=head1 SEE ALSO

=over 4

=item *

Google Partial Responses: L<https://developers.google.com/discovery/v1/performance#partial-response>

=item *

json-mask: L<https://github.com/nemtsov/json-mask>

=back

=head1 AUTHOR

Andrew Rodland <arodland@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Andrew Rodland.

This is free software, licensed under:

  The MIT (X11) License

=head1 ADDITIONAL LICENSE

This module contains code and tests from json-mask,
Copyright (c) 2013 Yuriy Nemtsov.

=head1 CREDIT

Development of this module is supported by Shutterstock.

=cut
