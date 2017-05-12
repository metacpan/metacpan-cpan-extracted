package Alzabo::Debug;

use strict;

BEGIN
{
    my %constants =
        ( SQL => 0,
          TRACE => 0,
          METHODMAKER => 0,
          REVERSE_ENGINEER => 0,
        );

    if ( $ENV{ALZABO_DEBUG} )
    {
        my %debug = map { uc $_ => 1 } split /\|/, $ENV{ALZABO_DEBUG};

        if ( $debug{ALL} )
        {
            @constants{ keys %constants } = (1) x keys %constants;
        }
        else
        {
            foreach ( grep { exists $constants{$_} } keys %debug )
            {
                $constants{$_} = $debug{$_} ? 1 : 0;
            }
        }
    }

    while ( my ($k, $v) = each %constants )
    {
        eval "use constant $k => $v";
        die $@ if $@;
    }
}


1;

__END__

=head1 NAME

Alzabo::Debug - Creates constants used to turn on debugging

=head1 SYNOPSIS

  export ALZABO_DEBUG='SQL|TRACE'

  ... load and run code using Alzabo ...

  export ALZABO_DEBUG=METHODMAKER

  ... load and run code using Alzabo ...

=head1 DESCRIPTION

This module creates constants used by other modules in order to
determine what debugging output should be generated.

The interface is currently experimental.

=head1 USAGE

Currently, the only way to turn on debugging is by setting the
C<ALZABO_DEBUG> environment variable.  This variable can contain
various flags, each separated by a pipe char (|).  Each flag turns on
different types of debugging output.

These flags B<must be set before Alzabo is loaded>, as debugging is
turned on or off through the use of constants.

The current flags are:

=over 4

=item * SQL

Generated SQL and its associated bound variables.

=item * TRACE

A stack trace will be generated any time SQL is generated.

=item * METHODMAKER

The C<Alzabo::MethodMaker> module will generate verbose output
describing the methods it is creating.

=item * REVERSE_ENGINEER

The modules involved in reverse-engineering will generate output
describing what it finds during reverse-engineering.

=item * ALL

Turn on all flags.

=back

For now, all debugging output is sent to C<STDERR>.

=cut
