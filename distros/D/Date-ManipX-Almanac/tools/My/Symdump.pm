package My::Symdump;

use 5.010;

use strict;
use warnings;

# use Carp;
use Devel::Symdump;
use Module::Load ();

our $VERSION = '0.001';

sub dmd_public_interface {
    my $dmd = find_public_methods( 'Date::Manip::Date' );

    # The following have the form of public methods but are not actually
    # part of the Date::Manip::Date public interface.
    delete $dmd->{$_} for qw{ dclone };
    return wantarray ? sort keys %{ $dmd } : $dmd;
}

sub find_public_methods {
    my $module = $_[-1];
    Module::Load::load( $module );
    my %implements = map { _mod_sub( $_ ) }
	$module, _mod_isa( $module );
    return wantarray ? sort keys %implements : \%implements;
}

sub _mod_sub {
    my ( $module ) = @_;
    my $sd = Devel::Symdump->new( $module );
    my $re = qr{ \A $module :: }smx;
    my @rslt;
    foreach my $symbol ( sort $sd->functions ) {
	( my $basic = $symbol ) =~ s/ $re //smx;
	$basic =~ m/ \W /smx
	    and next;
	$basic =~ m/ \A _ /smx	# Private
	    and next;
	$basic =~ m/ [[:lower:]] /smx	# ALL CAPS
	    or next;
	( my $name_space = $symbol ) =~ s/ :: [^:]* \z //smx;
	push @rslt, $basic, $name_space;
    }
    return @rslt;
}

sub _mod_isa {
    my ( $module, $seen ) = @_;
    $seen ||= {};
    my ( $isa ) = grep { m/ ::ISA \z /smx } Devel::Symdump->new( $module )->arrays()
	or return;
    my @isa;
    {
	no strict qw{ refs };
	@isa = @$isa;
    }
    foreach my $parent ( @isa ) {
	$seen->{$parent}++
	    and next;
	_mod_isa( $parent, $seen );
    }
    defined wantarray
	or return;
    return keys %{ $seen };
}

1;

__END__

=head1 NAME

My::Symdump - Rummage around in name spaces.

=head1 SYNOPSIS

 use lib qw{ tools };
 use My::Symdump;
 
 say for My::Symdump->find_public_methods( 'Date::Manip::Date' );

=head1 DESCRIPTION

This module is private to the C<Date-ManipX-Almanac> package.
It is unsupported, and can be changed or revoked at any time without
notice.

This module contains whatever symbol table ad-hocery is needed to
maintain the L<Date::ManipX::Almanac|Date::ManipX::Almanac> package.

=head1 METHODS

This class supports the following methods:

=head2 dmd_public_interface

This is just a wrapper for

 My::Symdump->find_public_methods( 'Date::Manip::Date' )

which tweaks the results to conform to the documented interface. As of
this writing (and Date::Manip::Date 6.85) the tweaks are:

=over

=item * remove 'dclone'

=back

=head2 find_public_methods

 say My::Symdump->find_public_methods( 'Date::Manip::Date' );
 my $hash = My::Symdump->find_public_methods( 'Date::Manip::Date' );

This static method takes a module name as its argument. That module is
loaded, and it and its parents (if any) are scanned for public methods.
These are defined as methods whose name contains at least one lower-case
character and does not begin with an underscore (C<'_'>).

If called in list context, the names are returned, sorted in lexical
order.

If called in scalar context, the return is a reference to a hash of the
names of public methods, with the associated value being the name space
that defines the method.

=head1 SEE ALSO

L<Devel::Symdump|Devel::Symdump>, which does the heavy lifting.

=head1 SUPPORT

This module is unsupported, and can be modified or revoked at any time.

=head1 AUTHOR

Thomas R. Wyant, III F<wyant at cpan dot org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2021 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :
