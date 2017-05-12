package Ambrosia::Assert;
use strict;
use warnings;
use Carp;

use Ambrosia::error::Exceptions;

our $VERSION = 0.010;

our %PROCESS_MAP = ();
our %ASSERT = ();

sub import
{
    my $package = shift;
    return if eval{$package->can('assert')};

    assign(shift) if @_;

    no strict 'refs';
    my $package_instance = caller(0);
    if ( debug_mode($PROCESS_MAP{$$}, @_) )
    {
        *{"${package_instance}::assert"} = sub(&$) { goto &__assert; };
    }
    else
    {
        *{"${package_instance}::assert"} = sub(&$) {};
    }

}

sub __assert(&$)
{
    my $condition = shift;
    if (( ref $condition eq 'CODE' && !$condition->() ) || !$condition)
    {
        carp( 'error: ' . shift);
        exit(42);
    }
}
################################################################################

sub assign
{
    $PROCESS_MAP{$$} = shift;
}

sub debug_mode
{
    my $key = shift or return 0;
    my $mode = shift;

    unless(defined $ASSERT{$key})
    {
        throw Ambrosia::error::Exception::BadParams 'First usage Ambrosia::Assert without initialize.' unless defined $mode;
        $ASSERT{$key} = lc($mode) eq 'debug';
    }
    return $ASSERT{$key};
}

1;

#########
# MUST WRITE IN MAIN
#########
#END
#{
#    if ( $? == 42 )
#    {
#        storage->foreach('cancel');
#        $? = 1;
#    }
#}

__END__

=head1 NAME

Ambrosia::Assert - adds a validation method in your module.

=head1 VERSION

version 0.010

=head1 SYNOPSIS

    #foo.pm 
    use Ambrosia::Assert GLOBAL_KEY => 'debug';

    sub foo
    {
        my @params = @_;
        assert(sub {@params && $params[0] eq 'abc'}, 'invalid params in foo()');
        .......
    }

    #script.pl
    use foo;
    foo::foo();
    END
    {
        $? = 0 if $?==42;
    }

=head1 DESCRIPTION

C<Ambrosia::Assert> adds a validation method in your module.
You can on or off assert for debug.

=head1 USAGE

    use Ambrosia::Assert GLOBAL_KEY => 'debug'; #on validation
    use Ambrosia::Assert GLOBAL_KEY => 'nodebug'; #off validation

GLOBAL_KEY is any keyword, for example application name.

=head1 METHODS

=head2 assert( $subroutine, $message )

    assert(sub {@params && $params[0] eq 'abc'}, 'invalid params in foo()');

If the $subroutine returns false then application execution will be stopped.
In value of variable $? will be 42 and on STDERR will be output the $message.

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
