#!/usr/bin/perl -w
# c.2009 nicholas wehr
# $Id: Simple.pm 244 2009-03-31 03:19:32Z nwehr $

package Catalyst::Plugin::Localize::Simple;
use strict;
use warnings;
use YAML::Syck;

our $VERSION = '1.1';

=head1 NAME

Catalyst::Plugin::Localize::Simple

=head1 SYNOPSIS

=over 4

in MyApp/lib/MyApp.pm

    use Catalyst 'Localize::Simple';

in controller
 
    print $c->localize('de','theking');
 
B<or> harness the power of this module; when you have stored the language preferences in the session

    ...
    $c->session->{lang} = $c->req->param('language');
    ...
    $c->stash->{bio} = $c->socal('theking');
    $c->stash->{template} = $c->socal('welcome.tt2');
    ...
    $c->lang; # the language code

from a template
 
    [% c.socal('theking') %]
  
    <a href="http://www.mysite.com?lang=[% c.lang %]">click here</a>
 
=back

=head1 DESCRIPTION

This module allows you to setup and access language files very simply by defining dictionary
L<YAML> files for configuration.  If you're looking for something a little more robust - check
out L<Catalyst::Plugin::I18N> and family. The dictionary files are accessed via L<YAML::Syck>
to ensure high performance.

This module intentionally avoids caching the data files to allow for "hot-swapping" of
dictionary changes (won't require a Catalyst restart).

=head1 CONFIGURATION

    __PACKAGE__->config(
       	'Localize::Simple' => {
					_sessionkey	=> 'lang',
					en					=> 'root/localize/en.yaml',
					de					=> 'root/localize/de.yaml',
					fr					=> 'root/localize/fr.yaml',
				}	
    );

=over 4

in I<root/localize/en.yaml>...

    ---
    yes: certainly
    no: nope
    welcome.tt2: welcome-en.tt2
    theking: Elvis Aaron Presley was an American singer, actor, and musician.

in I<root/localize/de.yaml>...

    ---
    yes: ja
    no: nein
    welcome.tt2: welcome-de.tt2
    theking: Elvis Aron Presley war ein US-amerikanischer Sänger und Schauspieler  

maybe you should put your language files in a consistent location; like this:

    root/
    |
    `-- localize
        |-- de.yaml
        |-- en.yaml
        |-- es.yaml
        |-- fr.yaml
        |-- it.yaml
        `-- ja.yaml

=back

=head1 METHODS

=over 4

=item setup (internal Catalyst plugin constructor)

note: defines a default language 'en'

=item sessionkey

this is the session variable that is defined in the configuration file

note: defines a default key of 'lang'

=item lang

returns the language code as stored by your application (into $c->session->{$key} or $c->req->param($key))

note: returns the default language 'en' when neither are specified

=item localize (I<lang>, I<term>)

=item loc (I<lang>, I<term>)

this method is the meat and potatoes of this module. it will return the defined I<term> in the dictionary for I<lang>.

if a term is B<not found>, this method will return a string C<_MISSING_TERM_|term>. I<term> is the term you asked for.
this is very handy for tracking down missing terms.

=item localize_from_session (I<term>)

=item socal (I<term>)

this method combines the work of I<lang> and I<localize> into one handy little method call.

why is it called I<socal>? just a plug for my hometown San Diego, California! ;)

=back

=head1 AUTHOR

Nicholas Wehr C<< <nicholas.wehr@bionikchickens.com> >>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut

# WOW! this code is so neat and clean - there's no need to document anything right? self-explanatory? yes?! yes!

sub setup {
    my $self = shift;
    $self->NEXT::setup(@_);

		unless (defined $self->config->{'Localize::Simple'}) {
			$self->log->error(sprintf("error loading configuration for: %s", ref $self));
		}
    $self->mk_classdata($_) for qw(sessionkey defaultlanguage);
		$self->sessionkey( $self->config->{'Localize::Simple'}->{_sessionkey} || 'lang' );
		$self->defaultlanguage( $self->config->{'Localize::Simple'}->{_defaultlanguage} || 'en' );
}

sub lang {
	my $c = shift;
	$c->session->{$c->sessionkey} =	
		defined $c->req->param($c->sessionkey) ? $c->req->param($c->sessionkey) :
		defined $c->session->{$c->sessionkey} ? $c->session->{$c->sessionkey} :
		$c->defaultlanguage;
	return $c->session->{$c->sessionkey};
}

sub localize {
	my $self = shift;
	my ($lang, $key) = @_;

	my $map;
	eval {
		my $file = $self->config->{'Localize::Simple'}->{$lang};
		-e $file or die "file does not exist\n";
		$map = LoadFile($file) or die "error loading with YAML::Syck\n";
	};
	if ($@) {
		$self->log->error("error loading terms from file: $self->config->{'Localize::Simple'}->{$lang}; $@");
		return "_MISSING_TERM_|$key";
	}

	my $term = $map->{$key}
		or $self->log->error("couldn't find [$lang] term for [$key] in file: $self->config->{'Localize::Simple'}->{$lang}");
	return $term || "_MISSING_TERM_|$key";
}
*loc = \&localize;

sub localize_from_session {
	my ($self, $key) = @_;
	if (my $lang = $self->lang) {
		return $self->localize($lang, $key);
	}
	else {
		$self->log->error("couldn't determine [lang] session key in session or query params");
		return "_MISSING_TERM_|$key";
	}
}
*socal = \&localize_from_session;

1;
