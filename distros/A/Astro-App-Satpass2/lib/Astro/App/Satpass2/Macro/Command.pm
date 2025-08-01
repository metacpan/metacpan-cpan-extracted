package Astro::App::Satpass2::Macro::Command;

use 5.008;

use strict;
use warnings;

use parent qw{ Astro::App::Satpass2::Macro };

use Astro::App::Satpass2::Utils qw{ quoter ARRAY_REF @CARP_NOT };

our $VERSION = '0.057';

sub execute {
    my ( $self, $name ) = @_;
    $self->implements( $name )
	or $self->weep( "'$name' not implemented by this object" );
    my $satpass2 = $self->parent();
    my $output;
    foreach my $cmd ( @{ $self->{def} } ) {
	eval {
	    if ( defined( my $buffer = $satpass2->execute( $cmd ) ) ) {
		$output .= $buffer;
	    }
	    1;
	} or do {
	    $satpass2->__wail( $@ );
	}
    }
    return $output;
}

sub completion {
    my ( $self, $text ) = @_;
    $self->{completion}
	or return;
    defined $text
	or $text = '';
    my @rslt = sort( grep { ! index $_, $text } @{ $self->{completion} } )
	or return;
    return \@rslt;
}

sub def {
    my ( $self ) = @_;
    my @def = @{ $self->{def} };
    return wantarray ? @def : \@def;
}

sub init {
    my ( $self ) = @_;
    $self->SUPER::init();
    ARRAY_REF eq ref $self->{def}
	or $self->wail( q{Attribute 'def' must be an array reference} );
    $self->{implements} = { map { $_ => 1 } $self->name() };

    $self->{completion}
	and @{ $self->{completion} } = map { split qr< \s+ >smx }
	    @{ $self->{completion} };

    return;
}

# Rewrite level1 macro definitions to level 2 commands. Note that this
# is idempotent.

sub __level1_rewrite {	# TODO get rid of this when level1 support goes away
    my ( $self ) = @_;

    delete $self->{level1}
	and $self->{def} = $self->parent()->__rewrite_level1_macro_def(
	$self->name(), $self->{def} );

    return;
}

1;

__END__

=head1 NAME

Astro::App::Satpass2::Macro::Command - Define a macro which consists of an array of commands

=head1 SYNOPSIS

No user-serviceable parts inside.

=head1 DESCRIPTION

This class is private to the Astro-App-Satpass2 distribution.
Documentation is for the benefit of the author only.

=head1 METHODS

This class provides the following methods in addition to those if its
superclass:

=head2 completion

 my $completion = $self->completion( $text );

This method returns a reference to an array containing all completions
defined by the C<'completion'> argument to C<new()> that match C<$text>.
If there are none, or if the C<'completion'> argument was not specified,
nothing is returned.

=head2 init

This method overrides the superclass method of the same name. In
addition to the functionality of that method, The C<def> attribute is
checked, and the C<implements> attribute populated.

=head1 ATTRIBUTES

This class adds the following attributes to the superclass:

=head2 def

This attribute is a reference to an array that contains the commands to
be executed when the macro is called. Substitution is done on these as
required.

The same-named method can be used to access this. The method returns an
array in list context, or an array reference in scalar context. Either
way the return is a copy of the definition; you can not access (and
therefore modify) the commands issued by the macro using the data
returned by this method.

=head1 SEE ALSO

The superclass,
L<Astro::App::Satpass2::Macro|Astro::App::Satpass2::Macro>.

=head1 SUPPORT

Support is by the author. Please file bug reports at
L<https://rt.cpan.org/Public/Dist/Display.html?Name=Astro-App-Satpass2>,
L<https://github.com/trwyant/perl-Astro-App-Satpass2/issues>, or in
electronic mail to the author.

=head1 AUTHOR

Thomas R. Wyant, III F<wyant at cpan dot org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013-2025 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :
