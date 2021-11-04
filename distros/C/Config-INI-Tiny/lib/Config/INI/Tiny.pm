use 5.006; use strict; use warnings;
use Carp ();

package Config::INI::Tiny;

our $VERSION = '0.103';

sub new { my $class = shift; bless { section0 => '', line0 => 0, pairs => 0, @_ }, $class }

my $str = '[^\r\n]* [^\r\n\t ]';
my $ws  = '[\t ]*';
my $cmt = '[#;]'; # separate var because cf. "Starting in Perl 5.001" in L<perl5200delta/'Regular Expressions'>
my $rx  = qr{\G $ws (?: $cmt (?:$str)? | \[ $ws ($str) $ws \] | ([^=\r\n]+?) $ws = $ws ($str|) | ($str) )? $ws (?:\z|\n|\r\n?) }x;

sub parse {
	my $self = shift;
	my $n = $self->{'line0'}, my @out = my $s = [ $self->{'section0'} ], pos( $_[0] ) = 0;
	BEGIN { utf8->import if eval { require utf8 } } # 5.6 compat
	while ( ++$n, $_[0] =~ /$rx/g ) {
		; defined $2 ? push @$s, $self->{'pairs'} ? [ "$2", "$3" ] : "$2", "$3"
		: defined $1 ? push @out, $s = [ "$1" ]
		: defined $4 ? Carp::croak map { s/"/\\"/g; qq'Bad INI syntax at line $n: "$_"' } "$4"
		: ()
	}
	wantarray ? @out : $out[0];
}

sub to_hash {
	my $self = shift;
	my ( @section, %config ) = do { local $self->{'pairs'}; $self->parse( $_[0] ) };
	shift @section unless @{ $section[0] } > 1;      # remove initial unnamed section if empty
	push @{ $config{ shift @$_ } }, $_ for @section; # collect sections in HoAoA, to minimise (re)alloc work
	$_ = { map @$_, @$_ } for values %config;        # flatten HoAoA to HoH as cheaply as possible
	\%config;
}

__END__

=pod

=encoding UTF-8

=head1 NAME

Config::INI::Tiny - Parse INI configuration in extremely little code

=head1 SYNOPSIS

=head2 Code

 use Config::INI::Tiny;
 use File::Slurper 'read_text';
 my $config = Config::INI::Tiny->new->to_hash( read_text 'myapp.ini' );

=head2 Configuration

 global = setting
 
 [section]
 name = value
 more = stuff
 
 [empty section]

=head1 DESCRIPTION

This is an extremely small amount of code for parsing the INI configuration
format, in its simplest form, as known from Microsoft Windows.

Its design focuses on making it easy to extract whichever level of semantics
you need from your configuration: whether you want to care about the order of
properties; their recurrence; the order of sections; treating each section
header as a separate unit; or however else you want to be able to interpret
your configuration files E<mdash> you can.

=head1 METHODS

=head2 C<new>

Instantiates an INI parser with the specified configuration.

The parsed form consists of a list of sections as they appeared in the configuration,
each represented by an array.
The first element of each array is the name of the section.
It is followed by any number of property/value pairs as they appeared in the configuration.

This format can be modified with the following options:

=head3 C<section0>

The section name for properties found before the first section in the configuration.

Defaults to the empty string, which cannot be expressed by valid configuration syntax.

For L<Config::Tiny> compatibility, set this to an underscore (C<_>).
Note that a section with this name is valid syntax and can appear in a configuration.

=head3 C<pairs>

When true, each property/value pair within the section array is returned as
a two-element sub-array.
Otherwise all the pairs are returned as a single flat list.

Defaults to false.

=head2 C<to_hash>

Takes a configuration in INI format as a string and returns it as a hash of
hashes or throws an exception on syntax error.

=head2 C<parse>

Takes a configuration in INI format as a string and returns it in parsed form
or throws an exception on syntax error.

=head1 SYNTAX

=over 3

=item * Leading and trailing whitespace is ignored on every line.

=item * Empty lines are ignored.

=item * Lines that start with C<#> or C<;> are ignored.

 ; this is a comment
 # so is this

=item * Lines enclosed in paired square brackets with any non-whitespace in between are section lines.

 [section name]

=item * Leading and trailing whitespace in section names is ignored.

 ; these are all the same section:
 [ section name ]
 [section name  ]

=item * Lines that contain a C<=> are property lines.

 prop name=prop value

Everything left of the leftmost C<=> is the name of the property.
Everything to the right of that C<=> is the value of the property.
The name of the property cannot be empty, but the value can.

=item * Leading and trailing whitespace in property names and values is ignored.

 ; these all have identical effect:
 prop name=prop value
 prop name  =  prop value
 prop name=    prop value

=item * Everything else is a syntax error.

=back

=head1 COOKBOOK

=head2 Emulating L<Config::Tiny::Ordered>

 my $config;
 for my $s_kv ( Config::INI::Tiny->new( section0 => '_', pairs => 1 )->parse( $content ) ) {
     my $section_name = shift @$s_kv;
     push @{ $config->{ $section_name } }, map +{ key => $_->[0], value => $_->[1] }, @$s_kv;
 };

The resulting data structure is a hash of arrays instead of the hash of hashes
that L<Config::Tiny> would produce.
The arrays contain key/value pairs in order of their appearance in the input,
where each pair is represented by a hash with two keys named C<key> and C<value>.

=head2 Multi-value (and order-preserving) properties

 use Hash::MultiValue;
 
 my $config;
 for my $s_kv ( Config::INI::Tiny->new->parse( $content ) ) {
     my $section_name = shift @$s_kv;
     my $section = $config->{ $section_name } ||= Hash::MultiValue->new;
     $section->merge_flat( @$s_kv );
 }

Consider the following configuration:

 [eth0]
 ip = 192.168.0.17
 ip = 10.0.1.253

When using L</to_hash>, this would simply store C<10.0.1.253> as the IP for
C<eth0>, with the C<192.168.0.17> value irretrievably lost. L<Hash::MultiValue>
defaults to the same behaviour, but optionally allows you to still retrieve all
other values:

 say for $config->{'eth0'}->get_all('ip');
 # 192.168.0.17
 # 10.0.1.253

=head2 Flexibly nestable sections and properties

 sub hash_path_ref (\%;@) {
     my $hash = shift;
     $hash = $hash->{ $_ } ||= {} for @_[ -@_ .. -2 ];
     \$hash->{ $_[-1] };
 }
 
 my $config = {};
 for my $s_kv ( Config::INI::Tiny->new( pairs => 1 )->parse( $content ) ) {
     my $section_name = shift @$s_kv;
     my $section = ${ hash_path_ref %$config, split ' ', $section_name } ||= {};
     ${ hash_path_ref %$section, split ' ', $_->[0] } = $_->[1] for @$s_kv;
 }

This interprets spaces in section and property names as path separators,
allowing a value like C<< $config->{'de'}{'error'}{'syntax'} >> to be specified
in any one of the following ways, interchangeably:

 de error syntax = Syntax-Fehler

 [de]
 error syntax = Syntax-Fehler

 [de error]
 syntax = Syntax-Fehler

The first two choices are convenient for sections with very few properties,
to avoid having to write a section header line just for one or two properties.

The last one is especially convenient when a section with many properties has
a deeply nested path,
to avoid having to repeat (part of) the path for each and every property.

I<Caveat lector:> this creates the possibility of inconsistent configurations
like the following:

 [foo]
 bar = 1
 
 [foo bar]
 baz = 1

With the given code, a configuration like this will trigger a ref stricture
exception while parsing, because it is essentially equivalent to the following
code:

 use strict 'refs';
 $config->{'foo'}{'bar'} = 1;
 $config->{'foo'}{'bar'}{'baz'} = 1; # boom

Depending on use case, the ref stricture exception may or may not be sufficient
(syntax) error handling.

=head1 SEE ALSO

=over 4

=item L<Config::Tiny>

The original basis for this module. Its design is focused on making the
simplest operations as easy as possible, so it returns the configuration
as a blessed hash on which you can call a method to write it back to a file.
It does not preserve any information about the order or recurrence of either
sections or properties.

=item L<Config::Tiny::Ordered>

This is a clone of L<Config::Tiny> with a more complex data structure, allowing
it to preserve the order and recurrence of properties within sections. Section
order and recurrence is still discarded. There is no other change in trade-offs.

The shape of its output data structure is easy to replicate with this module,
as shown L<in the cookbook|/Emulating Config::Tiny::Ordered>.

=item L<Config::INI>

An attempt at making L<Config::Tiny> flexible by breaking out the steps in the
parser as methods, which allows parsing a different syntax. Tweaking is done by
subclassing, which is cumbersome. If you wish to avoid reimplementing large parts
of the module in your subclass, you are constrained by the existing call graph,
so you must stay fairly close to both the original format and the default data
structure shape. In other words, you can parse any format into any output, so
long as it is I<basically> INI parsed into the default output format; or you
can write basically your own parser.

By contrast, Config::INI::Tiny offers no way of redefining the core INI syntax
but instead provides an easy-to-process full-fidelity representation of its
semantics, so that you can implement additional semantics on top of it,
as shown L<in the cookbook|/Flexibly nestable sections and properties>.

=back

=head1 AUTHOR

Aristotle Pagaltzis <pagaltzis@gmx.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Aristotle Pagaltzis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
