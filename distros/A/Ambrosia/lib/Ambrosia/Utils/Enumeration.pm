package Ambrosia::Utils::Enumeration;
use strict;
no strict 'refs';
use warnings;
no warnings 'redefine';

use Ambrosia::Assert;

our $VERSION = 0.010;

sub import
{
    my $proto = shift;

    my $style = shift or return; #property or flag
    my $field_name = shift;
    my %states_name = @_;

    assert {$proto eq __PACKAGE__} "'$proto' cannot be inherited from sealed class '" . __PACKAGE__ . '\'.';
    #throw Ambrosia::error::Exception("'$proto' cannot be inherited from sealed class '" . __PACKAGE__ . '\'.') if $proto ne __PACKAGE__;

    my $INSTANCE_CLASS = caller(0);

    if ( $style eq 'property' )
    {
        foreach my $f ( keys %states_name )
        {
            *{"${INSTANCE_CLASS}::SET_$f"} = sub() {
                    local $::__AMBROSIA_ACCESS_ALLOW = 1;
                    $_[0]->{$field_name} = $states_name{$f};
                    return $_[0];
                };

            *{"${INSTANCE_CLASS}::OFF_$f"} = sub() {
                    local $::__AMBROSIA_ACCESS_ALLOW = 1;
                    $_[0]->{$field_name} = undef;
                    return $_[0];
                };

            *{"${INSTANCE_CLASS}::IS_$f"}  = sub() {
                    local $::__AMBROSIA_ACCESS_ALLOW = 1;
                    defined $_[0]->{$field_name} && $_[0]->{$field_name} == $states_name{$f};
                };
        }
    }
    else
    {
        foreach my $f ( keys %states_name )
        {
            my $val = 2 ** $states_name{$f};
            *{"${INSTANCE_CLASS}::ON_$f"} = sub() {
                    local $::__AMBROSIA_ACCESS_ALLOW = 1;
                    $_[0]->{$field_name} ||= 0;
                    $_[0]->{$field_name} |= $val;
                    return $_[0];
                };

            *{"${INSTANCE_CLASS}::OFF_$f"} = sub() {
                    local $::__AMBROSIA_ACCESS_ALLOW = 1;
                    $_[0]->{$field_name} ||= 0;
                    $_[0]->{$field_name} &= ~($val);
                    return $_[0];
                };

            *{"${INSTANCE_CLASS}::IS_$f"}  = sub() {
                    local $::__AMBROSIA_ACCESS_ALLOW = 1;
                    defined $_[0]->{$field_name} && $_[0]->{$field_name} & $val;
                };
        }
    }
}

1;

__END__

=head1 NAME

Ambrosia::Utils::Enumeration - creates enumerable fields in a class.

=head1 VERSION

version 0.010

=head1 DESCRIPTION

C<Ambrosia::Utils::Container> creates enumerable fields in a class and methods for access to this fields.

=head1 CONSTRUCTOR

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
