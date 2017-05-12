package Data::Phrasebook::Loader::XML;

use strict;
use warnings FATAL => 'all';

our $VERSION = '0.16';

#--------------------------------------------------------------------------

use base qw( Data::Phrasebook::Loader::Base Data::Phrasebook::Debug );

use Carp qw( croak );
use XML::Parser;
use IO::File;

#--------------------------------------------------------------------------

=head1 NAME

Data::Phrasebook::Loader::XML - Absract your phrases with XML.

=head1 SYNOPSIS

    use Data::Phrasebook;

    my $q = Data::Phrasebook->new(
        class  => 'Fnerk',
        loader => 'XML',
        file   => 'phrases.xml',
        dict   => 'Dictionary',     # optional
    );

  OR

    my $q = Data::Phrasebook->new(
        class  => 'Fnerk',
        loader => 'XML',
        file   => {
            file => 'phrases.xml',
            ignore_whitespace => 1,
        }
    );

    # simple keyword to phrase mapping
    my $phrase = $q->fetch($keyword);

    # keyword to phrase mapping with parameters
    $q->delimiters( qr{ \[% \s* (\w+) \s* %\] }x );
    my $phrase = $q->fetch($keyword,{this => 'that'});

=head1 DESCRIPTION

This class loader implements phrasebook patterns using XML.

Phrases can be contained within one or more dictionaries, with each phrase
accessible via a unique key. Phrases may contain placeholders, please see
L<Data::Phrasebook> for an explanation of how to use these. Groups of phrases
are kept in a dictionary. The first dictionary is used as the default, unless
a specific dictionary is requested.

In this implementation, the dictionaries and phrases are implemented with an
XML document. This document is the same as implement by L<Class::Phrasebook>.

The XML document type definition is as followed:

 <?xml version="1.0"?>
 <!DOCTYPE phrasebook [
           <!ELEMENT phrasebook (dictionary)*>
           <!ELEMENT dictionary (phrase)*>
               <!ATTLIST dictionary name CDATA #REQUIRED>
               <!ELEMENT phrase (#PCDATA)>
               <!ATTLIST phrase name CDATA #REQUIRED>
 ]>

An example XML file:

 <?xml version="1.0"?>
 <!DOCTYPE phrasebook [
           <!ELEMENT phrasebook (dictionary)*>
           <!ELEMENT dictionary (phrase)*>
               <!ATTLIST dictionary name CDATA #REQUIRED>
               <!ELEMENT phrase (#PCDATA)>
               <!ATTLIST phrase name CDATA #REQUIRED>
 ]>

 <phrasebook>
 <dictionary name="EN">
   <phrase name="HELLO_WORLD">Hello World!!!</phrase>
   <phrase name="THE_HOUR">The time now is $hour.</phrase>
   <phrase name="ADDITION">add $a and $b and you get $c</phrase>
   <phrase name="THE_AUTHOR">Barbie</phrase>
 </dictionary>

 <dictionary name="FR">
   <phrase name="HELLO_WORLD">Bonjour le Monde!!!</phrase>
   <phrase name="THE_HOUR">Il est maintenant $hour.</phrase>
   <phrase name="ADDITION">$a + $b = $c</phrase>
   <phrase name="THE_AUTHOR">Barbie</phrase>
 </dictionary>

 <dictionary name="NL">
   <phrase name="HELLO_WORLD">Hallo Werld!!!</phrase>
   <phrase name="THE_HOUR">Het is nu $hour.</phrase>
   <phrase name="ADDITION">$a + $b = $c</phrase>
   <phrase name="THE_AUTHOR">Barbie</phrase>
 </dictionary>
 </phrasebook>

Note that, unlike L<Class::Phrasebook>, this implementation does not search
the default dictionary if a phrase is not found in the specified dictionary.
This may change in the future.

Each phrase should have a unique name within a dictionary, which is then used
as a reference key. Within the phrase text placeholders can be used, which are
then replaced with the appropriate values once the get() method is called.

The parameter 'ignore_whitespace', will remove any extra whitespace from the
phrase. This includes leading and trailing whitespace. Whitespace around a
newline, including the newline, is replace with a single space.

If you need to use the '<' symbol in your XML, you'll need to use '&lt;'
instead.

    # <phrase name="TEST">$a &lt; $b</phrase>

    my $q = Data::Phrasebook->new(
        class  => 'Fnerk',
        loader => 'XML',
        file   => 'phrases.xml',
    );

    my $phrase = $q->fetch('TEST');    # returns '$a < $b'

=head1 INHERITANCE

L<Data::Phrasebook::Loader::XML> inherits from the base class
L<Data::Phrasebook::Loader::Base>.
See that module for other available methods and documentation.

=head1 METHODS

=head2 load

Given a C<file>, load it. C<file> must contain valid XML.

   $loader->load( $file, $dict );

This method is used internally by L<Data::Phrasebook::Generic>'s
C<data> method, to initialise the data store.

=cut

my $phrases;

sub load {
    my ($class, $file, $dict) = @_;
    my ($ignore_whitespace,$ignore_newlines) = (0,0);
    my @dictionaries;

    if(ref $file eq 'HASH') {
        $ignore_whitespace = $file->{ignore_whitespace};
        $ignore_newlines = $file->{ignore_newlines};
        $file = $file->{file};
    }
    croak "No file given as argument!" unless defined $file;
    croak "Cannot access file!" unless -r $file;

    $dict = ''  unless($dict);  # use default

    my $read_on = 1;
    my $default_read = 0;
    my ($phrase_name,$phrase_value);

    # create the XML parser object
    my $parser = XML::Parser->new(ErrorContext => 2);
    $parser->setHandlers(
        Start => sub {
            my $expat = shift;
            my $element = shift;
            my %attributes = (@_);

            # deal with the dictionary element
            if ($element =~ /dictionary/) {
                my $name = $attributes{name};
                croak('The dictionary element must have the name attribute')
                    unless (defined($name));
                push @dictionaries, $name;

                # if the default was already read, and the dictionary name
                # is not the requested one, we should not read on.
                $read_on = ($default_read && $name ne $dict) ? 0 : 1;
            }

            # deal with the phrase element
            if ($element =~ /^phrase$/) {
                $phrase_name = $attributes{name};
                croak('The phrase element must have the name attribute')
                    unless (defined($phrase_name));
            }

            $phrase_value = ''; # ensure a clean phrase
        }, # of Start

        End => sub {
            my $expat = shift;
            my $element = shift;
            if ($element =~ /^dictionary$/i) {
                $default_read = 1;
            }

            if ($element =~ /^phrase$/i) {
                if ($read_on) {
                    if($ignore_whitespace) {
                        $phrase_value =~ s/^\s+//;
                        $phrase_value =~ s/\s+$//;
                        $phrase_value =~ s/\s*[\r\n]+\s*/ /gs;
                    }
                    if($ignore_newlines) {
                        $phrase_value =~ s/[\r\n]+/ /gs;
                    }
                    $phrases->{$phrase_name} = $phrase_value;
                    $phrase_value = '';
                }
            }
        }, # of End

        Char => sub {
            my $expat = shift;
            my $string = shift;

            # if $read_on flag is true and the string is not empty we set the
            # value of the phrase.
            if ($read_on && length($string)) {
                $phrase_value .= $string;
            }
        } # of Char
    ); # of the parser setHandlers class

    my $fh = IO::File->new($file);
    croak("Could not open $file for reading.")  unless ($fh);

    eval { $parser->parse($fh) };
    croak("Could not parse the file [$file]: ".$@)  if ($@);

    $class->{dictionaries} = \@dictionaries;
    $class->{phrases} = $phrases;
}

=head2 get

Returns the phrase stored in the phrasebook, for a given keyword.

   my $value = $loader->get( $key );

=cut

sub get {
    my ($class, $key) = @_;
    return    unless($key);
    return $class->{phrases}->{$key} || undef;
}

=head2 dicts

Returns the list of dictionaries available.

   my @dicts = $loader->dicts();

=cut

sub dicts {
    my $class = shift;
    return @{$class->{dictionaries}};
}

=head2 keywords

Returns the list of keywords available.

   my @keywords = $loader->keywords();

=cut

sub keywords {
    my $class = shift;
    return ()    unless($class->{phrases});
    my @keywords = sort keys %{$class->{phrases}};
    return @keywords;
}

1;

__END__

=head1 CONTINUATION LINES

As a configuration option (default is off), continuation lines can be
used via the use of the 'ignore_whitespace' or 'ignore_newlines' options
as follows:

    my $q = Data::Phrasebook->new(
        class  => 'Fnerk',
        loader => 'XML',
        file   => {
            file => 'phrases.xml',
            ignore_whitespace => 1,
        }
    );

Using 'ignore_whitespace', all whitespace (including newlines) will be
collapsed into a single space character, with leading and trailing whitespace
characters removed.

    my $q = Data::Phrasebook->new(
        class  => 'Fnerk',
        loader => 'XML',
        file   => {
            file => 'phrases.xml',
            ignore_newlines => 1,
        }
    );

Using 'ignore_newlines', all newlines are removed, preserving whitespace
around them, should this be required.

=head1 SEE ALSO

L<Data::Phrasebook>.

=head1 BUGS, PATCHES & FIXES

There are no known bugs at the time of this release. However, if you spot a
bug or are experiencing difficulties, that is not explained within the POD
documentation, please send an email to barbie@cpan.org or submit a bug to the
RT system (http://rt.cpan.org/). However, it would help greatly if you are
able to pinpoint problems or even supply a patch.

Fixes are dependent upon their severity and my availability. Should a fix not
be forthcoming, please feel free to (politely) remind me.

=head1 AUTHOR

  Barbie, <barbie@cpan.org>
  for Miss Barbell Productions <http://www.missbarbell.co.uk>.

=head1 COPYRIGHT AND LICENSE

  Copyright (C) 2004-2014 Barbie for Miss Barbell Productions.

  This distribution is free software; you can redistribute it and/or
  modify it under the Artistic License 2.0.

=cut
