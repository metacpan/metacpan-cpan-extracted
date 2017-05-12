package Config::Maker::Config;

use utf8;
use warnings;
use strict;

use Carp;
use Parse::RecDescent;

use Config::Maker;
use Config::Maker::Encode;
use Config::Maker::Option;
use Config::Maker::Option::Meta;
use Config::Maker::Type;

our $parser = $Config::Maker::parser;

# Now to the parser itself...

sub new {
    my ($class, $root) = @_;

    unless(UNIVERSAL::isa($root, 'Config::Maker::Option')) {
	# We didn't get a Config::Maker::Option, so let's assume we've got
	# a filename
	my $type = Config::Maker::Type->root;

	my $children = $class->read($root, $type);

	$root = $type->instantiate({ -children => $children });
    }

    bless {
	root => $root,
	meta => Config::Maker::Option::Meta->new(
		    -type => Config::Maker::Type->meta()
		),
    }, $class;
}

sub read {
    my ($class, $file, $type) = @_;
    my ($fh, $text);
    my $enc = 'system';

    $file = Config::Maker::locate($file);

    open($fh, '<', $file)
	or croak "Failed to open $file: $!";
    {
	local $/;
	$text = <$fh>;
    }
    close $fh;

    if((substr($text, 0, 250) =~ /^\s*#.*$Config::Maker::fenc([[:alnum:]_-]+)/m) ||
       (substr($text, -250)   =~ /^\s*#.*$Config::Maker::fenc([[:alnum:]_-]+)/m)) {
       $enc = $1;
    }
    $text = decode($enc, $text);

    LOG("Loading configuration from $file using encoding $enc");
    my $options = $parser->configuration($text, undef, $type);
    croak "Configuration file $file contained errors"
	unless defined $options;

    return $options;
}

sub meta {
    my ($self, $name) = @_;
    $self->{meta}->get($name);
}

sub set_meta {
    my ($self, $name, $value) = @_;
    $self->{meta}->set_child($name, $value);
}

1;

__END__

=head1 NAME

Config::Maker::Config - This class represents the parsed configuration data.

=head1 SYNOPSIS

  use Config::Maker::Config

  $config = Config::Maker::Config->new($file);

=head1 DESCRIPTION

This module parses the configuration data. It contains the (relatively large)
Parse::RecDescent parser for parsing the configuration files and a simple
constructor for parsing files.

The parser has two major parametrized rules: the C<body> and the C<value>.

=head2 Rule C<body>

The body rule takes a list of arguments, where the first one is the body type
to be used and the rest are lists of arguments for possible subrules. There are
three types of body defined:

=over 4

=item C<simple>

The C<body_simple> rule describes simple options (without suboptions). It has
one additional argument -- the argument list for a C<value>. The value has to
be terminated with a semicolon.

=item C<anon_group>

The C<body_anon_group> rule describes blocks with no indentifier/value, that
contain more options. It has no extra arguments.

=item C<named_group>

The C<body_named_group> rule describes an option with an identifier/value and
suboptions. It has one additional argument -- the argument list for a C<value>.

=back

=head2 Rule C<value>

This describes various types of values that can be given to options. There are
simple values and complex values. For now, all simple values are manipulated as
strings, but the more precise specification allows to check them during parsing
of the configuration. The complex values are represented by complex perl data
structures. Currently these can only be used from C<[{I<perl code>}]> in
templates. They are primarily designed for use in metaconfig.

=over 4

=item Simple values

None of the simple values takes extra arguments.

=over 4

=item C<void>

No option at all. 

=item C<string>

Either a single or double quoted string, or, if it does not contain too funny
characters a bareword.

=item C<identifier>

Starts with an alphabetic character and continues with alphanumerics, dashes
and underscores. Unicode word characters are recognized as alphabetic.

=item C<dns_name>

Just ASCII letters, numbers and dashes.

=item C<dns_zone>

Sequence of C<dns_name>s separated, and possibly terminated, with dots.

=item C<ipv4>

A dotted deciaml IPv4 address. Only four-byte notation is recognized. The
shorthand ones are not.

=item C<port>

A decimal integer from 0 through 65535.

=item C<ipv4_port>

An C<ipv4> and a C<port> separated with a colon.

=item C<ipv4_mask>

And C<ipv4>, a slash and an integer from 0 to 32.

=item C<mac>

Six tuples of hex digits, separated by colons.

=item C<perlcode>

A piece of perl code enclosed in curly braces (C<{}>). Represented as a string.

=back

=item Complex values

The complex values consist of other value types. They take arguments that shall
be passed to the C<value> subrules.

=over 4

=item C<list>

A space separated list of values. Remaining arguments are passed to the
recursive calls of C<value> rules.

=item C<zero_list>

Like above, but empty list is valid.

=item C<nested_list>

A space separated list of values or sublists in square brackets (C<[]>).
Remaining arguments are, again, passed to the recursive calls of C<value>
rules.

=item C<nestlist_elem>

This is the actual type of elements in the nested list. It is either a single
element of specified type, or a nested_list containing that type.

=item C<pair>

Space separated pair of values. Takes two array arguments, the respective types
of the two values.

=back

=back

=head1 AUTHOR

Jan Hudec <bulb@ucw.cz>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 Jan Hudec. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

perl(1), Config::Maker(3pm), Parse::RecDescent(3pm).

=cut
# arch-tag: d943c1af-6a9c-447a-8760-41758b32b163
