use 5.010001;
use strict;
use warnings;

package BSON::Regex;
# ABSTRACT: BSON type wrapper for regular expressions

use version;
our $VERSION = 'v1.12.2';

use Carp ();
use Tie::IxHash;

use Moo;

#pod =attr pattern
#pod
#pod A B<string> containing a PCRE regular expression pattern (not a C<qr> object
#pod and without slashes).  Default is the empty string.
#pod
#pod =cut

#pod =attr flags
#pod
#pod A string with regular expression flags.  Flags will be sorted and
#pod duplicates will be removed during object construction.  Supported flags
#pod include C<imxlsu>.  Invalid flags will cause an exception.
#pod Default is the empty string.
#pod
#pod =cut

has [qw/pattern flags/] => (
    is => 'ro'
);

use namespace::clean -except => 'meta';

my %ALLOWED_FLAGS = map { $_ => 1 } qw/i m x l s u/;

sub BUILD {
    my $self = shift;

    $self->{pattern} = '' unless defined($self->{pattern});
    $self->{flags} = '' unless defined($self->{flags});

    if ( length $self->{flags} ) {
        my %seen;
        my @flags = grep { !$seen{$_}++ } split '', $self->{flags};
        foreach my $f (@flags) {
            Carp::croak("Regex flag $f is not supported")
              if not exists $ALLOWED_FLAGS{$f};
        }

        # sort flags
        $self->{flags} = join '', sort @flags;
    }

}

#pod =method try_compile
#pod
#pod     my $qr = $regexp->try_compile;
#pod
#pod Tries to compile the C<pattern> and C<flags> into a reference to a regular
#pod expression.  If the pattern or flags can't be compiled, a
#pod exception will be thrown.
#pod
#pod B<SECURITY NOTE>: Executing a regular expression can evaluate arbitrary
#pod code if the L<re> 'eval' pragma is in force.  You are strongly advised
#pod to read L<re> and never to use untrusted input with C<try_compile>.
#pod
#pod =cut

sub try_compile {
    my ($self) = @_;
    my ( $p, $f ) = @{$self}{qw/pattern flags/};
    my $re = length($f) ? eval { qr/(?$f:$p)/ } : eval { qr/$p/ };
    Carp::croak("error compiling regex 'qr/$p/$f': $@")
      if $@;
    return $re;
}

#pod =method TO_JSON
#pod
#pod If the C<BSON_EXTJSON> option is true, returns a hashref compatible with
#pod MongoDB's L<extended JSON|https://github.com/mongodb/specifications/blob/master/source/extended-json.rst>
#pod format, which represents it as a document as follows:
#pod
#pod     {"$regularExpression" : { pattern: "<pattern>", "options" : "<flags>"} }
#pod
#pod If the C<BSON_EXTJSON> option is false, an error is thrown, as this value
#pod can't otherwise be represented in JSON.
#pod
#pod =cut

sub TO_JSON {
    if ( $ENV{BSON_EXTJSON} ) {
        my %data;
        tie( %data, 'Tie::IxHash' );
        $data{pattern} = $_[0]->{pattern};
        $data{options} = $_[0]->{flags};
        return {
            '$regularExpression' => \%data,
        };
    }

    Carp::croak( "The value '$_[0]' is illegal in JSON" );
}


1;

=pod

=encoding UTF-8

=head1 NAME

BSON::Regex - BSON type wrapper for regular expressions

=head1 VERSION

version v1.12.2

=head1 SYNOPSIS

    use BSON::Types ':all';

    $regex = bson_regex( $pattern );
    $regex = bson_regex( $pattern, $flags );

=head1 DESCRIPTION

This module provides a BSON type wrapper for a PCRE regular expression and
optional flags.

=head1 ATTRIBUTES

=head2 pattern

A B<string> containing a PCRE regular expression pattern (not a C<qr> object
and without slashes).  Default is the empty string.

=head2 flags

A string with regular expression flags.  Flags will be sorted and
duplicates will be removed during object construction.  Supported flags
include C<imxlsu>.  Invalid flags will cause an exception.
Default is the empty string.

=head1 METHODS

=head2 try_compile

    my $qr = $regexp->try_compile;

Tries to compile the C<pattern> and C<flags> into a reference to a regular
expression.  If the pattern or flags can't be compiled, a
exception will be thrown.

B<SECURITY NOTE>: Executing a regular expression can evaluate arbitrary
code if the L<re> 'eval' pragma is in force.  You are strongly advised
to read L<re> and never to use untrusted input with C<try_compile>.

=head2 TO_JSON

If the C<BSON_EXTJSON> option is true, returns a hashref compatible with
MongoDB's L<extended JSON|https://github.com/mongodb/specifications/blob/master/source/extended-json.rst>
format, which represents it as a document as follows:

    {"$regularExpression" : { pattern: "<pattern>", "options" : "<flags>"} }

If the C<BSON_EXTJSON> option is false, an error is thrown, as this value
can't otherwise be represented in JSON.

=for Pod::Coverage BUILD

=head1 AUTHORS

=over 4

=item *

David Golden <david@mongodb.com>

=item *

Stefan G. <minimalist@lavabit.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Stefan G. and MongoDB, Inc.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut

__END__


# vim: set ts=4 sts=4 sw=4 et tw=75:
