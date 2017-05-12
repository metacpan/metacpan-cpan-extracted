package Data::Walk::Extracted::Types;
our $AUTHORITY = 'cpan:JANDREW';
use version; our $VERSION = version->declare('v0.28.0');
use 5.010;
use utf8;
use strict;
use warnings;
use MooseX::Types::Moose qw( Int );
use MooseX::Types -declare => [qw( PosInt )];

#########1 SubType Library    3#########4#########5#########6#########7#########8#########9

subtype PosInt, as Int,
    where{ $_ >= 0 },
    message{ "$_ is not a positive integer" };

#########1 private methods    3#########4#########5#########6#########7#########8#########9



#########1 Phinish strong     3#########4#########5#########6#########7#########8#########9

1;
# The preceding line will help the module return a true value

#########1 main pod docs      3#########4#########5#########6#########7#########8#########9

__END__

=head1 NAME

Data::Walk::Extracted::Types - A type library for Data::Walk::Extracted

=head1 SYNOPSIS

    package Data::Walk::Extracted::MyRole;
	use Moose::Role;
	use Data::Walk::Extracted::Types qw(
		posInt
	);
    use Log::Shiras::Types qw(
        posInt #See Code for other options
    );

    has 'someattribute' =>(
            isa     => posInt,#Note the lack of quotes
        );

    sub valuetestmethod{
        my ( $self, $value ) = @_;
        return is_posInt( $value );
    }

    no Moose::Role;

    1;

=head1 DESCRIPTION

This is the custom type class that ships with the L<Data::Walk::Extracted
|https://metacpan.org/module/Data::Walk::Extracted> package.  Wherever
possible errors to coersions are passed back to the type so coersion failure
will be explained.

There are only subtypes in this package!  B<WARNING> These types should be
considered in a beta state.  Future type fixing will be done with a set of tests in
the test suit of this package.  (currently none are implemented)

See L<MooseX::Types|https://metacpan.org/module/MooseX::Types> for general re-use
of this module.

=head1 Types

=head2  posInt

=over

B<Definition: >all integers equal to or greater than 0

B<Coercions: >no coersion available

=back

=head1 TODO

=over

B<1.> write a test suit for the types to permanently define behavior!

B<2.> Add L<Log::Shiras|https://metacpan.org/module/Log::Shiras> debugging statements

=back

=head1 SUPPORT

L<github Data-Walk-Extracted/issues|https://github.com/jandrew/Data-Walk-Extracted/issues>

=head1 AUTHOR

=over

Jed Lund

jandrew@cpan.com

=back

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

This software is copyrighted (c) 2013, 2016 by Jed Lund.

=head1 DEPENDENCIES

=over

L<version>

L<utf8>

L<MooseX::Types>

L<MooseX::Types::Moose>

=back

=head1 SEE ALSO

=over

L<MooseX::Types::Perl>

=back

=cut

#########1 Main POD ends      3#########4#########5#########6#########7#########8#########9
