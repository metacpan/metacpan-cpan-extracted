package Config::Pod;

# $Id: Pod.pm,v 1.1 2001/09/24 20:18:44 jgsmith Exp $

use strict;
use Carp;

our $VERSION = 0.01;

=head1 NAME

Config::Pod - Configuration files in POD format

=head1 SYNOPSIS

 use Config::Pod;

 my $cfg = new Config::POD;

 $cfg -> filename($filename) or $cfg -> text($podtext);

 $cfg -> exists( @path )
 $cfg -> val( @path )

=head1 DESCRIPTION

Config::Pod allows configuration files to be written in POD.  Any 
text may be included at any location without affecting the 
configuration since Config::Pod only pays attention to lines 
beginning with `='.

Headings must be properly nested (head1 followed by head3 is not 
allowed, but head3 followed by head2 is allowed).

The module searches for lines beginning with =head(\d+) and =item.
Only items are leaf nodes and are stored in an array 
under the appropriate heading.

=head1 METHODS

=item exists

Given a list of keys, will return true if the list represents a 
(possibly empty) collection of leaf nodes (C<=item>s).  Note that 
intermediate headings will return false.

=item filename

If no arguments are present, returns the filename of the 
configuration source.  If an argument is given, it tries to read
the file and parse the contents.

=item keys

Given a list of keys, will return an array (possibly empty) of 
keys which reside under the list.

=item text

Either an array or an array reference may be passed.  The 
contents will be parsed as a POD file.

=item val

Given a list of keys, will return an array reference (possibly 
empty) of items.

=head1 EXAMPLE

The following is an example POD file.

 =head1 Section1

 =head2 Section2

 =over 4

 =item Item1

 =item Item2

 =back 4

 =head2 Section3

 =head3 SectionA

 =over 4

 =item ItemA

 =item ItemB

 =back 4

 =head2 Section4

 =cut

The following values then are available:

 $cfg -> val( qw(section1 section2) ) == 
    [ 'Item1', 'Item2' ];
 $cfg -> val( qw(section1 section3 sectiona) ) ==
    [ 'ItemA', 'ItemB' ];
 $cfg -> keys( qw(section1) ) ==
    ( qw(section2 section3 section4) );

and

 $cfg -> exists( qw(section1 section4) );

should return true even though it has no values.

On the other hand,

 $cfg -> exists( qw(section1 section3) );

should return false since there is yet another heading under 
Section3.

=head1 AUTHOR

James Smith <jgsmith@jamesmith.com>

=head1 COPYRIGHT

Copyright (C) 2001 Texas A&M University.  All Rights Reserved.

This module is free software; you can redistribute it and/or 
modify it under the same terms as Perl itself.

=cut


my $parse_file = sub {
    my @lines = grep { m{^=[^=]} } (@_ == 1 ? @$_[0] : @_);
    chomp @lines;
    my(@head, @items);
    my $conf = { };
    my $set_deep = sub {
        my($hash, $val, @path) = @_;

        return unless @path;

        return unless ref $hash eq 'HASH';

        my $p = $hash;
        my $f;
        $f = pop @path while @path && !$f;
        while($p && @path) {
            my $h = shift @path;
            $p -> {$h} = { } if(ref $p->{$h} ne 'HASH');
            $p = $p -> {$h};
        }
        $p -> {$f} = $val;
    };

    while(@lines) {
        my $line = shift @lines;
        my($key, $val) = split(/\s+/, $line, 2);
        if($key =~ m{^=head(\d+)}) {
            &$set_deep($conf, [ @items ], @head);
            @items = ( );
            croak "Incorrectly nested =head$1 (" . join(", ", @head) . ")"  if $1-1 > @head;
            $#head = $1-1;
            $head[-1] = lc $val;
        } elsif($key =~ m{^=item}) {
            push @items, $val;
        }
    }
    &$set_deep($conf, [ @items ], @head);

    return $conf;
};

sub filename {
    my($self) = shift;

    if(@_) {
        my($fn) = @_;

        my $fh;
        open $fh, "<", $fn or croak "Unable to open $fn: $!";
        $self -> {config} = &$parse_file(<$fh>);
        close $fh;
        $self -> {file} = $fn;
    } else {
        return $self -> {file};
    }
}

sub text {
    my($self) = shift;

    $self -> {config} = &$parse_file(@_);
}

sub exists {
    my($self) = shift;

    return unless @_;
    return unless $self -> {config};
    my $f;
    my $p = $self -> {config};
    $f = pop @_ while @_ && !$f;
    $p = $p -> {shift @_} while $p && @_;
    return ref $p eq 'HASH' && exists $p -> {$f} && ref $p -> {$f} eq 'ARRAY';
}

sub keys {
    my($self) = shift;

    return unless $self -> {config};
    my $p = $self -> {config};
    $p = $p -> {shift @_} while $p && @_;
    return unless ref $p eq 'HASH';
    return keys %$p;
}

sub val {
    my($self) = shift;

    return unless @_;
    return unless $self -> {config};
    my $f;
    my $p = $self -> {config};
    $f = pop @_ while @_ && !$f;
    my $l;
    $p = $p -> {shift @_} while $p && @_;
    return $p -> {$f} if ref $p eq 'HASH' && exists $p -> {$f} && ref $p -> {$f} eq 'ARRAY';
}

sub new { bless { }, ref $_[0] || $_[0]; }

1;
