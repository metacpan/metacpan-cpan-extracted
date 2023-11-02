package CXC::constant::setonce;

# ABSTRACT: Initialize a constant subroutine once.

use v5.10;

use strict;
use warnings;

our $VERSION = '0.01';
sub import {
    my ( undef, @names ) = @_;
    my $target = caller;

    ## no critic ( TestingAndDebugging::ProhibitNoStrict)
    no strict 'refs';
    for my $name ( @names ) {

        my $fqdn = join q{::}, $target, $name;

        *{$fqdn} = sub {
            state $stored = do {
                die( "$fqdn: used before initialization" )
                  unless @_;
                shift;
            };
            @_ && die( "$fqdn: too many arguments" );
            return $stored;
        };
    }
}


1;

#
# This file is part of CXC-constant-setonce
#
# This software is Copyright (c) 2023 by Smithsonian Astrophysical Observatory.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#

__END__

=pod

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory

=head1 NAME

CXC::constant::setonce - Initialize a constant subroutine once.

=head1 VERSION

version 0.01

=head1 SYNOPSIS

   use CXC::constant::setonce 'MYCONST';

   # this will die, as MYCONST hasn't been set:
   say MYCONST;

   # this sets MYCONST's value;
   MYCONST( $value );

   # this will succeed
   say MYCONST;

   # and this will die, as MYCONST has already been set
   MYCONST( $value );

=head1 DESCRIPTION

This module was written for the case where

=over

=item 1

a constant's value cannot be set until run time

=item 2

attempts to use the constant before its value is set should be fatal.

=item 3

attempts to set the constant's value more than once should be fatal

=back

=head1 USAGE

=over

=item 1

Use C<CXC::constant::setonce> as a pragma to declare the constants:

  use CXC::constant::setonce qw( CONST1 CONST 2);

=item 2

Call a constant as a subroutine with an argument to set it:

  CONST1( $value );
  CONST2( $value );

=item 3

Use the constant as you would any other constant:

  if ( CONST1 == 33 ) { ... }

=back

=head1 CAVEATS

=over

=item *

If the constant is used prior to being set, any later
attempt to set the constant will result in an exception, e.g.

  use CXC::constant::setonce 'CONST';
  eval { CONST }; # will die, eval prevents that from propagating
  CONST($value)   # will die

=item *

There's no way to check if the constant has been set before using it.

=back

=head1 SUPPORT

=head2 Bugs

Please report any bugs or feature requests to bug-cxc-constant-setonce@rt.cpan.org  or through the web interface at: L<https://rt.cpan.org/Public/Dist/Display.html?Name=CXC-constant-setonce>

=head2 Source

Source is available at

  https://gitlab.com/djerius/cxc-constant-setonce

and may be cloned from

  https://gitlab.com/djerius/cxc-constant-setonce.git

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<constant|constant>

=item *

L<constant::defer|constant::defer>

=back

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2023 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
