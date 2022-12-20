package Data::Localize::YAML;
$Data::Localize::YAML::VERSION = '0.001';
use v5.10;
use strict;
use warnings;

use Moo;
use File::Basename;
use Data::Localize;
use Data::Localize::Storage::Hash;
use YAML::Tiny;
use Carp qw(croak);

BEGIN {
	if (Data::Localize::DEBUG) {
		require Data::Localize::Log;
		Data::Localize::Log->import;
	}
}

extends 'Data::Localize::Localizer';
with 'Data::Localize::Trait::WithStorage';

has 'is_array' => (
	is => 'ro',
	default => sub { 1 },
);

has 'array_key_value' => (
	is => 'ro',
	default => sub { [qw(id str)] },
);

has paths => (
	is => 'ro',
);

around register => sub {
	my ($next, $self, $loc) = @_;
	$self->$next($loc);
	$loc->add_localizer_map('*', $self);
};

sub BUILD
{
	my $self = shift;
	my $paths = $self->paths;
	foreach my $path (@$paths) {
		$self->load_from_path($path);
	}
}

sub BUILDARGS
{
	my ($class, %args) = @_;

	my $path = delete $args{path};
	if ($path) {
		$args{paths} ||= [];
		push @{$args{paths}}, $path;
	}
	$class->SUPER::BUILDARGS(%args);
}

sub add_path
{
	my $self = shift;
	push @{$self->paths}, @_;
	$self->load_from_path($_) for @_;
}

sub load_from_path
{
	my ($self, $path) = @_;

	return unless $path;

	if (Data::Localize::DEBUG) {
		debugf("load_from_path - loading from glob(%s)", $path);
	}

	foreach my $x (glob($path)) {
		$self->load_from_file($x) if -f $x;
	}
}

sub load_from_file
{
	my ($self, $file) = @_;

	if (Data::Localize::DEBUG) {
		debugf("load_from_file - loading from file %s", $file);
	}

	my $lexicon = YAML::Tiny->read($file);
	my %hash_lexicon;

	if ($self->is_array) {
		my ($keykey, $valuekey) = @{$self->array_key_value};
		foreach my $item (@{$lexicon}) {
			if (!exists $item->{$keykey} || !exists $item->{$valuekey}) {
				croak
					"Array element from YAML file does not contain $keykey or $valuekey - forgot to set array_key_value?";
			}

			$hash_lexicon{$item->{$keykey}} = $item->{$valuekey};
		}
	}
	else {
		%hash_lexicon = %{$lexicon->[0]};
	}

	my $lang = File::Basename::basename($file);
	$lang =~ s/\.ya?ml$//;

	if (Data::Localize::DEBUG) {
		debugf("load_from_file - registering %d keys", scalar keys %hash_lexicon);
	}

	$self->merge_lexicon($lang, \%hash_lexicon);
}

1;

__END__

=head1 NAME

Data::Localize::YAML - Acquire Lexicons From .yml Files

=head1 SYNOPSIS

	my $loc = Data::Localize->new();

	# with YAML lexicons in form of arrays of id/str keys in hashes
	$loc->add_localizer(
		class => 'YAML',
		path => 'i18n/*.yaml',
	);

	# same, but change the keys
	$loc->add_localizer(
		class => 'YAML',
		path => 'i18n/*.yaml',
		array_key_value => [qw(msgid msgstr)],
	);

	# use hashes instead
	$loc->add_localizer(
		class => 'YAML',
		path => 'i18n/*.yaml',
		is_array => 0,
	);

=head1 DESCRIPTION

This module is a plugin to Data::Localize which makes it possible to acquire
lexicons from YAML files in the following formats:

B<array>

The default format. Resembles how basic C<.po> files look, but is easier to
handle since it is YAML.

Key and value keys are by default C<id> and C<str>, which can be changed by
passing C<array_key_value> (a two element array with keys).

	---
	id: key
	str: translation
	---
	id: key2
	str: other translation

B<hash>

Obtains simple key/value pairs from a hash

	---
	key: translation
	key2: other translation

=head1 METHODS

=head2 format_string($lang, $value, @args)

Formats the string

=head2 add_path($path, ...)

Adds a new path where .po files may be searched for.

=head2 get_lexicon($lang, $id)

Gets the specified lexicon

=head2 set_lexicon($lang, $id, $value)

Sets the specified lexicon

=head2 merge_lexicon

Merges lexicon (may change...)

=head2 get_lexicon_map($lang)

Get the lexicon map for language $lang

=head2 set_lexicon_map($lang, \%lexicons)

Set the lexicon map for language $lang

=head2 load_from_file

Loads lexicons from specified file

=head2 load_from_path

Loads lexicons from specified path. May contain glob()'able expressions.

=head2 register

Registers this localizer

=head1 UTF8

Currently, strings are assumed to be utf-8,

=head1 SEE ALSO

L<Data::Localize>

=head1 AUTHOR

Bartosz Jarzyna C<bbrtj.pro@gmail.com>

Parts of this code stolen from Data::Localize::Gettext.

=head1 COPYRIGHT

The "MIT" License

