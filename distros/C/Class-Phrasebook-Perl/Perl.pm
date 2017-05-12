package Class::Phrasebook::Perl;

use warnings;
use strict;

our $VERSION = '0.01';

=head1 NAME

Class::Phrasebook::Perl - Implements the Phrasebook pattern, using an all Perl dictionary file.

=head1 SYNOPSIS

  use Class::Phrasebook::Perl;

  $pb = new Class::Phrasebook::Perl("phrasebook.pl");

  $pb->load("en");
  $phrase = $pb->get("hello-world");
  $phrase = $pb->get("the-hour", hour => "10:30");

  $pb->load("fr");
  $phrase = $pb->get("hello-world");
  $phrase = $pb->get("the-hour", hour => "10h30");

=head1 DESCRIPTION

This class implements the Phrasebook pattern, which allows us to create dictionaries of phrases.  Each phrase is accessed via a unique key and may contain placeholders which are replaced when the phrase is retrieved.  Groups of phrases are stored in dictionaries, with the default dictionary being the one that alphabetically occurs first.  Phrases are stored in a Perl configuration file, which allows values to be scalars, arrays, hashes or even subroutines.

=head1 CONSTRUCTOR

  $pb = new Class::Phrasebook::Perl($filename, Verbose => 1);

The constructor accepts one required parameter, $filename, and a named hash of optional parameters. $filename is the name of the phrasebook configuration file to load and whose format is described below.  The optional named hash recognizes the following values:

  Verbose - Enables debugging messages when set to 1.  The default is 0.

The constructor returns an instance of a Class::Phrasebook::Perl object upon success, and undef on failure.  The default dictionary is set to the one which alphabetically occurs first.

=head1 METHODS

  $pb->load($dictionary);

The load method attempts to load the specified dictionary.  It will return a true value on success, and false value on failure.

  $pb->get($phrase, %args);

The get method retrieves the specified phrase from the currently loaded dictionary.  It accepts an optional named hash of arguments which will be used to replace placeholder values in the phrase.  The keys in the %args hash are assumed to be the names of the placeholders in the phrase.  Placeholders are denoted by having a '%' in front of their name.  For example, if we have the following phrase:

  "The time now is %hour"

and we call the get method as follows:

  $pb->get('the-hour', hour => "10:30");

Then the phrases' '%hour' placeholder will be replaced with the value of the 'hour' key in the named hash, which is "10:30".

=head1 CONFIGURATION FILE

The configuration file is written in Perl and is read in and eval()'d during object instantiation.  The result of the eval() is expected to be a reference to a hash and contains keys which are considered to be the dictionary names.  The dictionary keys point to another hash reference, whose keys are considered to be the phrase names and whose values are the phrases.  While the term "phrase" may imply that the value is a string. arrays, hashes and subroutines are also allowable.

An example configuration file follows:

  {
    'en' => { 'hello-world' => 'Hello, World!',
              'the-hour'    => 'The time now is %hour.' }

    'fr' => { 'hello-world' => 'Bonjour le Monde!!!',
              'the-hour'    => 'Il est maintenant %hour.' }
  }

In this example, the phrasebook contains two dictionaries: 'en' and 'fr', which contain English and French versions of the same phrases, respectively.  Each dictionary contains two phrases: 'hello-world' and 'the-hour'.  The 'the-hour' phrase contains a placeholder, '%hour', which will be replaced with a supplied value when the phrase is retrieved.

The above example contains string-only phrases - it is possible, however, to have arrays, hashes and subroutines as values:

  {
    'example' => { 'array' => [ 'biff!', 'bam!', 'chicka-pow!' ],
                   'hash'  => { sound => 'bork!', noise => 'bonk!' },
                   'code'  => sub { return "ka-plooey!\n" } }
  }

In this example, loading the 'example' dictionary and retrieving the 'array', 'hash' and 'code' phrases would return an array reference, hash reference and a code reference, respectively.

  $pb->load('example');

  $array = $pb->get('array');
  $hash  = $pb->get('hash');
  $code  = $pb->get('code');

Since place holders don't make much sense in array, hash or code contexts, any replacement values passed in to the get method will be ignored.  To retrieve an array or a hash, instead of an array or hash reference, use @{..} and %{..} to force to the appropriate contexts:

  @array = @{$pb->get('array')};
  %hash  = %{$pb->get('hash')};

Code values can be called in the standard fashion, passing it any arguments to the subroutine if applicable:

  $code->();
  $code->(1, 'speelunk!', noise => 'whir!');

=head1 AUTHOR

Cory Spencer <cspencer@sprocket.org>

=head1 SEE ALSO

Class::Phrasebook

=head1 COPYRIGHT

Copyright (c) 2004 Cory Spencer. All rights reserved.  This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

sub new {
  my ($class, $filename, %args) = @_;
  my ($self) = bless({ }, $class);

  $self->{verbose} = $args{Verbose} || 0;

  if (open(PBOOK, "<$filename")) {
    $self->{phrasebook} = eval(join('', <PBOOK>));
    close(PBOOK);

    if ($@) {
      # eval failed - return a null object.
      print(STDERR "Error while loading phrasebook: $@\n") if
	($self->{verbose});
      return undef;
    }

    if (ref($self->{phrasebook}) ne "HASH") {
      # we didn't get the format we were expecting.
      print(STDERR "Error: phrasebook is not a hash reference\n") if
	($self->{verbose});
      return undef;
    }
  } else {
    # open failed - return a null object.
    print(STDERR "Error: open $filename: $!\n") if ($self->{verbose});
    return undef;
  }

  $self->{dictionary} = (sort(keys(%{$self->{phrasebook}})))[0];

  return $self;
}

sub load {
  my ($self, $dict) = @_;

  # Return an error if the dictionary doesn't exist.
  if (! exists($self->{phrasebook}->{$dict})) {
    print(STDERR "Error: dictionary '$dict' not found in phrasebook\n")
      if ($self->{verbose});
    return 0;
  }

  $self->{dictionary} = $dict;

  return 1;
}

sub get {
  my ($self, $phrase, %args) = @_;

  if (! defined($self->{dictionary})) {
    print(STDERR "Error: no dictionary has been selected\n")
       if ($self->{verbose});
    return undef;
  }

  my $value = $self->{phrasebook}->{$self->{dictionary}}->{$phrase};

  if ($value && (! ref($value))) {
    # Value isn't a hash, array or code - interpolate any necessary values.
    $value =~ s/%$_/$args{$_} || ''/ge for keys(%args);
  }

  return $value;
}

1;
