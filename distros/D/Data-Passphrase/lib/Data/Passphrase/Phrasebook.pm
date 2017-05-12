# $Id: Phrasebook.pm,v 1.4 2007/01/30 20:09:03 ajk Exp $

use strict;
use warnings;

package Data::Passphrase::Phrasebook; {
    use Object::InsideOut qw(Exporter);

    use Carp;
    use Fatal qw(open close);

    # export utility routines and configuration directive names
    BEGIN {
        our @EXPORT_OK = qw(build_phrasebook phrasebook_check);
    }

    # object attributes
    my @debug  :Field(Std => 'debug',  Type => 'numeric');
    my @file   :Field(Std => 'file',                    );
    my @filter :Field(Std => 'filter',                  );

    my %init_args :InitArgs = (
        debug  => {Def => 0, Field => \@debug,  Type => 'numeric'},
        file   => {          Field => \@file,                    },
        filter => {          Field => \@filter,                  },
    );

    # overload constructor so we can automatically load the phrase dictionary
    sub new {
        my ($class, $arg_ref) = @_;

        # unpack arguments
        my $debug = $arg_ref->{debug};

        $debug and warn 'initializing ', __PACKAGE__, ' object';

        # construct object
        my $self = $class->Object::InsideOut::new($arg_ref);

        # load rules from file
        if (exists $arg_ref->{file}) {
            $self->load();
        }

        # or at least initialize the filter
        else {
            $self->init_filter();
        }

        return $self;
    }

    # cache rulesets by filename
    my %Filter_Cache;

    # load the rules file if we need to
    sub load {
        my ($self) = @_;

        # unpack arguments
        my $debug = $self->get_debug();
        my $file  = $self->get_file () or croak 'file attribute undefined';

        $debug and warn "$file: checking readability";
        my $last_modified = 0;
        if (-r $file) {

            # don't re-read if file hasn't been modified since last time
            $last_modified = (stat _)[9];
            $debug and warn "$file: pid: $$, mod time: $last_modified, ",
                "last processed: ", $Filter_Cache{$file}{last_read};
            if (exists $Filter_Cache{$file}{last_read}
                    && $Filter_Cache{$file}{last_read} == $last_modified) {

                # point the object attribute at the current ruleset
                $self->set(\@filter, $Filter_Cache{$file}{filter});

                return;
            }

            # construct a filter & read the file in
            $self->init_filter();
            my $dictionary_file = $self->get_file();
            open my ($dictionary_handle), $dictionary_file;
            while (my $phrase = <$dictionary_handle>) {
                chomp $phrase;
                $self->add($self->normalize($phrase));
            }
            close $dictionary_handle;
            $Filter_Cache{$file}{filter} = $self->get_filter();

            # point the object attribute at the current ruleset
            $self->set(\@filter, $Filter_Cache{$file}{filter});
        }

        # limp along if the file went away, unless this is the first run
        else {
            warn "$file: $!";
            die if !exists $Filter_Cache{$file}{last_read};
        }

        # cache the timestamp for comparison in later calls
        $Filter_Cache{$file}{last_read} = $last_modified;
    }

    # by default, use a hash
    sub init_filter {
        my ($self) = @_;

        $self->get_debug() and warn 'initializing hash';

        return $self->set_filter({});
    }

    # add phrases to the book
    sub add {
        my ($self, $phrase) = @_;
        return @{$self->get_filter()}{ref $phrase ? @$phrase: $phrase} = ();
    }

    # check the book
    sub has {
        my ($self, $phrase) = @_;
        return exists $self->get_filter()->{$phrase};
    }

    # by default, convert to lowercase & remove anything but alphas & spaces
    sub normalize {
        my ($self, $phrase) = @_;
        $phrase =~ s/[^a-z ]//gi;
        return lc $phrase;
    }

    # procedural constructor
    sub build_phrasebook {
        my ($file, $type) = @_;

        my $class = __PACKAGE__;
        if (defined $type) {
            $class .= ucfirst $type;
        }

        return $class->new({file => $file});
    }

    # procedural method to check the book
    sub phrasebook_check {
        my ($book, $phrases) = @_;
        return $book->has($phrases);
    }
}

1;
__END__

=head1 NAME

Data::Passphrase::Phrasebook - dictionaries for passphrase strength checking

=head1 SYNOPSIS

Object-oriented interface:

    use Data::Passphrase::Phrasebook;
    
    my $phrasebook = Data::Passphrase::Phrasebook->new({
        file => '/usr/local/etc/passphrase/phrasebook',
    });
    my $too_common = $phrasebook->has('april showers bring may flowers');
    
    use Data::Passphrase::Phrasebook::Bloom;
    
    $phrasebook = Data::Passphrase::Phrasebook::Bloom->new({
        file => '/usr/local/etc/passphrase/phrasebook',
    });
    $too_common = $phrasebook->has('april showers bring may flowers');

Procedural interface:

    use Data::Passphrase::Phrasebook qw(build_phrasebook phrasebook_check);
    
    my $phrasebook = build_phrasebook;
    my $too_common = phrasebook_check 'april showers bring may flowers';
    
    $phrasebook = build_phrasebook 'bloom';
    $too_common = phrasebook_check 'april showers bring may flowers';

=head1 DESCRIPTION

This module provides a simple interface for using phrase dictionaries
with L<Data::Passphrase|Data::Passphrase>.

=head1 OBJECT-ORIENTED INTERFACE

This module provides a constructor C<new>, which takes a reference to
a hash of initial attribute settings, and accessor methods of the form
get_I<attribute>() and set_I<attribute>().  See L</Attributes>.

The OO interface can be accessed via subclasses.  For example, you'd
call Data::Passphrase::Phrasebook::Bloom->new() to construct a
phrasebook that uses a Bloom filter instead of the default Perl hash.
The inherited methods and attributes are documented here.

=head2 Methods

In addition to the constructor and accessor methods, the following
special methods are available.

=head3 add()

    $self->add($phrase)

Add C<$phrase> to the phrasebook.

=head3 init_filter()

    $self->init_filter()

Initialize the L<filter|/filter> attribute.  May be useful for
subclassing.

=head3 load()

    $self->load()

Load or reload the phrasebook specified by the L<file|/file>
attribute.  Rules are only reloaded if the file has been modified
since the last time it was loaded.

=head3 has()

    $value = $self->has($phrase)

Return TRUE if the phrasebook contains C<$phrase>, FALSE if it
doesn't.

=head3 normalize()

    $self->normalize($phrase)

Normalize the phrase in preparation for comparison.  The default
method converts the phrase to lowercase and removes anything but
letters and spaces.

=head2 Attributes

The following attributes can be accessed via methods of the form
get_I<attribute>() and set_I<attribute>().

=head3 debug

If TRUE, enable debugging to the Apache error log.

=head3 file

The filename of the phrasebook.  Each line represents one phrase.

=head3 filter

The filter mechanism that holds the phrasebook data and determines
whether supplied phrases are members.  The default filter is a Perl
hash.  See also L<Data::Passphrase::Phrasebook::Bloom>.

=head1 PROCEDURAL INTERFACE

Unlike the object-oriented interface, the procedural interface can
create any type of phrasebook, specified as the argument to
L<build_phrasebook()|/build_phrasebook()>.  Then,
L<phrasebook_check()|/phrasebook_check()> is used to determine if a
phrase is contained in the phrasebook.

=head3 build_phrasebook()

    $phrasebook = build_phrasebook $type

Build a phrasebook of type C<$type>.  This subroutine will essentially
construct a new object of type

    "Data::Passphrase::Phrasebook::" . ucfirst $type

and return the phrasebook itself for use with
L<phrasebook_check()|/phrasebook_check()>.

=head3 phrasebook_check()

    $value = phrasebook_check $phrasebook, $phrase

Returns TRUE if C<$phrase> is contained by C<$phrasebook>, FALSE if it
isn't.

=head1 AUTHOR

Andrew J. Korty <ajk@iu.edu>

=head1 SEE ALSO

Data::Passphrase(3), Data::Passphrase::Phrasebook::Bloom(3)
