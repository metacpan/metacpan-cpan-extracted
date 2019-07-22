package Astro::App::Satpass2::Locale;

use 5.008;

use strict;
use warnings;

use Astro::App::Satpass2::Utils qw{
    expand_tilde instance
    ARRAY_REF CODE_REF HASH_REF
    @CARP_NOT
};
use Exporter qw{ import };
use I18N::LangTags ();
use I18N::LangTags::Detect ();

our $VERSION = '0.040';

our @EXPORT_OK = qw{ __localize __message __preferred };

my @lang;
my $locale;

{

    my %deref = (
	ARRAY_REF()	=> sub {
	    my ( $data, $inx ) = @_;
	    defined $inx
		and exists $data->[$inx]
		and return $data->[$inx];
	    return;
	},
	CODE_REF()	=> sub {
	    my ( $code, $key, $arg ) = @_;
	    my $rslt = $code->( $key, $arg );
	    return $rslt;
	},
	HASH_REF()	=> sub {
	    my ( $data, $key ) = @_;
	    defined $key
		and exists $data->{$key}
		and return $data->{$key};
	    return;
	},
	''		=> sub {
	    return;
	},
    );

    sub __localize {

# Keys used:
# {argument} = argument for code reference
# {default} = the default value
# {text} = the text to localize, as scalar or array ref. REQUIRED.
# {locale} = fallback locales, as hash ref or ref to array of hash refs.

	my %arg = @_;
	unless ( $arg{text} ) {
	    require Carp;
	    Carp::confess( q<Argument 'text' is required> );
	}
	ref $arg{text}
	    or $arg{text} = [ $arg{text} ];
	$arg{locale} ||= [];
	HASH_REF eq ref $arg{locale}
	    and $arg{locale} = [ $arg{locale} ];
	$locale ||= _load();

	my @rslt;
	foreach my $lc ( @lang ) {
	    SOURCE_LOOP:
	    foreach my $source ( @{ $locale }, @{ $arg{locale} } ) {
		unless ( HASH_REF eq ref $source ) {
		    require Carp;
		    Carp::confess( "\$source is '$source'" );
		}
		my $data = $source->{$lc}
		    or next;
		foreach my $key ( @{ $arg{text} } ) {
		    my $code = $deref{ ref $data }
			or do {
			require Carp;
			Carp::confess(
			    'Programming error - Locale systen can ',
			    'not handle ', ref $data, ' as a container'
			);
		    };
		    ( $data ) = $code->( $data, $key, $arg{argument} )
			or next SOURCE_LOOP;
		}
		wantarray
		    or return $data;
		push @rslt, $data;
	    }
	}
	wantarray
	    or return $arg{default};
	return ( @rslt, $arg{default} );

    }

}

=begin comment

{
    my %stringify_ref = map { $_ => 1 } qw{ Template::Exception };

    sub __message {
	# My OpenBSD 5.5 system seems not to stringify the arguments in
	# the normal course of events, though my Mac OS 10.9 system
	# does. The OpenBSD system gives instead a stringified hash
	# reference (i.e. "HASH{0x....}").
	my @raw_arg = @_;
	my ( $msg, @arg ) =
	    map { $stringify_ref{ ref $_ } ? '' . $_ : $_ } @raw_arg;
	my $lcl = __localize(
	    text	=> [ '+message', $msg ],
	    default	=> $msg,
	);

	CODE_REF eq ref $lcl
	    and return $lcl->( $msg, @arg );

	$lcl =~ m/ \[ % /smx
	    or return join ' ', $lcl, @arg;

	grep { instance( $_, 'Template::Exception' ) } @raw_arg
	    and return join ' ', $lcl, @arg;

	my $tt = Template->new();

	my $output;
	$tt->process( \$lcl, {
		arg	=> \@arg,
	    }, \$output );

	return $output;
    }
}

=end comment

=cut

sub __message {
    my ( $msg, @arg ) = @_;

    instance( $msg, 'Template::Exception' )
	and return join ' ', $msg->as_string(), @arg;

    my $lcl = __localize(
	text	=> [ '+message', $msg ],
	default	=> $msg,
    );

    CODE_REF eq ref $lcl
	and return $lcl->( $msg, @arg );

    $lcl =~ m/ \[ % /smx
	or return join ' ', $lcl, @arg;

    my $tt = Template->new();

    my $output;
    $tt->process( \$lcl, {
	    arg	=> \@arg,
	}, \$output );

    return $output;
}

sub __preferred {
    $locale ||= _load();
    return wantarray ? @lang : $lang[0];
}

sub _load {

    # Pick up the languages from the environment
    @lang = I18N::LangTags::implicate_supers(
	I18N::LangTags::Detect::detect() );

    # Normalize the language names.
    foreach ( @lang ) {
	s/ ( [^_-]+ ) [_-] (.* ) /\L$1_\U$2/smx
	    or $_ = lc $_;
	'c' eq $_
	    and $_ = uc $_;
    }

    # Append the default locale name.
    grep { 'C' eq $_ } @lang
	or push @lang, 'C';

    # Accumulator for locale data.
    my @locales;

    # Put all the user's data in a hash.
    push @locales, {};
    foreach my $lc ( @lang ) {
	eval {	## no critic (ErrorHandling::RequireCheckingReturnValueOfEval)
	    defined( my $path = expand_tilde( "~~/locale/$lc.pm" ) )
		or return;
	    my $data;
	    $data = do $path
		and HASH_REF eq ref $data
		and $locales[-1]{$lc} = $data;
	};
    }

    # Put the system-wide data in a hash.
    push @locales, {};
    foreach my $lc ( @lang ) {
	my $mod_name = __PACKAGE__ . "::$lc";
	my $data;
	$data = eval "require $mod_name"
	    and HASH_REF eq ref $data
	    and $locales[-1]{$lc} = $data;
    }

    # Return a reference to the names of locales.
    return \@locales;
}

1;

__END__

=head1 NAME

Astro::App::Satpass2::Locale - Handle locale-dependant data.

=head1 SYNOPSIS

 use Astro::App::Satpass2::Locale qw{ __localize };
 
 # The best localization
 say scalar __localize(
     text    => [ 'foo', 'bar' ],
     default => 'default text',
 );
 
 # All localizations, in decreasing order of goodness
 for ( __localize(
     text    => [ 'foo', 'bar' ],
     default => 'default text',
 ) ) {
     say;
 }

=head1 DESCRIPTION

This Perl module implements the locale system for
L<Astro::App::Satpass2|Astro::App::Satpass2>.

The locale data can be thought of as a two-level hash, with the first
level corresponding to the section of a Microsoft-style configuration
file and the second level to the items in the section.

The locale data are stored in C<.pm> files, which return the required
hash when they are loaded. These are named after the locale, in the form
F<lc_CC.pm> or F<lc.pm>, where the C<lc> is the language code (lower
case) and the C<CC> is a country code (upper case).

The files are considered in the following order:

=over

=item The user's F<lc_CC.pm>

=item The global F<lc_CC.pm>

=item The user's F<lc.pm>

=item The global F<lc.pm>

=item The user's F<C.pm>

=item The global F<C.pm>.

=back

The global files are installed as Perl modules, named
C<Astro::App::Satpass2::Locale::whatever>, and are loaded via
C<require()>. The user's files are stored
in the F<locale/> directory of the user's configuration, and are loaded
via C<do()>.

=head1 SUBROUTINES

This class supports the following exportable public subroutines:

=head2 __localize
 
 # The best localization
 say scalar __localize(
     text    => [ 'foo', 'bar' ],
     default => 'default text',
 );
 
 # All localizations, in decreasing order of goodness
 for ( __localize(
     text    => [ 'foo', 'bar' ],
     default => 'default text',
 ) ) {
     say;
 }

This subroutine is the interface used to localize values.

The arguments are name/value pairs, with the following names being the
only ones supported.

=over

=item text

This argument is required, and passes the text to be localized. This can
be either a scalar, or a reference to an array of keys (or indices) used
to traverse the locale data structure.

=item default

This argument specifies the default value to be returned if no
localization is available. If it is not specified, C<undef> is returned
if no localization is available.

=item locale

This argument specifies either a hash reference that is consulted for
locale information if all other available locales provide no
localization, or a reference to an array of such hashes. The default is
C<[]>.

=item argument

This argument specifies the value of the second argument passed to a
code reference which is being used for localization. See
L<Astro::App::Satpass2::Locale::C|Astro::App::Satpass2::Locale::C> for
an example of how this can be used.

=back

All other keys are unsupported in the sense that the author makes no
representation what will happen if you specify them, and makes no
commitment that whatever you observe to happen will not change without
notice.

If this subroutine is called in scalar context, the best available
localization is returned. If it is called in list context, all available
localizations will be returned, with the best first and the worst (which
will be the default) last.

To extend the above example, assuming neither the system-wide or
locale-specific locale information defines the keys C<{fu}{bar}>,

 say scalar __localize(
     text    => [ foo => 'bar' ],
     default => 'Greeble',
     locale  => {
         C => {
	     foo => {
	         bar => 'Gronk!',
	     },
         },
         fr => {
	     foo => {
	         bar => 'Gronkez!',
	     },
         },
     },
 );

will print C<'Gronkez!'> in a French locale, and C<'Gronk!'> in any
other locale (since the C<'C'> locale is always consulted). If
C<'Greeble'> is printed, it indicates that the locale system is buggy.

=head2 __message

 say __message( 'Fee fi foe foo!' ); # Fee fi foe foo
 say __message( 'A', 'B', 'C' );     # A B C
 say __message( 'Hello [% arg.0 %]!', 'sailor' );
                                     # Hello sailor!

This subroutine is a wrapper for C<__localize()> designed to make
message localization easier.

The first argument is localized by looking it up under the
C<{'+message'}> key in the localization data. If no localization is
found, the first argument is its own localization. In other words, if
the first argument is C<$message>, its localization is
C<__localize( '+message', $message, $message )>.

If the localization contains C<Template-Toolkit> interpolations
(specifically, C<'[%'>) it and the arguments are fed to that system,
with the arguments being available to the template as variable C<arg>.
The result is returned.

If the localization of the first argument does not contain any
C<Template-Toolkit> interpolations, it is simply joined to the
arguments, with single space characters in between, and the result of
the join is returned.

=head2 __preferred

 say __preferred()

This subroutine returns the user's preferred locale in scalar mode, or
all acceptable locales in descending order of preference in list mode.

=head1 SEE ALSO

L<Astro::App::Satpass2::FormatValue|Astro::App::Satpass2::FormatValue>

=head1 SUPPORT

Support is by the author. Please file bug reports at
L<http://rt.cpan.org>, or in electronic mail to the author.

=head1 AUTHOR

Thomas R. Wyant, III F<wyant at cpan dot org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014-2019 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :
