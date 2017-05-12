use strict;
use warnings;

package Dancer2::Plugin::Negotiate;

# ABSTRACT: Content negotiation plugin for Dancer2

use Dancer2::Plugin;

use HTTP::Negotiate;

our $VERSION = '0.002';    # VERSION

sub choose_variant {
    my $dsl      = shift;
    my $app      = $dsl->app;
    my $variants = [];
    while ( my ( $variant, $options ) = ( shift, shift ) ) {
        last unless defined $variant and defined $options;
        push @$variants => [
            $variant,             $options->{Quality}, $options->{Type},
            $options->{Encoding}, $options->{Charset}, $options->{Language},
            $options->{Size}
        ];
    }
    HTTP::Negotiate::choose( $variants, $app->request->headers, );
}

sub apply_variant {
    my ( $dsl, %variants ) = @_;
    my $app     = $dsl->app;
    my $variant = scalar choose_variant(@_);
    return unless defined $variant;
    my %options = %{ $variants{$variant} };
    my $R       = $app->response;
    $R->header( 'Content-Type' => $options{Type} ) if defined $options{Type};
    $R->header( 'Content-Encoding' => $options{Encoding} )
      if defined $options{Encoding};
    $R->header( 'Content-Charset' => $options{Charset} )
      if defined $options{Charset};
    $R->header( 'Content-Language' => $options{Language} )
      if defined $options{Language};
    $variant;
}

sub _langmap {
    my $grep = shift || sub { 1 };
    my $langs = plugin_setting->{languages} || {};
    return grep defined, map {
        my $opt = {
            Language => scalar( ref $_ eq 'HASH' ? ( keys %$_ )[0]   : $_ ),
            Quality  => scalar( ref $_ eq 'HASH' ? ( values %$_ )[0] : 1 )
        };
        my $id = lc $opt->{Language};
        $grep->($opt) ? ( $id => $opt ) : undef;
    } @$langs;
}

sub negotiate {
    my ( $dsl, $tplname, @rest ) = @_;
    my $app     = $dsl->app;
    my $engine  = $app->engine('template');
    my @langmap = _langmap(
        sub {
            my $lang = shift->{Language};
            my $view = $engine->view_pathname( $tplname . '.' . $lang );
            defined $view and -e $view ? 1 : 0;
        }
    );
    my $lang = apply_variant( $dsl, 0, {}, @langmap );
    $tplname .= '.' . $lang if $lang;
    if (wantarray) {
        return ( $tplname, @rest );
    }
    else {
        return $tplname;
    }
}

register
  choose_variant => \&choose_variant,
  { is_global => 0 };
register
  apply_variant => \&apply_variant,
  { is_global => 0 };
register
  negotiate => \&negotiate,
  { is_global => 0 };

register_plugin;

1;

__END__

=pod

=head1 NAME

Dancer2::Plugin::Negotiate - Content negotiation plugin for Dancer2

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    use Dancer2::Plugin::Negotiate;
	
	get '...' => sub {
		choose_variant(
			var1 => {
				Quality => 1.000,
				Type => 'text/html',
				Charset => 'iso-8859-1',
				Language => 'en',
				Size => 3000
			},
			var2 => {
				Quality => 0.950,
				Type => 'text/plain',
				Charset => 'us-ascii',
				Language => 'no',
				Size => 400
			},
			var3 => {
				Quality => 0.3,
				Type => 'image/gif',
				Size => 43555
			}
		); # returns 'var1' or 'var2' or 'var3' or undef
	}

=head1 DESCRIPTION

This module is a wrapper for L<HTTP::Negotiate>.

=head1 METHODS

=head2 C<< choose_variant(%variants) >>

C<%options> is a hash like this:

	%variants = (
		$identifier => \%options
	)

The key C<$identifier> is a string that will be returned by C<choose_variant()>.

Valid keywords of hashref C<\%options>:

=over 4

=item Quality

A float point value between I<0.000> and I<1.000>, describing the source quality (defaults to 1)

=item Type

A MIME media type (with no charset attributes, but other attributes like I<version>)

=item Encoding

An encoding like I<gzip> or I<compress>

=item Charset

An encoding like I<utf-8> or I<iso-8859-1>

=item Language

A language tag conforming to RFC 3066

=item Size

Number of bytes used to represent

=back

Returns C<undef> if no variant matched.

See L<HTTP::Negotiate> for more information.

=head2 C<< apply_variant(%options) >>

This method behaves like C<choose_variant> but sets the according response headers if a variant matched.

=head2 C<< negotiate($template_name) >>

This method returns C<$template_name> with a suffixed language tag. The file needs to exist. This method behaves similiary to mod_negotiate of apache httpd.

Language tags must be specified in plugin settings and ordered by priority:

	plugins:
	  Negotiate:
	    languages:
	      - en
	      - de
	      - fr

The result of this method can be propagated to C<template()> in order to render a localized version of the file.

	get '/index' => sub {
		return template negotiate 'index';
	}; # renders index.de.tt or index.en.tt or index.fr.tt or index.tt 

Falls back to C<$template_name> if negotiaten fails.

Hint: additional arguments applies to C<template()>:

	template negotiate index => { foo => 'bar' };
	# is the same as
	template(negotiate('index'), { foo => 'bar' });

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/zurborg/libdancer2-plugin-negotiate-perl/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

David Zurborg <zurborg@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by David Zurborg.

This is free software, licensed under:

  The ISC License

=cut
