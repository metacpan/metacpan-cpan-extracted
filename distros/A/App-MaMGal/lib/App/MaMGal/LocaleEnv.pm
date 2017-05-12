# mamgal - a program for creating static image galleries
# Copyright 2008 Marcin Owsiany <marcin@owsiany.pl>
# See the README file for license information
# A class encapsulating locale environment settings.
package App::MaMGal::LocaleEnv;
use strict;
use warnings;
use base 'App::MaMGal::Base';
use Carp;
use Locale::gettext;
use POSIX;

sub init
{
	my $self = shift;
	my $logger = shift or croak "Need a logger arg";
	ref $logger and $logger->isa('App::MaMGal::Logger') or croak "Arg is not a App::MaMGal::Logger , but a [$logger]";
	eval {
		require I18N::Langinfo;
		I18N::Langinfo->import(qw(langinfo CODESET));
	};
	if ($@) {
		$logger->log_message("nl_langinfo(CODESET) is not available. ANSI_X3.4-1968 (a.k.a. US-ASCII) will be used as HTML encoding. $@");
		$self->{get_codeset} = sub { "ANSI_X3.4-1968" };
	} else {
		$self->{get_codeset} = sub { langinfo(CODESET()) };
	}
}

sub get_charset
{
	my $self = shift;
	&{$self->{get_codeset}}
}

sub set_locale
{
	my $self = shift;
	my $locale = shift;
	setlocale(LC_ALL, $locale);
}

sub format_time
{
	my $self = shift;
	my $time = shift or return '??:??:??';
	strftime('%X', localtime($time))
}

sub format_date
{
	my $self = shift;
	my $time = shift or return '???';
	strftime('%x', localtime($time))
}

1;
