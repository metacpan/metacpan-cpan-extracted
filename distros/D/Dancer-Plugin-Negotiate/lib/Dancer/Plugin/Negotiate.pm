package Dancer::Plugin::Negotiate;

use Modern::Perl;
use Carp 'croak';
use Dancer ':syntax';
use Dancer::Plugin;
use HTTP::Negotiate ();

=head1 NAME

Dancer::Plugin::Negotiate - Content negotiation plugin for Dancer

=head1 VERSION

Version 0.031

=cut

our $VERSION = '0.031';

=head1 SYNOPSIS

    use Dancer::Plugin::Negotiate;

	$variant = choose_variant(
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

=head1 DESCRIPTION

This module is a wrapper for L<HTTP::Negotiate>.

=head1 KEYWORDS

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

See L<HTTP::Negotiate|HTTP::Negotiate> for more information.

=cut

sub choose_variant {
	my $variants = [];
	while (my ($variant, $options) = (shift, shift)) {
		last unless defined $variant and defined $options;
		push @$variants => [
			$variant,
			$options->{Quality},
			$options->{Type},
			$options->{Encoding},
			$options->{Charset},
			$options->{Language},
			$options->{Size}
		];
	}
	return HTTP::Negotiate::choose($variants, Dancer::SharedData->request->headers);
}

=head2 C<< apply_variant(%options) >>

This method behaves like C<choose_variant> but sets the according response headers if a variant matched.

=cut

sub apply_variant {
	local %_ = @_;
	my $variant = scalar choose_variant(@_);
	return undef unless defined $variant;
	my %options = %{$_{$variant}};
	my $R = Dancer::SharedData->response;
	$R->header('Content-Type'     => $options{Type}    ) if defined $options{Type};
	$R->header('Content-Encoding' => $options{Encoding}) if defined $options{Encoding};
	$R->header('Content-Charset'  => $options{Charset} ) if defined $options{Charset};
	$R->header('Content-Language' => $options{Language}) if defined $options{Language};
	return $variant;
}

=head2 C<< negotiate($template_name) >>

This method returns C<$template_name> with a suffixed language tag. The file needs to exist. This method behaves similiary to mod_negotiate of apache httpd's.

Language tags must be specified in plugin settings and ordered by priority:

	plugin:
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

=cut

sub _langmap {
	my $grep = shift || sub { 1 };
	my $langs = plugin_setting->{languages} || {};
	return grep defined, map {
		my $opt = {
			Language => scalar(ref $_ eq 'HASH' ? (keys   %$_)[0] : $_ ),
			Quality  => scalar(ref $_ eq 'HASH' ? (values %$_)[0] : 1  )
		};
		my $id = lc $opt->{Language};
		$grep->($opt) ? ( $id => $opt ) : undef;
	} @$langs;
}

sub negotiate($;) {
	my ($tplname, @rest) = @_;
	my $engine = engine('template');
	my @langmap = _langmap(sub {
		my $lang = shift->{Language};
		my $view = $engine->view($tplname.'.'.$lang);
		defined $view and $engine->view_exists($view) ? 1 : 0
	});
	my $lang = apply_variant(0, {}, @langmap);
	return ($tplname, @rest) unless defined $lang;
	return ($tplname, @rest) unless $lang;
	return ($tplname.'.'.$lang, @rest);
}

register choose_variant => \&choose_variant;
register apply_variant => \&apply_variant;
register negotiate => \&negotiate;

register_plugin;
1;

=head1 AUTHOR

David Zurborg, C<< <zurborg@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests through my project management tool
at L<http://development.david-zurb.org/projects/libdancer-plugin-negotiate-perl/issues/new>.  I
will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dancer::Plugin::Negotiate

You can also look for information at:

=over 4

=item * Redmine: Homepage of this module

L<http://development.david-zurb.org/projects/libdancer-plugin-negotiate-perl>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dancer-Plugin-Negotiate>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Dancer-Plugin-Negotiate>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Dancer-Plugin-Negotiate>

=item * Search CPAN

L<http://search.cpan.org/dist/Dancer-Plugin-Negotiate/>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2014 David Zurborg, all rights reserved.

This program is released under the following license: open-source

=cut

1;
