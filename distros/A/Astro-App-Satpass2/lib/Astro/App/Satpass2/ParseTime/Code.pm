package Astro::App::Satpass2::ParseTime::Code;

use 5.008;

use strict;
use warnings;

use parent qw{ Astro::App::Satpass2::ParseTime };

use Astro::App::Satpass2::Utils qw{ CODE_REF HASH_REF @CARP_NOT };

our $VERSION = '0.040';

use constant DUMMY	=> 'DUMMY';

# __arguments() is normally called as a subroutine, but it needs access
# to this namespace to figure out the options, so we just load this
# module and then call __arguments() as a static method.
require Astro::App::Satpass2;

sub attribute_names {
    my ( $self ) = @_;
    return ( $self->SUPER::attribute_names(), qw{ code } );
}

sub class_name_of_record {
    my ( $self ) = @_;
    my $code = $self->code();
    ref $code
	and $code = DUMMY;
    return $code;
}

sub code {
    my ( $self, @args ) = @_;
    if ( @args ) {
	my ( $val, $name ) = @args;
	if ( my $ref = ref $val ) {
	    if ( CODE_REF eq $ref ) {
		defined $name
		    or $name = $val;
		return $self->_code_storage( $name, $val );
	    }
	} elsif ( $val =~ m/ ( .* ) :: ( .* ) /smx ) {
	    if ( my $code = $1->can( $2 ) ) {
		return $self->_code_storage( $val, $code );
	    }
	} elsif ( my $code = caller->can( $val ) ) {
	    return $self->_code_storage( $val, $code );
	}
	$self->wail(
	    'Code attribute must be a CODE ref or a subroutine name' );
    }
    return $self->_attr()->{code};
}

sub delegate {
    return __PACKAGE__;
}

sub parse_time_absolute {
    my ( $self, $string ) = @_;
    return $self->_call_code( parse => $string );
}

sub tz {
    my ( $self, @args ) = @_;
    @args
	and $self->_call_code( tz	=> $args[0] );
    return $self->SUPER::tz( @args );
}

sub use_perltime {
    my ( $self ) = @_;
    return $self->_call_code( 'use_perltime' );
}

sub _attr {
    my ( $self ) = @_;
    my $pkg = __PACKAGE__;
    return $self->{$pkg} ||= {};
}

sub _call_code {
    my ( $self, @args ) = @_;
    ( undef, @args ) = Astro::App::Satpass2->__arguments( @args );
    my $code = $self->_attr()->{_code}
	or $self->wail( 'No code specified' );
    return $code->( $self, @args );
}

sub _code_storage {
    my ( $self, $name, $code ) = @_;
    my $attr = $self->_attr();
    $attr->{code} = $name;
    $attr->{_code} = $code;
    return $self;
}

1;

__END__

=head1 NAME

Astro::App::Satpass2::ParseTime::Code - Astro::App::Satpass2 wrapper for custom code to parse time

=head1 SYNOPSIS

No user-serviceable parts inside.

=head1 DESCRIPTION

This class wraps code to parse a time string and return the epoch.

=head1 METHODS

This class supports the following public methods over and above those
documented in its superclass
L<Astro::App::Satpass2::ParseTime|Astro::App::Satpass2::ParseTime>.

=head2 code

 my $value = $pt->code();
 $pt->code( 'my_time_parser' );
 $pt->code( 'Some::Package::time_parser' );
 $pt->code( sub { ... } );
 $pt->code( sub { ... }, 'name_of_record' );

This method acts as both accessor and mutator for the C<code> attribute,
which contains the code to do the parsing. Without arguments it is an
accessor, returning the value of the attribute.

If called with arguments, it sets the value of the attribute. You can
pass either the name of the subroutine that implements the parse, or a
reference to it. An unqualified name is resolved in the caller's name
space.

In general the accessor returns what was set. But if you pass a name of
record after the code reference (as in the last example above), that
name of record will be returned as the value of the attribute.

The code reference will be called with the following arguments:

=over

=item the invocant

That is, it will be called as though it was a method of this class.

=item a reference to an options hash

If the code has the C<Verb()> attribute (as it will if it comes from a
code macro), the options will be as parsed by
L<Getopt::Long|Getopt::Long> using the value of the C<Verb()> attribute
as the option specification.

If the code does not have the C<Verb()> attribute, the reference will be
to an empty hash.

=item the name of the action to to perform

Supported values are discussed below. Any other values are unsupported
and reserved by the author.

=item the arguments for the action, if any.

The arguments depend on the action, as follows:

=over

=item parse

The argument is the string to parse. The code C<must> return the epoch,
or call C<wail()> on the invocant to generate an exception.

This is the only action that B<must> be implemented.

=item tz

The argument is the time zone being set. The return value is ignored,
but the code B<must> call C<wail()> to generate an exception if it does
not like the value of the time zone.

If this action has no specific implementation, the code should simply
return.

=item use_perltime

No argument is provided. The code C<must> return a true value if it
makes use of the C<perltime> attribute, and a false value otherwise.

If this action has no specific implementation, the code should simply
return.

=back

=back

The code reference will be called when the time zone is set (to give the
code a chance to reject it), and to request a parse.

In the first case the arguments are C<( $self, tz => $zone )>, where
C<$self> is a reference to this object, and C<$zone> is the prospective
new time zone. When called this way the code would reject the zone by
calling C<< $self->wail( $some_message ) >>. The code accepts the zone
by simply returning.

In the second case the arguments are C<( $self, parse => $string >,
where C<$self> is as before, and C<$string> is the string to be parsed.
If the parse is successful, the code must return the epoch time. If the
parse fails, the code must call C<wail()> as above.

You do B<not> need to specify C<'code'> as an argument to C<new()>,
though you can. But you B<must> have set the code before calling
inherited method
L<parse_time_absolute()|Astro::App::Satpass2::ParseTime/parse_time_absolute>.

=head1 SUPPORT

Support is by the author. Please file bug reports at
L<http://rt.cpan.org>, or in electronic mail to the author.

=head1 AUTHOR

Tom Wyant (F<wyant at cpan dot org>)

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016-2019 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :
