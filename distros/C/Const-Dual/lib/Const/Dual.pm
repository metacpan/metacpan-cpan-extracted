package Const::Dual;

use 5.006;
use strict;
use warnings;

use Carp ();
use Scalar::Util ();

our $VERSION = '0.02';

=head1 NAME

Const::Dual - numeric constants that know their names

=cut


=head1 SYNOPSIS

    # create constants
    use Const::Dual (
        TYPE_FOO => 1,
        TYPE_BAR => 2,
        # ... more constants ...
        TYPE_BAZ => 99,
    );

    $type = TYPE_BAR;
    print $type + 0;                               # 2
    print $type == 2 ? "bar" : "not bar";          # bar
    print $type == TYPE_BAR ? "bar" : "not bar";   # bar
    print "type = $type";                          # type = TYPE_BAR

    # create constants and store them in %TYPES
    use Const::Dual \%TYPES => (
        TYPE_FOO => 1,
        TYPE_BAR => 2,
        # ... more constants ...
        TYPE_BAZ => 99,
    );
    @EXPORT_OK = keys %TYPES;
    @EXPORT_TAGS = (types => [ keys %TYPES ]);

    # get dual value from non-dual value
    my $type = $ARGV[0] // 99;
    my %TYPES_REVERSE; @TYPES_REVERSE{ map { int $_ } values %TYPES } = values %TYPES;
    die "Invalid type $type" unless exists $TYPES_REVERSE{$type};
    $type = $TYPES_REVERSE{$type};
    print int $type;                               # 99
    print "type = $type";                          # type = TYPE_BAZ

    # dual constants are always true!
    use Const::Dual FALSE => 0;
    print int FALSE;                               # 0
    print "FALSE is ", FALSE ? "true" : "false";   # FALSE is true

=cut

BEGIN {
    # forbid utf8 constant names on old perl
    *_DOWNGRADE = $] >= 5.008 && $] < 5.015004 ? sub { 1 } : sub { 0 };
}

# some names are evil choices
my %forbidden = map { $_ => 1 } qw/BEGIN INIT CHECK UNITCHECK END DESTROY AUTOLOAD/, qw/STDIN STDOUT STDERR ARGV ARGVOUT ENV INC SIG/;

sub import {
    my $class = shift;

    my $storehash = ref $_[0] ? shift : undef;
    Carp::croak "Only hashref accepted to store constants" if $storehash && ref $storehash ne 'HASH';
    Carp::croak "Odd number of elements provided" if @_ % 2;

    while (@_) {
        my ($name, $value) = splice @_, 0, 2;
        Carp::croak "Invalid constant name '$name'" if ref $name || $name !~ /^[a-zA-Z_][a-zA-Z0-9_]*$/;
        Carp::croak "Invalid constant name '$name': registered keyword" if $forbidden{$name}; #TODO utf?

        my $value_copy = Scalar::Util::looks_like_number($value) ? Scalar::Util::dualvar($value, $name) : $value;
        $storehash->{$name} = $value_copy if $storehash;

        utf8::encode $name if _DOWNGRADE && utf8::is_utf8 $name;
        $name = caller() . '::' . $name;

        no strict 'refs';
        *{ $name } = sub () { $value_copy };
    }
}

=head1 DESCRIPTION

This module can be helpful when you use a lot of constants and really tired to deal with them. Numeric constants created
with this module are dual (see L<Scalar::Util/dualvar>). They have their given numeric values when are used in numeric
context. When used in string context, such constants are strings with constants' names. This can be useful for debug purposes:
constant's value "knows" constant's name and it can be printed. This behavior does not apply to non-numberic constants,
they are created as usual.

=head1 CAVEATS

Developer should ALWAYS keep in mind that he works with dual values and should force numeric context when necessary.
This is strict rule and it's violation can lead to bugs. Common ways to force numeric context is C<int $value> or C<$value+0>.

Dual constant in bool context is always TRUE, because one of constant's value is it's name and it can not be FALSE.

=head1 SOURCE

The development version is on github at L<https://github.com/bambr/Const-Dual>

=head1 AUTHOR

Sergey Panteleev, E<lt>bambr@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2018 by Sergey Panteleev

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;
