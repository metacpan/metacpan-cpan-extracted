# Copyright 2004 Nathan Poznick.  All rights reserved.
# Create semi-random sentences based upon a body of text.
# Distributed under the terms of the GPL Version 2

package Acme::Wabby;
$Acme::Wabby::VERSION='0.13';

use strict;
use warnings;
use Storable;

use vars qw($VERSION);

# Default values for various configurable settings
use constant DEF_CASE => 1;
use constant DEF_MIN_LEN => 3;
use constant DEF_MAX_LEN => 30;
use constant DEF_MAX_ATTEMPTS => 1000;
use constant DEF_PUNCTUATION => [".","?","!","..."];
use constant DEF_HASH_FILE => "./wabbyhash.dat";
use constant DEF_LIST_FILE => "./wabbylist.dat";
use constant DEF_AUTOSAVE => 0;

# Constructor.  Note that Acme::Wabby only supports an OO interface.
# Arguments: A reference to a hash containing configuration key/value pairs.
# Returns:   A reference to the created object. Dies on error.
sub new {
    my $self = shift;
    my %conf;

    if (@_ == 1) {
        my $ref = shift;
        if (!ref($ref)) {
            die "Sanity check: One parameter passed, and it is not a reference";
        }
        elsif (ref($ref) eq "HASH") {
            %conf = %{$ref};
        }
        else {
            die "Sanity check: One parameter passed, and it is not a hash reference";
        }
    }
    elsif (@_ % 2 != 0) {
        die "Sanity check: Odd number of parameters, expecting a hash";
    }
    else {
        %conf = @_;
    }

    # Set up the initial state of our data structures
    my %hash = ();
    my @list = ({ word => "(null)", num => []});
    my %data = ('hash' => \%hash, 'list' => \@list);

    # Go through each of the configuration options, and if they were not
    # explicitly set, assign to them the defaults.
    if (!exists($conf{'case_sensitive'})) {
        $conf{'case_sensitive'} = DEF_CASE;
    }
    if (!exists($conf{'min_len'})) {
        $conf{'min_len'} = DEF_MIN_LEN;
    }
    if (!exists($conf{'max_len'})) {
        $conf{'max_len'} = DEF_MAX_LEN;
    }
    if (!exists($conf{'max_attempts'})) {
        $conf{'max_attempts'} = DEF_MAX_ATTEMPTS;
    }
    if (!exists($conf{'punctuation'})) {
        $conf{'punctuation'} = DEF_PUNCTUATION;
    }
    if (!exists($conf{'hash_file'})) {
        $conf{'hash_file'} = DEF_HASH_FILE;
    }
    if (!exists($conf{'list_file'})) {
        $conf{'list_file'} = DEF_LIST_FILE;
    }
    if (!exists($conf{'autosave_on_destroy'})) {
        $conf{'autosave_on_destroy'} = DEF_AUTOSAVE;
    }

    # Do some simple sanity checks on the values that they sent us
    if ($conf{'min_len'} > $conf{'max_len'}) {
        die "min_len ($conf{'min_len'}) cannot be larger than"
            ."max_len ($conf{'max_len'})";
    }
    if ($conf{'min_len'} < 1) {
        die "Cannot be negative: min_len";
    }
    if ($conf{'max_len'} < 1) {
        die "Cannot be negative: max_len";
    }
    if ($conf{'max_attempts'} < 1) {
        die "Cannot be negative: max_attempts";
    }
    if (ref($conf{'punctuation'}) ne 'ARRAY') {
        die "Not an array reference: punctuation";
    }
    if (scalar(@{$conf{'punctuation'}}) < 1) {
        die "Array must contain at least one element: punctuation";
    }
    if ($conf{'list_file'} eq $conf{'hash_file'}) {
        die "list_file and hash_file cannot point to the same file";
    }

    # Return our blessed object
    return bless({ conf=>\%conf, data=>\%data}, __PACKAGE__);
}

# A destructor for the object, so that we get a chance to autosave the state
# if the caller so desired.
# Arguments: None.
# Returns:   Nothing.
sub DESTROY {
    my $self = shift;
    die "Invalid object" unless (ref($self) eq __PACKAGE__);

    if ($self->{'conf'}{'autosave_on_destroy'}) {
        $self->save;
    }
}

# A method for dumping the current state to files using Storable.
# Arguments: None.
# Returns:   undef on failure, true on success.
sub save {
    my $self = shift;
    die "Invalid object" unless (ref($self) eq __PACKAGE__);

    # Since Storable can die on serious errors, or simply return an undef,
    # we need to wrap these calls in evals
    eval {
        if (!store($self->{'data'}{'list'}, $self->{'conf'}{'list_file'})) {
            $@ = 1;
        }
    };
    if ($@) {
        return undef;
    }

    eval {
        if (!store($self->{'data'}{'hash'}, $self->{'conf'}{'hash_file'})) {
            $@ = 1;
        }
    };
    if ($@) {
        return undef;
    }

    return 1;
}

# A method for loading a previously saved state from files using Storable.
# Arguments: None.
# Returns:   undef on failure, true on success
sub load {
    my $self = shift;
    die "Invalid object" unless (ref($self) eq __PACKAGE__);

    # Since Storable can die on serious errors, or simply return an undef,
    # we need to wrap these calls in evals
    my $ref;
    eval {
        if (!($ref = retrieve($self->{'conf'}{'list_file'}))) {
            $@ = "Error retrieving list from " . $self->{'conf'}{'list_file'};
        }
    };
    if ($@) {
        return undef;
    }
    @{$self->{'data'}{'list'}} = @{$ref};

    eval {
        if (!($ref = retrieve($self->{'conf'}{'hash_file'}))) {
            $@ = "Error retrieving hash from " . $self->{'conf'}{'hash_file'};
        }
    };
    if ($@) {
        return undef;
    }
    %{$self->{'data'}{'hash'}} = %{$ref};

    return 1;
}

# A method for adding a block of text to the current state.
# Arguments: Takes a scalar containing text to be added.  Embedded newlines,
#            random crap, et al are fine, they'll just be stripped out anyway.
# Returns:   undef on failure, true on success.  The only failure condition is
#            currently if an invalid parameter is passed in.
sub add {
    my $self = shift;
    die "Invalid object" unless (ref($self) eq __PACKAGE__);

    # Make sure we actually got something to add
    my $text = shift;
    unless ($text) {
        return undef;
    }

    # If we don't care about case, lowercase the whole thing to start with
    unless ($self->{'conf'}{'case_sensitive'}) {
        $text = lc($text);
    }

    # Split the text into component phrases, which we define as being delimited
    # by the characters below.  I left the comma out because it seems to lead
    # to slightly more coherent results.
    my @phrases = split /[.!?;]/, $text;
    foreach my $phrase (@phrases) {

        # First, strip out any characters we don't want to deal with.  We
        # replace them with a space so that things like "the+dog" gets treated
        # as "the dog".
        $phrase =~ s/[^-a-zA-Z0-9 ']/ /g;

        # Trim leading and trailing whitespace, and see if we still have
        # anything left.
        $phrase =~ s/^\s+//;
        $phrase =~ s/\s+$//;
        next if $phrase eq "";

        my $last_word = 0;
        my $idx = 0;
        # Split the phrase into component words.  We're splitting on simple
        # whitespace here.
        my @words = split /\s+/, $phrase;

        # First we're going to loop through the words and clean them up a bit.
        # While we're at it, we're going to find the index of the last real
        # word in this phrase.
        foreach my $word (@words) {

            # Clean up the word a little bit.  We allow hyphens and
            # apostrophies to occur within words, but not at the beginning
            # or ends of words.
            $word =~ s/^\s+//;
            $word =~ s/\s+$//;
            $word =~ s/^-+//g;
            $word =~ s/^'+//g;
            $word =~ s/-+$//g;
            $word =~ s/'+$//g;

            # Only allow the single-character words of 'a' and 'I'.
            # FIXME - Need to be able to configure this so that persons with
            # non-english texts can pick values that make sense.
            if (length($word) == 1 && lc($word) ne "i" && lc($word) ne "a") {
                $word = "";
                $idx++;
                next;
            }

            # If this is a valid word, then mark this as a possible last word.
            if ($word ne "") {
                $last_word = $idx;
            }
            $idx++;
        }

        $idx = 0;
        my $new_index = 0;
        my $old_index = 0;

        # Now we loop through the words, recording the transitions between them.
        foreach my $word (@words) {

            # Shock shock, we're going to ignore non-existent words.
            if ($word eq "") {
                $idx++;
                next;
            }

            # If this is a new word that we've never seen before
            if (!exists($self->{'data'}{'hash'}{$word})) {

                # Add this word to the end of the word list, and to the hash,
                # taking care to record its index for the next loop iteration.
                $new_index = scalar(@{$self->{'data'}{'list'}});
                $self->{'data'}{'hash'}{$word} = $new_index;
                push @{$self->{'data'}{'list'}}, {word => $word, num => []};

                # Add a transition from the previous word to this word.
                push @{${$self->{'data'}{'list'}}[$old_index]{'num'}},
                    $new_index;

                # If this word happens to be the last in the phrase, add a -1
                # to its possible transitions so that we have the possibility
                # of ending sentences here.
                if ($idx == $last_word) {
                    push @{${$self->{'data'}{'list'}}[$new_index]{'num'}}, -1;
                }
            }

            # If we've seen this word before
            else {
                # Record the index of this word for the next loop iteration,
                # and add a transition from the previous word to this one.
                $new_index = $self->{'data'}{'hash'}{$word};
                push @{${$self->{'data'}{'list'}}[$old_index]{'num'}},
                    $new_index;

                # If this word happens to be the last in the phrase, add a -1
                # to its possible transitions so that we have the possibility
                # of ending sentences here.
                if ($idx == $last_word) {
                    push @{${$self->{'data'}{'list'}}[$new_index]{'num'}}, -1;
                }
            }
            # Move on to the next word.
            $old_index = $new_index;
        }
    }

    return 1;
}

# A function for generating a random line of text.
# Arguments: If no arguments, spew will try to generate a completely random
#            sentence.  If a string is passed in, spew will try to generate a
#            random sentence beginning with the provided text.
# Returns:   The generated string, or undef on any of several error conditions.
#            Note that these error conditions are not fatal.  They are:
#               * At least (min_len * 10) words haven't been run through yet.
#                 (Must ->add() more text before trying again.)
#               * A string was passed in containing nothing. (Don't do that.)
#               * We don't know the last word in the sentence, and can therefore
#                 not generate a sentence with it. (Either teach us about it
#                 with ->add(), or try something else.)
#               * A sentence of at least min_len words could not be generated,
#                 even after max_attempts tries at doing so. (Likely need to
#                 ->add() more text before trying again.)
#               
sub spew {
    my $self = shift;
    die "Invalid object" unless (ref($self) eq __PACKAGE__);
    my $text = shift;

    # If we don't have at least 10 * min_len words, we probably don't have a
    # very good chance of making a sentence, so let's just return.
    if (scalar(keys %{$self->{'data'}{'hash'}}) <
            ($self->{'conf'}{'min_len'} * 10)) {
        return undef;
    }

    my $directed;
    my $start;

    # If they passed in an argument, take a look at it.
    if ($text) {
        $directed = 1;

        # If we're case-insensitive, lowercase what they sent us.
        unless ($self->{'conf'}{'case_sensitive'}) {
            $text = lc($text);
        }

        # Weed out unsavory characters.
        $text =~ s/[^-a-zA-Z0-9 ']/ /gs;

        # Clean any long strings of whitespace to single spaces.
        $text =~ s/\s+/ /g;

        # Remove leading and trailing whitespace.
        $text =~ s/^\s+//;
        $text =~ s/\s+$//;

        # If there's not a word left to talk about, return.
        if ($text !~ /([-a-zA-Z0-9']+)$/) {
            return undef;
        }

        # If we don't know anything about this word, return.
        if (!exists(${$self->{'data'}{'hash'}}{$1})) {
            return undef;
        }

        # Seems like a good starting place, so let's mark it.
        $start = ${$self->{'data'}{'hash'}}{$1};
    }
    # They didn't pass an argument, so we're on our own.
    else {
        $directed = 0;

        # The 0th element in the list is 'special' in that no hash entry points
        # to it, and it only contains pointers to words which are possible
        # sentence starting points.  Thus, let's grab a random entry out of the
        # 0th element in the list and start there.
        $start = ${${$self->{'data'}{'list'}}[0]{'num'}}[int rand scalar @{${$self->{'data'}{'list'}}[0]{'num'}}];
        $text = ${$self->{'data'}{'list'}}[$start]{'word'};
    }

    # Since we're dealing with randomness, we can't always be sure that we'll
    # be able to make a sentence of min_len, so we just keep retrying up to
    # max_attempts times, relying on sheer dumb luck to help us out.  On a
    # reasonably-sized body of text, this works perfectly fine.
    my $attempts = 0;
    my $count = 0;
    my $final = "";
    my $next = $start;

    while ($count < $self->{'conf'}{'min_len'} &&
            $attempts < $self->{'conf'}{'max_attempts'}) {

        # We start out with one word, and uppercase the first character in our
        # starting text.
        $count = 1;
        $final = "\u$text";
        $next = $start;

        # Keep adding new words to this sentence until we hit an sentence end
        # mark, or we hit max_len
        while ($next != -1 && ($count < $self->{'conf'}{'max_len'})) {

            # If the word we're on has no transitions, count this as a stopping
            # point, since we can't go any further.
            if (scalar(@{${$self->{'data'}{'list'}}[$next]{'num'}}) < 1) {
                $next = -1;
            }
            # Otherwise, randomly pick the word we'll visit next out of the
            # list of possible transitions from our current word.
            else {
                $next = ${${$self->{'data'}{'list'}}[$next]{'num'}}[int rand scalar @{${$self->{'data'}{'list'}}[$next]{'num'}}];
            }

            # If we're not at the end yet, add this word to our collected
            # string, increment our word count, and do it all again. 
            if ($next != -1) {
                $final .= " " . ${$self->{'data'}{'list'}}[$next]{'word'};
                $count++;
            }
        }

        # If we failed to make a long enough sentence, we need to do something.
        if ($count < $self->{'conf'}{'min_len'}) {

            # If we haven't yet passed our max number of attempts, try again.
            if ($attempts < $self->{'conf'}{'max_attempts'}) {
                $attempts++;
                next;
            }
            # If we passed our max number of attempts, we can take one of two
            # course of action.
            else {
                # If we're trying to talk about something in particular, we're
                # always going to be stuck with the same starting point.  Thus,
                # there's not the best chance for continued success, so just
                # give up and bail.
                if ($directed) {
                    return undef;
                }
                # If we're talking about random things, we likely just got
                # a bad starting point, so we'll pick a new random starting
                # point, and do the whole thing over again.
                else {
                    $attempts = 0;
                    $start = ${${$self->{'data'}{'list'}}[0]{'num'}}[int rand scalar @{${$self->{'data'}{'list'}}[0]{'num'}}];
                    $text = ${$self->{'data'}{'list'}}[$start]{'word'};
                    next;
                }
            }
        }
    }

    # If we're not case sensitive, make sure any I's by themselves are
    # capitalized, for aesthetic purposes.  If we are, they probably want
    # things to come out the way they are.
    # FIXME - Need to be able to configure this so that persons with
    # non-english texts can pick values that make sense.
    unless ($self->{'conf'}{'case_sensitive'}) {
        $final =~ s/(^|[^\w-])i($|[^\w-])/$1I$2/g
    }

    # Pick a random piece of punctuation to add to the end of the sentence.
    $final .= ${$self->{'conf'}{'punctuation'}}[int rand scalar @{$self->{'conf'}{'punctuation'}}];

    return $final;
}

# A method for getting some basic information about the current state.
# Arguments: None.
# Returns:   In a scalar context, this function returns a string describing the
#            current state.  In a list context, this function returns a list
#            containing two numbers -- the first one is the number of words
#            that this object knows about, and the second one is the average
#            number of transitions between words.
sub stats {
    my $self = shift;
    die "Invalid object" unless (ref($self) eq __PACKAGE__);

    # Get the number of words in our hash.
    my $word_count = scalar keys %{$self->{'data'}{'hash'}};

    # If we've got no words, just quit now.
    if ($word_count == 0) {
        return wantarray ? (0,0) : "I don't know anything!";
    }

    # Iterate over the list, adding up the number of transitions for each word.
    my $average = 0;
    foreach (@{$self->{'data'}{'list'}}) {
        $average += scalar @{$_->{'num'}} if defined($_->{'num'});
    }

    # Calculate an average, trim it to two decimal points, and return it.
    $average /= $word_count;
    $average = sprintf "%.2f", $average;
    return wantarray ? ($word_count, $average) : "Wabby knows $word_count "
        ."words, with an average of $average connections between each word.";
}

1;

__END__

=head1 NAME

Acme::Wabby - Create semi-random sentences based upon a body of text.

=head1 SYNOPSIS

  use Acme::Wabby qw(:errors);

  # Use the default options
  my $wabby = Acme::Wabby->new;

  # Pass in explicit options. (All options below are defaults)
  my $wabby = Acme::Wabby->new( min_len => 3, max_len => 30,
      punctuation => [".","?","!","..."], case_sensitive => 1,
      hash_file => "./wabbyhash.dat", list_file => "./wabbylist.dat",
      autosave_on_destroy => 0, max_attempts => 1000 );

  # Save the current state to the configured files
  $wabby->save;

  # Load a saved state from the configured files
  $wabby->load;

  # Add some text to the current state
  $wabby->add($the_complete_works_of_shakespeare);

  # Generate a random sentence
  print $wabby->spew, "\n";

  # Generate a random sentence, beginning with "The"
  print $wabby->spew("Romeo and Juliet"), "\n";

  # Produce a string containing some info about the current state
  print scalar($wabby->stats), "\n";

  # Produce a list containing the word count and average connection count
  my ($wordcount, $average) = $wabby->stats;
  print "Wabby knows $wordcount words, with an average number of"
      ."connections between each word of $average\n";

=head1 DESCRIPTION

This module is used to create semi-random sentences based on a body of text.
It uses a markov-like method of storing probabilities of word transitions.
It is good for annoying people on IRC, AIM, or other such fun mediums.

Acme::Wabby only provides an object-oriented interface, and exports no
symbols into the caller's namespace.  Each object is self-contained, so there
are no issues with creating and using multiple objects from within the same
calling program.

=head2 Creating an object

To begin using Acme::Wabby you must first create a new object:

  my $wabby = Acme::Wabby->new(min_len => 3, max_len => 30,
      punctuation => [".","?","!","..."], case_sensitive => 1,
      hash_file => "./wabbyhash.dat", list_file => "./wabbylist.dat",
      autosave_on_destroy => 0, max_attempts => 1000 );

All configuration values passed to the object constructor are optional, and
have sensible defaults.  The following is a description of the parameters
and their default values.

=over 8

=item min_len

The minimum length for a generated sentence. (3)

=item max_len

The maximum length for a generated sentence. (30)

=item punctuation

A reference to an array containing possible punctuation with which to end sentences. ([".","?","!","..."])

=item case_sensitive

Whether or not to treat text in a case sensitive manner. (1)

=item hash_file

The file to/from which the hash data will be stored/loaded if requested. ("./wabbyhash.dat")

=item list_file

The file to/from which the list data will be stored/loaded if requested. ("./wabbylist.dat")

=item autosave_on_destroy

Whether or not to automatically save the state upon object destruction. (0)

=item max_attempts

The maximum number of attempts to create a sentence before giving up. (1000)

=back

=head2 Adding text to the state

To have an amusing experience, you will need to feed the object a body of text.
This text can come from virtually any source, although I enjoy using e-Texts
from the good folks at Project Gutenberg (http://promo.net/pg).  To add text to
the state, simply call the B<add()> method on the object, passing it a scalar
containing the text.

  $wabby->add($complete_works_of_shakespeare);

It is acceptable for the input text to contain embedded newlines or other such
things.  It is acceptable to call the B<add()> method many times, and at any
point in the object's life-span.  The B<add()> method will return B<undef> upon
error, and true upon success.

=head2 Generating random sentences

Once you have some text loaded into the object, you can generate random
sentences.  To do this, we use the B<spew()> method.  The B<spew()> method has
two modes of operation:  If no argument is given, it will generate and return a
random sentence.  If a single string is passed in, it will generate and return
a random sentence beginning with the provided string.

  my $random_sentence = $wabby->spew;
  my $not_so_random_sentence = $wabby->spew("Romeo and Juliet");

The B<spew()> method will return the generated string, or B<undef> upon error.
There are several error conditions which can occur in the B<spew()> method.
None of them are fatal, but they must be taken into account by the calling
program.  They are:

* At least (min_len * 10) words haven't been run through yet. (Must B<add()>
more text before trying again.)

* A string was passed in containing nothing. (Don't do that.)

* We don't know the last word in the string passed in, and can therefore not
generate a sentence with it. (Either teach us about it with B<add()>, or try
something else.)

* A sentence of at least min_len words could not be generated, even after
max_attempts tries at doing so. (Likely need to B<add()> more text before
trying again.)

=head2 Saving / loading state

Acme::Wabby can save and load state to disk using the Storable module.  To do
this, simply use the B<save()> and/or B<load()> methods.

  $wabby->save;
  $wabby->load;

These methods take no arguments, they simply save or load the state to or from
the file names which were defined when the object was created.  Loading a
saved state is much faster than re-parsing a large body of text.

=head2 Getting statistics

Using the B<stat()> method will provide you with some simple statistics about
the current state of an object.  When used in a scalar context, the B<stat()>
method will return a string containing a description of what the object knows.
When used in a list context, it will return a list of two numbers.  The first
entry in the list is the number of words that the object knows.  The second
entry in the list is the average number of connections between words.

  my ($wordcount, $average) = $wabby->stats;
  print "count=$wordcount, average=$average\n";
  print scalar($wabby->stats), "\n";

=head1 BUGS

 * Uses a lot of memory (not so much a bug as an implementation quirk).

=head1 TODO

 * Be better about normalizing input text.
 * Fix english assumtions about single-letter words besides I and a.
 * See about making the parsing into phrases and words more configurable.
 * Investigate using longer-order chains to improve generation quality.
 * Try to use less memory!

=head1 AUTHOR

Nathan Poznick <kraken@wang-fu.org>

=head1 CREDITS

 nick@misanthropia.nu - for writing the original wabbylegs.pl
 Project Gutenberg - for providing free text to feed to Acme::Wabby.

=head1 COPYRIGHT

Copyright (c) 2004, Nathan Poznick.  All rights reserved.  This program is free
software; you can redistribute it and/or modify it under the terms of the GPL
version 2.

=cut
