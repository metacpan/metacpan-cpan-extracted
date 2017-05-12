# mamgal - a program for creating static image galleries
# Copyright 2007-2009 Marcin Owsiany <marcin@owsiany.pl>
# See the README file for license information
# The wrapper-for-everything module
package App::MaMGal;
use strict;
use warnings;
use base 'App::MaMGal::Base';
# Remeber to change po/mamgal.pot as well
our $VERSION = '1.6';
our $AUTOLOAD;
use Carp;
use FileHandle;
use Image::EXIF::DateTime::Parser;
use Locale::gettext;

use App::MaMGal::CommandChecker;
use App::MaMGal::EntryFactory;
use App::MaMGal::Formatter;
use App::MaMGal::ImageInfoFactory;
use App::MaMGal::LocaleEnv;
use App::MaMGal::Maker;
use App::MaMGal::MplayerWrapper;

sub init
{
	my $self = shift;

	my $logger = App::MaMGal::Logger->new(FileHandle->new_from_fd('STDERR', 'w'));
	my $locale_env;
	if (@_) {
		$locale_env = App::MaMGal::LocaleEnv->new($logger);
		$locale_env->set_locale($_[0]);
		textdomain('mamgal');
	} else {
		$locale_env = App::MaMGal::LocaleEnv->new($logger);
	}
	my $formatter = App::MaMGal::Formatter->new($locale_env);
	my $command_checker = App::MaMGal::CommandChecker->new;
	my $mplayer_wrapper = App::MaMGal::MplayerWrapper->new($command_checker);
	my $datetime_parser = Image::EXIF::DateTime::Parser->new;
	my $image_info_factory = App::MaMGal::ImageInfoFactory->new($datetime_parser, $logger);
	my $entry_factory = App::MaMGal::EntryFactory->new($formatter, $mplayer_wrapper, $image_info_factory, $logger);
	my $maker = App::MaMGal::Maker->new($entry_factory);

	$self->{maker} = $maker;
	$self->{logger} = $logger;

}

sub DESTROY {} # avoid using AUTOLOAD

sub AUTOLOAD
{
	my $self = shift;
	my $method = $AUTOLOAD;
	$method =~ s/.*://;
	croak "Unknown method $method" unless $method =~ /^make_(without_)?roots$/;
	eval {
		$self->{maker}->$method(@_);
	};
	my $e;
	if ($e = Exception::Class->caught('App::MaMGal::SystemException')) {
		$self->{logger}->log_exception($e);
	} elsif ($e = Exception::Class->caught) {
		ref $e ? $e->rethrow : die $e;
	}
	1;
}

1;

