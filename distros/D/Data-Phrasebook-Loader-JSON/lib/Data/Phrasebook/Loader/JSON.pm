package Data::Phrasebook::Loader::JSON;

use strict;
use warnings FATAL => 'all';

our $VERSION = '0.02';

#--------------------------------------------------------------------------

use base qw( Data::Phrasebook::Loader::Base Data::Phrasebook::Debug );

use Carp qw( croak );
use File::Slurp;
use JSON::XS;

#--------------------------------------------------------------------------

=head1 NAME

Data::Phrasebook::Loader::JSON - Absract your phrases with JSON.

=head1 SYNOPSIS

    use Data::Phrasebook;

    my $q = Data::Phrasebook->new(
        class  => 'Fnerk',
        loader => 'JSON',
        file   => 'phrases.json',
    );

    $q->delimiters( qr{ \[% \s* (\w+) \s* %\] }x );
    my $phrase = $q->fetch($keyword);

=head1 DESCRIPTION

This class loader implements phrasebook patterns using JSON.

Phrases can be contained within one or more dictionaries, with each phrase
accessible via a unique key. Phrases may contain placeholders, please see
L<Data::Phrasebook> for an explanation of how to use these. Groups of phrases
are kept in a dictionary. In this implementation a single file is one
complete dictionary.

An example JSON file:

  { 
    "dictionary1": { "key1": "value1", "key2": "value2" },
    "dictionary2": { "key3": "value3", "key4": "value4" }
  }

Within the phrase text placeholders can be used, which are then replaced with
the appropriate values once the get() method is called. The default style of
placeholders can be altered using the delimiters() method.

=head1 INHERITANCE

L<Data::Phrasebook::Loader::JSON> inherits from the base class
L<Data::Phrasebook::Loader::Base>.
See that module for other available methods and documentation.

=head1 METHODS

=head2 load

Given a C<file>, load it. C<file> must contain a JSON map.

   $loader->load( $file, @dict );

This method is used internally by L<Data::Phrasebook::Generic>'s
C<data> method, to initialise the data store.

It must take a C<file> (be it a scalar, or something more complex)
and return a handle. The C<dict> is optional, should you wish to use the
dictionary support.

=cut

sub load {
    my ($class, $file, @dict) = @_;
    croak "No file given as argument!"          unless defined $file;
    croak "Unable to read file [$file]!"        unless -r $file;
    my $json = read_file( $file );
    croak "No data in given JSON file [$file]"  unless $json;
    my $data = decode_json($json);
    croak "Badly formatted JSON file [$file]"   unless $data;
	$class->{json} = $data;

    # what sections are we using?
    my $key = $class->{defaultname} || ($class->dicts)[0];
    $class->{default} = ($key ? $class->{json}->{$key}
                              : $class->{json});

    $class->{dict} = [];
    $class->{dict} = [$class->{defaultname}] if $class->{defaultname};
    $class->{dict} = (ref $dict[0] ? $dict[0] : [@dict]) if scalar @dict;
}

=head2 get

Returns the phrase stored in the phrasebook, for a given keyword.

   my $value = $loader->get( $key );

If one or more named dictionaries have been previously selected, they will be
searched in order, followed by the default dictionary. The first hit on
C<key> will be returned, otherwise C<undef> is returned.

=cut

sub get {
	my ($class,$key) = @_;
	return	unless($key);
	return	unless($class->{json});

    my @dicts = (ref $class->{dict} ? @{$class->{dict}} : ());

    foreach ( @dicts ) {
        return $class->{json}->{$_}->{$key}
            if exists $class->{json}->{$_}
            and exists $class->{json}->{$_}->{$key};
    }

    return $class->{default}->{$key}
        if ref $class->{default} eq 'HASH'
        and exists $class->{default}->{$key};

    return;
}

=head2 dicts

Returns the list of dictionaries available.

   my @dicts = $loader->dicts();

This is the list of all dictionaries available in the source file. If multiple
dictionaries are not being used, then an empty list will be returned.

=cut

sub dicts {
    my $class = shift;

    my @keys = keys %{$class->{json}};
    if ( scalar @keys ==
            scalar grep {ref $_ eq 'HASH'} values %{$class->{json}} ) {
        # data source looks like it has multiple dictionaries
        return (sort @keys);
    }

    return ();
}

=head2 keywords

Returns the list of keywords available. List is lexically sorted.

 my @keywords = $loader->keywords( $dict );

If one or more named dictionaries have been previously selected, they will be
farmed for keywords, followed by the default dictionary.

The C<dict> argument is optional, and may be used to override the search to a
single named dictionary, or a list of dictionaries if passed by reference,
plus the default dictionary of course.

To find all available keywords in all available dictionaries, use the
following:

 $loader->keywords( [ $loader->dicts ] );

=cut

sub keywords {
    my ($class, $dict) = @_;
    my (%keywords, @dicts);

    @dicts = ( (not $dict) ? (ref $class->{dict} ? @{$class->{dict}} : ())
             : (ref $dict) ? @$dict : ($dict) );

    foreach my $d (@dicts) {
        next unless
            exists $class->{json}->{$d}
            and ref $class->{json}->{$d} eq 'HASH';
        map { $keywords{$_} = 1 } keys %{$class->{json}->{$d}};
    }

    if (ref $class->{default} eq 'HASH') {
        map { $keywords{$_} = 1 } keys %{$class->{default}};
    }

    my @keywords = sort keys %keywords;
    return @keywords;
}

=head2 set_default

If a requested phrase is not found in the named dictionary an attempt is made
to find it in the I<default> dictionary. L<Data::Phrasebook> loaders normally
use the first dictionary in the phrasebook as the default, but as mentioned in
L</"DICTIONARY SUPPORT"> this does not make sense because the dictionaries in
JSON phrasebooks are not ordered.

To override the automatically selected default dictionary use this method, and
pass it a C<default_dictionary_name>. This value is only reset at phrasebook
load time, so you'll probably need to trigger a reload:

 $q->loader->set_default( $default_dictionary_name );
 $q->loader->load( $file );

To reset the loader's behaviour to automatic default dictionary selection,
pass this method an undefined value, and then reload.

=cut

sub set_default {
    $_[0]->{defaultname} = $_[1];
}

1;

__END__

=head1 DICTIONARY SUPPORT

This loader supports the use of dictionaries, as well as multiple dictionaries
with a search order. If you are unfamiliar with these features, see
L<Data::Phrasebook> for more information.

Source data format for a single unnamed dictionary is a JSON stream that has
as its I<root node> an anonymous hash, like so:

  { 
    "first_key": "first_value", "second_key": "second_value"
  }

In this case, specifying one or more named dictionaries will have no effect.
The single dictionary that comprises the JSON file will take the place of your
I<default> dictionary, so will always be searched. To override this behaviour
use the C<set_default> object method.

Multiple dictionaries B<must> be specified using a two-level hash system,
where the root node of your JSON file is an anonymous hash containing
dictionary names, and the values of those hash keys are further anonymous
hashes containing the dictionary contents. Here is an example:

  { 
    "dict_one": { "first_key": "first_value", "second_key": "second_value" },
    "dict_two": { "first_key": "first_value", "second_key": "second_value" }
  }

If you use any other structure for your JSON dictionary files, the result is
uncertain, and this loader module is very likely to crash your program.

If a requested phrase is not found in the named dictionary an attempt is made
to find it in the I<default> dictionary. L<Data::Phrasebook> loaders normally
use the first dictionary in the phrasebook as the default, but this does not
make sense because JSON phrasebook files contain an unordered hash of
dictionaries.

This loader will therefore select the first dictionary from the list of
I<lexically sorted> dictionary names to be the default. To override this
behaviour use the C<set_default> object method. Alternatively, just include a
dictionary that is guaranteed to be selected for the default (e.g.
C<0000default>); it need not contain any keys.

=head1 ALTERNATIVES

This module was written to use JSON::XS. If you prefer to use JSON::Syck, I 
heartily recommend using L<Data::Phrasebook::Loader::JSON::Syck> by Stevan 
Little. The only reason I didn't use his module is beacuse this was used in
a project already using JSON::XS, and I didn't want to use two different
JSON parsers.

=head1 SEE ALSO

L<Data::Phrasebook>,
L<Data::Phrasebook::Loader>.

=head1 BUGS, PATCHES & FIXES

There are no known bugs at the time of this release. However, if you spot a
bug or are experiencing difficulties, that is not explained within the POD
documentation, please send an email to barbie@cpan.org or submit a bug to the
RT system (http://rt.cpan.org/). However, it would help greatly if you are
able to pinpoint problems or even supply a patch.

Fixes are dependent upon their severity and my availability. Should a fix not
be forthcoming, please feel free to (politely) remind me.

=head1 AUTHOR

  Barbie <barbie@cpan.org>
  for Miss Barbell Productions <http://www.missbarbell.co.uk>.

=head1 COPYRIGHT AND LICENSE

  Copyright (C) 2013-2014 Barbie for Miss Barbell Productions.

  This distribution is free software; you can redistribute it and/or
  modify it under the Artistic License 2.0.

=cut
