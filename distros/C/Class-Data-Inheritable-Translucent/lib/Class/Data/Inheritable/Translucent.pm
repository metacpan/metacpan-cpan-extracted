package Class::Data::Inheritable::Translucent;

use 5.008001;

use strict;
use warnings;

=head1 NAME

Class::Data::Inheritable::Translucent - Inheritable, overridable, translucent class data / object attributes

=cut

our $VERSION = '1.04';

if (eval { require Sub::Name }) {
    Sub::Name->import;
}

=head1 SYNOPSIS

  package Foo;
  use base 'Class::Data::Inheritable::Translucent';

  Foo->mk_translucent("bar");
  Foo->bar("baz");

  $obj = Foo->new;

  print $obj->bar; # prints "baz"

  $obj->bar("whatever");

  print $obj->bar; # prints "whatever"
  print Foo->bar;  # prints "baz"

  $obj->bar(undef);

  print $obj->bar; # prints "baz"

=head1 DESCRIPTION

This module is based on Class::Data::Inheritable, and is largely the same,
except the class data accessors double as translucent object attributes.

Object data, by default, is stored in $obj->{$attribute}.  See the attrs()
method, explained below, on how to change that.

=head1 METHODS

=over

=item B<mk_translucent>

Creates inheritable class data / translucent instance attributes

=cut

sub mk_translucent {
    my ($declaredclass, $attribute, $data) = @_;

    my $accessor = sub {
        my $obj = ref($_[0]) ? $_[0] : undef;
        my $wantclass = ref($_[0]) || $_[0];

        return $wantclass->mk_translucent($attribute)->(@_)
          if @_>1 && !$obj && $wantclass ne $declaredclass;

        if ($obj) {
            my $attrs = $obj->attrs;
            $attrs->{$attribute} = $_[1] if @_ > 1;
            return $attrs->{$attribute} if defined $attrs->{$attribute};
        }
        else {
            $data = $_[1] if @_>1;
        }
        return $data;
    };

    my $name = "${declaredclass}::$attribute";
    my $subnamed = 0;
    unless (defined &{$name}) {
        subname($name, $accessor) if defined &subname;
        $subnamed = 1;
        {
            no strict 'refs';
            *{$name}  = $accessor;
        }
    }
    my $alias = "${declaredclass}::_${attribute}_accessor";
    unless (defined &{$alias}) {
        subname($alias, $accessor) if defined &subname and not $subnamed;
        {
            no strict 'refs';
            *{$alias} = $accessor;
        }
    }
}

=pod

=item B<attrs>

This method is called by the generated accessors and, by default, simply
returns the object that called it, which should be a hash reference for storing
object attributes.  If your objects are not hashrefs, or you wish to store your
object attributes in a different location, eg. $obj->{attrs}, you should
override this method.  Class::Data::Inheritable::Translucent stores object
attributes in $obj->attrs()->{$attribute}.

=cut

sub attrs {
    my $obj = shift;
    return $obj;
}

=pod

=back

=head1 AUTHOR

Steve Hay <F<shay@cpan.org>> is now maintaining
Class::Data::Inheritable::Translucent as of version 1.00

Originally by Ryan McGuigan

Based on Class::Data::Inheritable, originally by Damian Conway

=head1 ACKNOWLEDGEMENTS

Thanks to Damian Conway for L<Class::Data::Inheritable>

=head1 COPYRIGHT & LICENSE

Version 0.01 Copyright 2005 Ryan McGuigan, all rights reserved.
Changes in Version 1.00 onwards Copyright (C) 2009, 2011 Steve Hay

mk_translucent is based on mk_classdata from Class::Data::Inheritable,
Copyright Damian Conway and Michael G Schwern, licensed under the terms of the
Perl Artistic License.

This program is free software; It may be used, redistributed and/or modified
under the terms of the Perl Artistic License (see
L<http://www.perl.com/perl/misc/Artistic.html>)

=head1 BUGS

Please report any bugs or feature requests on the CPAN Request Tracker at
F<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Class-Data-Inheritable-Translucent>.

=head1 SEE ALSO

=over 2

=item *

L<Class::Data::Inheritable>

=item *

L<perltooc> - Tom's OO Tutorial for Class Data in Perl - a pretty nice Class
Data tutorial for Perl

=item *

The source.  It's quite short, and simple enough.

=back

=cut

1; # End of Class::Data::Inheritable::Translucent
