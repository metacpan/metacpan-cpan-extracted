package Apache::Voodoo::View::HTML::Theme;

$VERSION = "3.0200";

use strict;
use warnings;

use Config::General;
use HTML::Template;

sub new {
	my $class  = shift;
	my $config = shift;

	my $self = {};

	$self->{default}  = $config->{default};
	$self->{user_set} = $config->{user_can_choose};

	foreach (@{$config->{'theme'}}) {
		$self->{'themes'}->{$_->{'name'}} = $_->{'dir'};
	}

	bless $self,$class;

	return $self;
}

sub handle {
	my $self = shift;
	my $p    = shift;

	my $chosen_theme = $self->choose_theme($p);

	my $return = {};

	# URL relative
	$return->{'THEME_DIR'} = $self->{'themes'}->{$chosen_theme};

	# FILE system relative
	my $theme_dir = $p->{'document_root'}."/".$self->{'themes'}->{$chosen_theme};

	my $tc = "$theme_dir/theme.conf";
	if ($self->_is_stale($tc)) {
		$self->{cache}->{$tc} = $self->_load($tc);
	}

	my $conf = $self->{cache}->{$tc};

	# find which style section this page is under
	my $style = $conf->{'pages'}->{$p->{'uri'}}->{'__style__'};
	$self->{'skeleton'} = $self->{'themes'}->{$chosen_theme}."/";

	unless (defined($style)) {
		# not listed.  no theme for you!

		# assume default skeleton.
		$self->{'skeleton'} .= "skeleton";
		return $return;
	}

	$self->{'skeleton'} .= $conf->{'style'}->{$style}->{'skeleton'} || 'skeleton';

	if (defined($conf->{'style'}->{$style}->{'includes'})) {
		while (my ($k,$v) = each %{$conf->{'style'}->{$style}->{'includes'}}) {
			my $template = HTML::Template->new('filename'          => "$theme_dir/$v.tmpl",
			                                   'shared_cache'      => 1,
			                                   'die_on_bad_params' => 0
			                                  );
			$template->param($conf->{'pages'}->{$p->{'uri'}});

			$return->{$k} = $template->output();
		}
	}
	else {
		while (my ($k,$v) = each %{$conf->{'pages'}->{$p->{'uri'}}}) {
			$return->{$k} = $v;
		}
	}

	return $return;
}

sub choose_theme {
	my $self = shift;
	my $p    = shift;

	my $session = $p->{'session'};

	# check for an override of what's in the template conf file.
	my $sys_override = $p->{'document_root'}."/.theme_conf";

	my $chosen_theme = $self->{'default'};

	if (-e $sys_override && -s $sys_override) {
		my $mtime = (stat($sys_override))[9];

		if (!defined($self->{'sys_theme'}->{'mtime'}) || $self->{'sys_theme'}->{'mtime'} ne $mtime) {
			unless(open(T,$sys_override)) {
				die "Can't open $sys_override: $!";
			}
			my $t = <T>;
			chomp($t);
			close(T);

			if ($t ne "default" && defined($self->{'themes'}->{$t})) {
				$chosen_theme = $t;
				$self->{'sys_theme'}->{'name'} = $t;
			}

			$self->{'sys_theme'}->{'mtime'} = (stat($sys_override))[9];
		}
		else {
			$chosen_theme = $self->{'sys_theme'}->{'name'};
		}
	}

	if ($self->{'user_set'}) {
		my $user_theme = $session->{'user_theme'};
		if (defined($user_theme) && $user_theme ne "default") {
			if (defined($self->{'themes'}->{$user_theme})) {
				$chosen_theme = $user_theme;
			}
			else {
				delete ($session->{'user_theme'});
			}
		}
	}

	return $chosen_theme;
}

sub _load {
	my $self = shift;
	my $file = shift;

	my $record;

	my $config_general = Config::General->new($file);
	my %conf = $config_general->getall;

	$record->{'mtime'} = (stat($file))[9];
	foreach my $style (keys %{$conf{'style'}}) {
		$record->{'style'}->{$style}->{'skeleton'} = $conf{'style'}->{$style}->{'skeleton'};
		$record->{'style'}->{$style}->{'includes'} = $conf{'style'}->{$style}->{'includes'};
		foreach my $page (keys %{$conf{'style'}->{$style}->{'pages'}}) {
			$record->{'pages'}->{$page} = $conf{'style'}->{$style}->{'pages'}->{$page};
			$record->{'pages'}->{$page}->{'__style__'} = $style;
		}
	}

	return $record;
}

sub _is_stale {
	my $self = shift;
	my $file = shift;

	return 1 unless defined($self->{'cache'}->{$file});
	return ($self->{'cache'}->{$file}->{'mtime'} != (stat($file))[9]);
}

sub get_skeleton {
	return shift->{'skeleton'};
}

1;

################################################################################
# Copyright (c) 2005-2010 Steven Edwards (maverick@smurfbane.org).
# All rights reserved.
#
# You may use and distribute Apache::Voodoo under the terms described in the
# LICENSE file include in this package. The summary is it's a legalese version
# of the Artistic License :)
#
################################################################################
