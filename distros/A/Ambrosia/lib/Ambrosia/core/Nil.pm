package Ambrosia::core::Nil;
use strict;
use warnings;

use overload
    '%{}' => sub { {} },
    '@{}' => sub { [] },
    '${}' => sub { my $e=undef; \$e; },
    '&{}' => \&sub_nil,
    '*{}' => sub { shift },
    'bool'=> sub {0},
    '""'  => sub {''},
    '0+'  => sub {0},
    'fallback' => 1
    ;

our $VERSION = 0.010;

our $AUTOLOAD;

{
    my $SINGLETON;

    sub new
    {
        my $proto = shift;
        return $SINGLETON ||= bless [], ref $proto || $proto;
    }
}

sub sub_nil
{
    my $obj = shift;
    sub { $obj };
}

sub TO_JSON
{
    return {};
}

sub AUTOLOAD
{
    unless ( defined wantarray ) # don't bother doing more
    {
        goto \&sub_nil;
    }
    elsif ( wantarray )
    {
        return ();
    }
    return $_[0];
}

1;

__END__

=head1 NAME

Ambrosia::core::Nil - implement pattern NullObject.

=head1 VERSION

version 0.010

=head1 SYNOPSIS

    use Ambrosia::core::Nil;

    $obj = new Ambrosia::core::Nil(@arg);

    $obj->foo(); #It's work and not invoke exeption.
    $obj->()->()->foo(); #And it's work too.
    @a = $obj->foo(); #return empty array
    $b = $obj->foo(); #return object of Ambrosia::core::Nil
    #with string concatenation $obj return empty string
    $s = "foo" . $obj; #$s eq 'foo'
    $i = 10 + $obj; #$i == 10
    #%$obj is empty hash
    #@$obj is empty array
    unless ( $obj )
    {
        print "The object of type Ambrosia::core::Nil allthase is false.\n";
    }

=head1 DESCRIPTION

C<Ambrosia::core::Nil> implement pattern NullObject.

Has only the constructor B<new>.

You can call any methods, and it will not lead to an error.

They will return reference on object of type <Ambrosia::core::Nil>
in scalar context and will return empty array in list context.

=head1 CONSTRUCTOR

=head2 new

C<new> Constructor. Instances the object of type L<Ambrosia::core::Nil>.

=head1 THREADS

Not tested.

=head1 BUGS

Please report bugs relevant to C<Ambrosia> to <knm[at]cpan.org>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010-2012 Nickolay Kuritsyn. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Nikolay Kuritsyn (knm[at]cpan.org)

=cut
