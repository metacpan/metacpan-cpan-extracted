package CGI::Lingua;

use warnings;
use strict;
use Storable; # RT117983
use Class::Autouse qw{Carp Locale::Language Locale::Object::Country Locale::Object::DB I18N::AcceptLanguage I18N::LangTags::Detect};

use vars qw($VERSION);
our $VERSION = '0.59';

=head1 NAME

CGI::Lingua - Create a multilingual web page

=head1 VERSION

Version 0.59

=cut

=head1 SYNOPSIS

No longer does your website need to be in English only.
CGI::Lingua provides a simple basis to determine which language to display a
website. The website tells CGI::Lingua which languages it supports. Based on
that list CGI::Lingua tells the application which language the user would like
to use.

    use CGI::Lingua;
    # ...
    my $l = CGI::Lingua->new(supported => ['en', 'fr', 'en-gb', 'en-us']);
    my $language = $l->language();
    if ($language eq 'English') {
       print '<P>Hello</P>';
    } elsif($language eq 'French') {
	print '<P>Bonjour</P>';
    } else {	# $language eq 'Unknown'
	my $rl = $l->requested_language();
	print "<P>Sorry for now this page is not available in $rl.</P>";
    }
    my $c = $l->country();
    if ($c eq 'us') {
      # print contact details in the US
    } elsif ($c eq 'ca') {
      # print contact details in Canada
    } else {
      # print worldwide contact details
    }

    # ...

    use CHI;
    use CGI::Lingua;
    # ...
    my $cache = CHI->new(driver => 'File', root_dir => '/tmp/cache', namespace => 'CGI::Lingua-countries');
    my $l = CGI::Lingua->new({ supported => ['en', 'fr'], cache => $cache });

=head1 SUBROUTINES/METHODS

=head2 new

Creates a CGI::Lingua object.

Takes one mandatory parameter: a list of languages, in RFC-1766 format,
that the website supports.
Language codes are of the form primary-code [ - country-code ] e.g.
'en', 'en-gb' for English and British English respectively.

For a list of primary-codes refer to ISO-639 (e.g. 'en' for English).
For a list of country-codes refer to ISO-3166 (e.g. 'gb' for United Kingdom).

    # We support English, French, British and American English, in that order
    my $l = CGI::Lingua(supported => ['en', 'fr', 'en-gb', 'en-us']);

Takes optional parameter cache, an object which is used to cache country
lookups.
This cache object is an object that understands get() and set() messages,
such as a L<CHI> object.

Takes an optional parameter syslog, to log messages to
L<Sys::Syslog>.
It can be a boolean to enable/disable logging to syslog, or a reference
to a hash to be given to Sys::Syslog::setlogsock.

Takes optional parameter logger, an object which is used for warnings
and traces.
This logger object is an object that understands warn() and trace()
messages, such as a L<Log::Log4perl> object.

Takes optional parameter info, an object which can be used to see if a CGI
parameter is set, for example an L<CGI::Info> object.

Since emitting warnings from a CGI class can result in messages being lost (you
may forget to look in your server's log), or appearing to the client in
amongst HTML causing invalid HTML, it is recommended either either syslog
or logger (or both) are set.
If neither is given, L<Carp> will be used.

Takes an optional parameter dont_use_ip.  By default, if none of the
requested languages is supported, CGI::Lingua->language() looks in the IP
address for the language to use.  This may be not what you want, so use this
option to disable the feature.

The optional parameter debug is passed on to L<I18N::AcceptLanguage>.

=cut

sub new {
	my $proto = shift;

	my $class = ref($proto) || $proto;
	my %params = (ref($_[0]) eq 'HASH') ? %{$_[0]} : @_;

	# TODO: check that the number of supported languages is > 0
	# unless($params{supported} && ($#params{supported} > 0)) {
		# croak('You must give a list of supported languages');
	# }
	unless($params{supported}) {
		Carp::croak('You must give a list of supported languages');
	}

	my $cache = $params{cache};
	my $logger = $params{logger};
	my $info = $params{info};

	if($cache && $ENV{'REMOTE_ADDR'}) {
		my $key = "$ENV{REMOTE_ADDR}/";
		my $l;
		if($info && ($l = $info->lang())) {
			$key .= "$l/";
		} elsif($l = $class->_what_language()) {
			$key .= "$l/";
		}
		$key .= join('/', @{$params{supported}});
		if($logger) {
			$logger->debug("Looking in cache for $key");
		}
		if(my $rc = $cache->get($key)) {
			if($logger) {
				$logger->debug('Found - thawing');
			}
			$rc = Storable::thaw($rc);
			$rc->{_logger} = $logger;
			$rc->{_syslog} = $params{syslog};
			$rc->{_cache} = $cache;
			$rc->{_supported} = $params{supported};
			$rc->{_info} = $info;

			if(($rc->{_what_language} || $rc->{_rlanguage}) && $info && $info->lang()) {
				delete $rc->{_what_language};
				delete $rc->{_rlanguage};
				delete $rc->{_country};
			}
			return $rc;
		}
	}

	return bless {
		_supported => $params{supported}, # List of languages (two letters) that the application
		_cache => $cache,	# CHI
		_info => $info,
		# _rlanguage => undef,	# Requested language
		# _slanguage => undef,	# Language that the website should display
		# _sublanguage => undef,	# E.g. United States for en-US if you want American English
		# _slanguage_code_alpha2 => undef, # E.g en, fr
		# _sublanguage_code_alpha2 => undef, # E.g. us, gb
		# _country => undef,	# Two letters, e.g. gb
		# _locale => undef,	# Locale::Object::Country
		_syslog => $params{syslog},
		_dont_use_ip => $params{dont_use_ip} || 0,
		_logger => $logger,
		_have_ipcountry => -1,	# -1 = don't know
		_have_geoip => -1,	# -1 = don't know
		_have_geoipfree => -1,	# -1 = don't know
		_debug => $params{debug} || 0,
	}, $class;
}

# Some of the information takes a long time to work out, so cache what we can
sub DESTROY {
	if(defined($^V) && ($^V ge 'v5.14.0')) {
		return if ${^GLOBAL_PHASE} eq 'DESTRUCT';	# >= 5.14.0 only
	}
	unless($ENV{'REMOTE_ADDR'}) {
		return;
	}
	my $self = shift;
	return unless(ref($self));

	my $cache = $self->{_cache};
	return unless($cache);

	my $key = "$ENV{REMOTE_ADDR}/";
	if(my $l = $self->_what_language()) {
		$key .= "$l/";
	}
	$key .= join('/', @{$self->{_supported}});
	return if($cache->get($key));

	if(my $logger = $self->{_logger}) {
		$logger->trace("Storing self in cache as $key");
	}

	my $copy = bless {
		_slanguage => $self->{_slanguage},
		_slanguage_code_alpha2 => $self->{_slanguage_code_alpha2},
		_sublanguage_code_alpha2 => $self->{_sublanguage_code_alpha2},
		_country => $self->{_country},
		_rlanguage => $self->{_rlanguage},
		_dont_use_ip => $self->{_dont_use_ip},
		_have_ipcountry => $self->{_have_ipcountry},
		_have_geoip => $self->{_have_geoip},
		_have_geoipfree => $self->{_have_geoipfree},
	}, ref($self);

	# All of these crash, presumably something recursive is going on
	# my $copy = Clone::clone($self);
	# my $storable = Storable::nfreeze(Storable::dclone($self));
	# my $storable = Storable::dclone($self);

	$cache->set($key, Storable::nfreeze($copy), '1 month');
}

# Emit a warning message somewhere
sub _warn {
	my ($self, $params) = @_;

	my $warning = $$params{'warning'};

	return unless($warning);

	if(my $syslog = $self->{_syslog}) {
		require Sys::Syslog;
		require CGI::Info;

		Sys::Syslog->import();
		if(ref($syslog eq 'HASH')) {
			Sys::Syslog::setlogsock($syslog);
		}
		if(my $info = $self->{_info}) {
			openlog($info->script_name(), 'cons,pid', 'user');
		} else {
			openlog(CGI::Info->new(syslog => $syslog)->script_name(), 'cons,pid', 'user');
		}
		syslog('warning', $warning);
		closelog();
	}

	if($self->{_logger}) {
		$self->{_logger}->warn($warning);
	} elsif(!defined($self->{_syslog})) {
		Carp::carp($warning);
	}
}

=head2 language

Tells the CGI application what language to display its messages in.
The language is the natural name e.g. 'English' or 'Japanese'.

Sublanguages are handled sensibly, so that if a client requests U.S. English
on a site that only serves British English, language() will return 'English'.

If none of the requested languages is included within the supported lists,
language() returns 'Unknown'.

    use CGI::Lingua;
    # Site supports English and British English
    my $l = CGI::Lingua->new(supported => ['en', 'fr', 'en-gb']);

    # If the browser requests 'en-us' , then language will be 'English' and
    # sublanguage will be undefined because we weren't able to satisfy the
    # request

    # Site supports British English only
    my $l = CGI::Lingua->new({supported => ['fr', 'en-gb']});

    # If the browser requests 'en-us' , then language will be 'English' and
    # sublanguage will also be undefined, which may seem strange, but it
    # ensures that sites behave sensibly.

If the script is not being run in a CGI environment, perhaps to debug it, the
locale is used via the LANG environment variable.
=cut

sub language {
	my $self = shift;

	unless($self->{_slanguage}) {
		$self->_find_language();
	}
	return $self->{_slanguage};
}

=head2 name

Synonym for language, for compatibility with Local::Object::Language

=cut

sub name {
	my $self = shift;

	return $self->language();
}

=head2 sublanguage

Tells the CGI what variant to use e.g. 'United Kingdom', or 'Unknown' if
it can't be determined.

Sublanguages are handled sensibly, so that if a client requests U.S. English
on a site that only serves British English, sublanguage() will return undef.

=cut

sub sublanguage {
	my $self = shift;

	unless($self->{_slanguage}) {
		$self->_find_language();
	}
	return $self->{_sublanguage};
}

=head2 language_code_alpha2

Gives the two character representation of the supported language, e.g. 'en'
when you've asked for en-gb.

If none of the requested languages is included within the supported lists,
language_code_alpha2() returns undef.

=cut

sub language_code_alpha2 {
	my $self = shift;

	if($self->{_logger}) {
		$self->{_logger}->trace('Entered language_code_alpha2');
	}
	unless($self->{_slanguage}) {
		$self->_find_language();
	}
	if($self->{_logger}) {
		$self->{_logger}->trace('language_code_alpha2 returns ', $self->{_slanguage_code_alpha2});
	}
	return $self->{_slanguage_code_alpha2};
}


=head2 code_alpha2

Synonym for language_code_alpha2, kept for historical reasons.

=cut

sub code_alpha2 {
	my $self = shift;

	return $self->language_code_alpha2();
}

=head2 sublanguage_code_alpha2

Gives the two character representation of the supported language, e.g. 'gb'
when you've asked for en-gb, or undef.

=cut

sub sublanguage_code_alpha2 {
	my $self = shift;

	unless($self->{_slanguage}) {
		$self->_find_language();
	}
	return $self->{_sublanguage_code_alpha2};
}


=head2 requested_language

Gives a human readable rendition of what language the user asked for whether
or not it is supported.

=cut

sub requested_language {
	my $self = shift;

	unless($self->{_rlanguage}) {
		$self->_find_language();
	}
	return $self->{_rlanguage};
}

# The language cache is stored as country_2_letter -> $language_human_readable_name=$language_2_letter
# The IP cache is stored as ip -> country_human_readable_name

# Returns the human readable language, such as 'English'

sub _find_language {
	my $self = shift;

	if($self->{_logger}) {
		$self->{_logger}->trace('Entered _find_language');
	}
	$self->{_rlanguage} = 'Unknown';
	$self->{_slanguage} = 'Unknown';

	# Use what the client has said
	my $http_accept_language = $self->_what_language();
	if(defined($http_accept_language)) {
		if($self->{_logger}) {
			$self->{_logger}->debug("language wanted: $http_accept_language");
		}

		# Workaround for RT 74338
		local $SIG{__WARN__} = sub {
			if($_[0] !~ /^Use of uninitialized value/) {
				warn $_[0];
			}
		};
		my $i18n = I18N::AcceptLanguage->new(debug => $self->{_debug});
		my $l = $i18n->accepts($http_accept_language, $self->{_supported});
		local $SIG{__WARN__} = 'DEFAULT';
		if((!$l) && ($http_accept_language =~ /(.+)-.+/)) {
			# Fall back position, e,g. we want US English on a site
			# only giving British English, so allow it as English.
			# The calling program can detect that it's not the
			# wanted flavour of English by looking at
			# requested_language
			if($i18n->accepts($1, $self->{_supported})) {
				$l = $1;
			}
		}

		if($l) {
			if($self->{_logger}) {
				$self->{_logger}->debug("l: $l");
			}

			unless($l =~ /^..-..$/) {
				$self->{_slanguage} = $self->_code2language($l);
				if($self->{_slanguage}) {
					if($self->{_logger}) {
						$self->{_logger}->debug("_slanguage: $self->{_slanguage}");
					}
					# We have the language, but not the right
					# sublanguage, e.g. they want US English but we
					# only support British English or English
					# wanted: en-us, got en-gb and en
					$self->{_slanguage_code_alpha2} = $l;
					$self->{_rlanguage} = $self->{_slanguage};

					my $sl;
					if($http_accept_language =~ /..-(..)$/) {
						$sl = $self->_code2country($1);
					} elsif($http_accept_language =~ /..-([a-z]{2,3})$/i) {
						$sl = Locale::Object::Country->new(code_alpha3 => $1);
					}
					if($sl) {
						$self->{_rlanguage} .= ' (' . $sl->name() . ')';
						# The requested sublanguage
						# isn't supported so don't
						# define that
					}
					return;
				}
			}
			# TODO: Handle es-419 "Spanish (Latin America)"
			if($l =~ /(.+)-(..)$/) {
				my $alpha2 = $1;
				my $variety = $2;
				# my $accepts = $i18n->accepts($l, $self->{_supported});
				my $accepts = $l;

				if($accepts) {
					if($self->{_logger}) {
						$self->{_logger}->debug("accepts: $accepts");
					}
					if($accepts =~ /\-/) {
						delete $self->{_slanguage};
					} else {
						my $from_cache;
						if($self->{_cache}) {
							$from_cache = $self->{_cache}->get($accepts);
						}
						if($from_cache) {
							if($self->{_logger}) {
								$self->{_logger}->debug("$accepts is in cache as $from_cache");
							}
							$self->{_slanguage} = (split(/=/, $from_cache))[0];
						} else {
							$self->{_slanguage} = $self->_code2language($accepts);
						}
						if($self->{_slanguage}) {
							if($variety eq 'uk') {
								# ???
								$self->_warn({
									warning => "Resetting country code to GB for $http_accept_language"
								});
								$variety = 'gb';
							}
							my $c = $self->_code2countryname($variety);
							if(defined($c)) {
								$self->{_sublanguage} = $c;
							}
							$self->{_slanguage_code_alpha2} = $accepts;
							if($self->{_sublanguage}) {
								$self->{_rlanguage} = "$self->{_slanguage} ($self->{_sublanguage})";
								if($self->{_logger}) {
									$self->{_logger}->debug("_rlanguage: $self->{_rlanguage}");
								}
							}
							$self->{_sublanguage_code_alpha2} = $variety;
							unless($from_cache) {
								if($self->{_logger}) {
									$self->{_logger}->debug("Set $variety to $self->{_slanguage}=$self->{_slanguage_code_alpha2}");
								}
								$self->{_cache}->set($variety, "$self->{_slanguage}=$self->{_slanguage_code_alpha2}", '1 month');
							}
							return;
						}
					}
				}
				$self->{_rlanguage} = $self->_code2language($alpha2);
				if($self->{_logger}) {
					$self->{_logger}->debug("_rlanguage: $self->{_rlanguage}");
				}
				if($accepts) {
					$http_accept_language =~ /(.{2})-(..)/;
					$variety = lc($2);
					# Ignore en-029 etc (Carribean English)
					if(($variety =~ /[a-z]{2,3}/) && !defined($self->{_sublanguage})) {
						$self->_get_closest($alpha2, $alpha2);
						if($self->{_logger}) {
							$self->{_logger}->debug("Find the country code for $variety");
						}
						if($variety eq 'uk') {
							# ???
							$self->_warn({
								warning => "Resetting country code to GB for $http_accept_language"
							});
							$variety = 'gb';
						}
						my $from_cache;
						my $language_name;
						if($self->{_cache}) {
							$from_cache = $self->{_cache}->get($variety);
						}
						if(defined($from_cache)) {
							if($self->{_logger}) {
								$self->{_logger}->debug("$variety is in cache as $from_cache");
							}
							my $language_code2;
							($language_name, $language_code2) = split(/=/, $from_cache);
							$language_name = $self->_code2countryname($variety);
						} else {
							my $db = Locale::Object::DB->new();
							my @results = @{$db->lookup(
								table => 'country',
								result_column => 'name',
								search_column => 'code_alpha2',
								value => $variety
							)};
							if(defined($results[0])) {
								eval {
									$language_name = $self->_code2countryname($variety);
								};
							}
						}
						if($@ || !defined($language_name)) {
							$self->{_sublanguage} = 'Unknown';
							$self->_warn({
								warning => "Can't determine values for $http_accept_language"
							});
						} else {
							$self->{_sublanguage} = $language_name;
							if($self->{_logger}) {
								$self->{_logger}->debug('variety name ' . $self->{_sublanguage});
							}
							if($self->{_cache} && !defined($from_cache)) {
								if($self->{_logger}) {
									$self->{_logger}->debug("Set $variety to $self->{_slanguage}=$self->{_slanguage_code_alpha2}");
								}
								$self->{_cache}->set($variety, "$self->{_slanguage}=$self->{_slanguage_code_alpha2}", '1 month');
							}
						}
					}
					if(defined($self->{_sublanguage})) {
						$self->{_rlanguage} = "$self->{_slanguage} ($self->{_sublanguage})";
						$self->{_sublanguage_code_alpha2} = $variety;
						return;
					}
				}
			}
		}
		if($self->{_slanguage} && ($self->{_slanguage} ne 'Unknown')) {
			if($self->{_rlanguage} eq 'Unknown') {
				$self->{_rlanguage} = I18N::LangTags::Detect::detect();
			}
			if($self->{_rlanguage}) {
				if($l = $self->_code2language($self->{_rlanguage})) {
					$self->{_rlanguage} = $l;
				# } else {
					# We have the language, but not the right
					# sublanguage, e.g. they want US English but we
					# only support British English
					# wanted: en-us, got en-gb and not en
				}
				return;
			}
		}
		if(((!$self->{_rlanguage}) || ($self->{_rlanguage} eq 'Unknown')) &&
		   ((length($http_accept_language) == 2) || ($http_accept_language =~ /^..-..$/))) {
			$self->{_rlanguage} = $self->_code2language($http_accept_language);

			unless($self->{_rlanguage}) {
				$self->{_rlanguage} = 'Unknown';
			}
		}
		$self->{_slanguage} = 'Unknown';
	}

	if($self->{_dont_use_ip}) {
		return;
	}

	# The client hasn't said which to use, guess from their IP address,
	# or the requested language(s) isn't/aren't supported so use the IP
	# address for an alternative
	my $country = $self->country();

	if((!defined($country)) && (my $c = $self->_what_language())) {
		if($c =~ /^(..)_(..)/) {
			$country = $2;	# Best guess
		} elsif($c =~ /^(..)$/) {
			$country = $1;	# Wrong, but maybe something will drop out
		}
	}

	if(defined($country)) {
		if($self->{_logger}) {
			$self->{_logger}->debug("country: $country");
		}
		# Determine the first official language of the country

		my $from_cache;
		if($self->{_cache}) {
			$from_cache = $self->{_cache}->get($country);
		}
		my $language_name;
		my $language_code2;
		if($from_cache) {
			if($self->{_logger}) {
				$self->{_logger}->debug("$country is in cache as $from_cache");
			}
			($language_name, $language_code2) = split(/=/, $from_cache);
		} else {
			my $l = $self->_code2country(uc($country));
			if($l) {
				$l = ($l->languages_official)[0];
				if(defined($l)) {
					$language_name = $l->name;
					$language_code2 = $l->code_alpha2;
					if($self->{_logger} && $language_name) {
						$self->{_logger}->debug("Official language: $language_name");
					}
				}
			}
		}
		my $ip = $ENV{'REMOTE_ADDR'};
		if($language_name) {
			if((!defined($self->{_rlanguage})) || ($self->{_rlanguage} eq 'Unknown')) {
				$self->{_rlanguage} = $language_name;
			}
			unless((exists($self->{_slanguage})) && ($self->{_slanguage} ne 'Unknown')) {
				# Check if the language is one that we support
				# Don't bother with secondary language
				my $code;

				if($language_name && $language_code2 && !defined($http_accept_language)) {
					# This sort of thing speeds up search engine access a lot
					if($self->{_logger}) {
						$self->{_logger}->debug("Fast assign to $language_code2");
					}
					$code = $language_code2;
				} else {
					if($self->{_logger}) {
						$self->{_logger}->debug("Call language2code on $self->{_rlanguage}");
					}
					$code = Locale::Language::language2code($self->{_rlanguage});
					unless($code) {
						if($http_accept_language && ($http_accept_language ne $self->{_rlanguage})) {
							if($self->{_logger}) {
								$self->{_logger}->debug("Call language2code on $http_accept_language");
							}
							$code = Locale::Language::language2code($http_accept_language);
						}
						unless($code) {
							# If language is Norwegian (Nynorsk)
							# lookup Norwegian
							if($self->{_rlanguage} =~ /(.+)\s\(.+/) {
								if((!defined($http_accept_language)) || ($1 ne $self->{_rlanguage})) {
									if($self->{_logger}) {
										$self->{_logger}->debug("Call language2code on $1");
									}
									$code = Locale::Language::language2code($1);
								}
							}
							unless($code) {
								$self->_warn({
									warning => "Can't determine code from IP $ip for requested language $self->{_rlanguage}"
								});
							}
						}
					}
				}
				if($code) {
					$self->_get_closest($code, $language_code2);
					unless($self->{_slanguage}) {
						$self->_warn({
							warning => "Couldn't determine closest language for $language_name in $self->{_supported}"
						});
					} elsif($self->{_logger}) {
						$self->{_logger}->debug("language set to $self->{_slanguage}, code set to $code");
					}
				}
			}
			if(!defined($self->{_slanguage_code_alpha2})) {
				if($self->{_logger}) {
					$self->{_logger}->debug("Can't determine slanguage_code_alpha2");
				}
			} elsif(!defined($from_cache) && $self->{_cache} &&
			   defined($self->{_slanguage_code_alpha2})) {
				if($self->{_logger}) {
					$self->{_logger}->debug("Set $country to $language_name=$self->{_slanguage_code_alpha2}");
				}
				$self->{_cache}->set($country, "$language_name=$self->{_slanguage_code_alpha2}", '1 month');
			}
		} elsif(defined($ip)) {
			$self->_warn({
				warning => "Can't determine language from IP $ip, country $country"
			});
		}
	}
}

# Try our very best to give the right country - if they ask for en-us and
# we only have en-gb then give it to them

sub _get_closest {
	my ($self, $language_string, $alpha2) = @_;

	foreach (@{$self->{_supported}}) {
		my $s;
		if(/^(.+)-.+/) {
			$s = $1;
		} else {
			$s = $_;
		}
		if($language_string eq $s) {
			$self->{_slanguage} = $self->{_rlanguage};
			$self->{_slanguage_code_alpha2} = $alpha2;
			last;
		}
	}
}

# What's the language being requested? Can be used in both a class and an object context
sub _what_language {
	my $self = shift;

	if(ref($self)) {
		if($self->{_logger}) {
			$self->{_logger}->trace('Entered _what_language');
		}
		if($self->{_what_language}) {
			if($self->{_logger}) {
				$self->{_logger}->trace('_what_language: returning cached value: ', $self->{_what_language});
			}
			return $self->{_what_language};	# Useful in case something changes the $info hash
		}
		if(my $info = $self->{_info}) {
			if(my $rc = $info->lang()) {
				# E.g. cgi-bin/script.cgi?lang=de
				if($self->{_logger}) {
					$self->{_logger}->trace("_what_language set language to $rc from the lang argument");
				}
				return $self->{_what_language} = $rc;
			}
		}
	}

	if(defined($ENV{'LANG'})) {
		# Running the script locally, presumably to debug, so set the language
		# from the Locale
		if(ref($self)) {
			return $self->{_what_language} = $ENV{'LANG'};
		}
		return $ENV{'LANG'};
	}

	if($ENV{'HTTP_ACCEPT_LANGUAGE'}) {
		if(ref($self)) {
			return $self->{_what_language} = $ENV{'HTTP_ACCEPT_LANGUAGE'};
		}
		return $ENV{'HTTP_ACCEPT_LANGUAGE'};
	}
}

=head2 country

Returns the two character country code of the remote end in lower case.

If L<IP::Country>, L<Geo::IPfree> or L<Geo::IP> is installed,
CGI::Lingua will make use of that, otherwise it will do a Whois lookup.
If you do not have any of those installed I recommend you make use of the
caching capability of CGI::Lingua.

=cut

sub country {
	my $self = shift;

	if($self->{_logger}) {
		$self->{_logger}->trace('Entered country');
	}

	# FIXME: If previous calls to country() return undef, we'll
	# waste time going through again and no doubt returning undef
	# again.
	if($self->{_country}) {
		if($self->{_logger}) {
			$self->{_logger}->trace('quick return: ' . $self->{_country});
		}
		return $self->{_country};
	}

	# mod_geoip
	if(defined($ENV{'GEOIP_COUNTRY_CODE'})) {
		$self->{_country} = lc($ENV{'GEOIP_COUNTRY_CODE'});
		return $self->{_country};
	}
	if(($ENV{'HTTP_CF_IPCOUNTRY'}) && ($ENV{'HTTP_CF_IPCOUNTRY'} ne 'XX')) {
		# Hosted by Cloudfare
		$self->{_country} = lc($ENV{'HTTP_CF_IPCOUNTRY'});
		return $self->{_country};
	}

	my $ip = $ENV{'REMOTE_ADDR'};

	return unless(defined($ip));

	require Data::Validate::IP;
	Data::Validate::IP->import();

	unless(is_ipv4($ip)) {
		if($ip eq '::1') {
			# special case that is easy to handle
			$ip = '127.0.0.1';
		} else {
			$self->_warn({
				warning => "$ip isn't a valid IPv4 address\n"
			});
			return;
		}
	}
	if(is_private_ip($ip)) {
		if($self->{_logger}) {
			$self->{_logger}->trace("Can't determine country from LAN connection $ip");
		}
		return;
	}
	if(is_loopback_ip($ip)) {
		if($self->{_logger}) {
			$self->{_logger}->trace("Can't determine country from loopback connection $ip");
		}
		return;
	}

	if($self->{_cache}) {
		$self->{_country} = $self->{_cache}->get($ip);
		if($self->{_logger}) {
			if(defined($self->{_country})) {
				$self->{_logger}->debug("Get $ip from cache = $self->{_country}");
			} else {
				$self->{_logger}->debug("$ip isn't in the cache");
			}
		}
		if(defined($self->{_country})) {
			return $self->{_country};
		}
	}

	if($self->{_have_ipcountry} == -1) {
		if(eval { require IP::Country; }) {
			IP::Country->import();
			$self->{_have_ipcountry} = 1;
			$self->{_ipcountry} = IP::Country::Fast->new();
		} else {
			$self->{_have_ipcountry} = 0;
		}
	}
	if($self->{_logger}) {
		$self->{_logger}->debug("have_ipcountry $self->{_have_ipcountry}");
	}

	if($self->{_have_ipcountry}) {
		$self->{_country} = $self->{_ipcountry}->inet_atocc($ip);
		if($self->{_country}) {
			$self->{_country} = lc($self->{_country});
		} else {
			$self->_warn({
				warning => "$ip is not known by IP::Country"
			});
		}
	}
	unless(defined($self->{_country})) {
		if($self->{_have_geoip} == -1) {
			if(($^O eq 'MSWin32') || (-r '/usr/local/share/GeoIP/GeoIP.dat')) {
				if(eval { require Geo::IP; }) {
					Geo::IP->import();
					$self->{_have_geoip} = 1;
					# GEOIP_STANDARD = 0, can't use that because you'll
					# get a syntax error
					$self->{_geoip} = Geo::IP->new(0);
				} else {
					$self->{_have_geoip} = 0;
				}
			} else {
				$self->{_have_geoip} = 0;
			}
		}
		if($self->{_have_geoip} == 1) {
			$self->{_country} = $self->{_geoip}->country_code_by_addr($ip);
		}
		unless(defined($self->{_country})) {
			if($self->{_have_geoipfree} == -1) {
				if(eval { require Geo::IPfree; }) {
					Geo::IPfree::IP->import();
					$self->{_have_geoipfree} = 1;
					$self->{_geoipfree} = Geo::IPfree->new();
				} else {
					$self->{_have_geoipfree} = 0;
				}
			}
			if($self->{_have_geoipfree} == 1) {
				$self->{_country} = lc(($self->{_geoipfree}->LookUp($ip))[0]);
			}
		}
	}
	if($self->{_country} && ($self->{_country} eq 'eu')) {
		delete($self->{_country});
	}
	unless($self->{_country}) {
		if($self->{_logger}) {
			$self->{_logger}->debug("Look up $ip on geoplugin");
		}

		if(eval { require LWP::Simple; require JSON::Parse } ) {
			LWP::Simple->import();
			JSON::Parse->import();

			if(my $data = LWP::Simple::get("http://www.geoplugin.net/json.gp?ip=$ip")) {
				$self->{_country} = JSON::Parse::parse_json($data)->{'geoplugin_countryCode'};
			}
		}
	}
	unless($self->{_country}) {
		if($self->{_logger}) {
			$self->{_logger}->debug("Look up $ip on Whois");
		}
		require Net::Whois::IP;
		Net::Whois::IP->import();

		my $whois;

		eval {
			# Catch connection timeouts to
			# whois.ripe.net by turning the carp
			# into an error
			local $SIG{__WARN__} = sub { die $_[0] };
			$whois = Net::Whois::IP::whoisip_query($ip);
		};
		unless($@ || !defined($whois) || (ref($whois) ne 'HASH')) {
			if(defined($whois->{Country})) {
				$self->{_country} = $whois->{Country};
			} elsif(defined($whois->{country})) {
				$self->{_country} = $whois->{country};
			}
			if($self->{_country} && ($self->{_country} eq 'eu')) {
				delete($self->{_country});
			}
		}

		unless($self->{_country}) {
			if($self->{_logger}) {
				$self->{_logger}->debug("Look up $ip on IANA");
			}

			require Net::Whois::IANA;
			Net::Whois::IANA->import();

			my $iana = Net::Whois::IANA->new();
			eval {
				$iana->whois_query(-ip => $ip);
			};
			unless ($@) {
				$self->{_country} = $iana->country();
				if($self->{_logger}) {
					$self->{_logger}->debug("IANA reports $ip as " . $self->{_country});
				}
			}
		}

		if($self->{_country}) {
			# 190.24.1.122 has carriage return in its WHOIS record
			$self->{_country} =~ s/[\r\n]//g;
			if($self->{_country} =~ /^(..)\s*#/) {
				# Remove comments in the Whois record
				$self->{_country} = $1;
			}
		}
		# TODO - try freegeoip.net if whois has failed
	}

	if($self->{_country}) {
		$self->{_country} = lc($self->{_country});
		if($self->{_country} eq 'hk') {
			# Hong Kong is no longer a country, but Whois thinks
			# it is - try "whois 218.213.130.87"
			$self->{_country} = 'cn';
		} elsif($self->{_country} eq 'eu') {
			require Net::Subnet;

			# RT-86809, Baidu claims it's in EU not CN
			Net::Subnet->import();
			if(subnet_matcher('185.10.104.0/22')->($ip)) {
				$self->{_country} = 'cn';
			} else {
				# There is no country called 'eu'
				$self->_warn({
					warning => "$ip has country of eu"
				});
				$self->{_country} = 'Unknown';
			}
		}
		if($self->{_cache}) {
			if($self->{_logger}) {
				$self->{_logger}->debug("Set $ip to $self->{_country}");
			}
			$self->{_cache}->set($ip, $self->{_country}, '1 hour');
		}
	}

	return $self->{_country};
}

=head2 locale

HTTP doesn't have a way of transmitting a browser's localisation information
which would be useful for default currency, date formatting etc.

This method attempts to detect the information, but it is a best guess
and is not 100% reliable.  But it's better than nothing ;-)

Returns a L<Locale::Object::Country> object.

To be clear, if you're in the US and request the language in Spanish,
and the site supports it, language() will return 'Spanish', and locale() will
try to return the Locale::Object::Country for the US.

=cut

sub locale {
	my $self = shift;

	if($self->{_locale}) {
		return $self->{_locale};
	}

	# First try from the User Agent.  Probably only works with Mozilla and
	# Safari.  I don't know about Opera.  It won't work with IE or Chrome.
	my $agent = $ENV{'HTTP_USER_AGENT'};
	my $country;
	if(defined($agent) && ($agent =~ /\((.+)\)/)) {
		foreach(split(/;/, $1)) {
			my $candidate = $_;

			$candidate =~ s/^\s//g;
			$candidate =~ s/\s$//g;
			if($candidate =~ /^[a-zA-Z]{2}-([a-zA-Z]{2})$/) {
				local $SIG{__WARN__} = undef;
				my $c = $self->_code2country($1);
				if($c) {
					$self->{_locale} = $c;
					return $c;
				}
				# carp "Warning: unknown country $1 derived from $candidate in HTTP_USER_AGENT ($agent)";
			}
		}

		if(eval { require HTTP::BrowserDetect; } ) {
			HTTP::BrowserDetect->import();
			my $browser = HTTP::BrowserDetect->new($agent);

			if($browser && $browser->country()) {
				my $c = $self->_code2country($browser->country());
				if($c) {
					$self->{_locale} = $c;
					return $c;
				}
			}
		}
	}

	# Try from the IP address
	$country = $self->country();

	if($country) {
		$country =~ s/[\r\n]//g;

		my $c;
		eval {
			local $SIG{__WARN__} = sub { die $_[0] };
			$c = $self->_code2country($country);
		};
		unless($@) {
			if($c) {
				$self->{_locale} = $c;
				return $c;
			}
		}
	}

	# Try mod_geoip
	if(defined($ENV{'GEOIP_COUNTRY_CODE'})) {
		$country = $ENV{'GEOIP_COUNTRY_CODE'};
		my $c = $self->_code2country($country);
		if($c) {
			$self->{_locale} = $c;
			return $c;
		}
	}
	return ();	# returns undef
}

# Wrapper to Locale::Language::code2language which makes use of the cache
sub _code2language
{
	my ($self, $code) = @_;

	return unless($code);
	if($self->{_logger}) {
		if(defined($self->{_country})) {
			$self->{_logger}->trace("_code2language $code, country " . $self->{_country});
		} else {
			$self->{_logger}->trace("_code2language $code");
		}
	}
	unless($self->{_cache}) {
		return Locale::Language::code2language($code);
	}
	my $from_cache = $self->{_cache}->get("code2language/$code");
	if($from_cache) {
		if($self->{_logger}) {
			$self->{_logger}->trace("_code2language found in cache $from_cache");
		}
		return $from_cache;
	}
	if($self->{_logger}) {
		$self->{_logger}->trace('_code2language not in cache, storing');
	}
	return $self->{_cache}->set("code2language/$code", Locale::Language::code2language($code), '1 month');
}

# Wrapper to Locale::Object::Country allowing for persistance to be added
sub _code2country
{
	my ($self, $code) = @_;

	return unless($code);
	if($self->{_logger}) {
		if($self->{_country}) {
			$self->{_logger}->trace("_code2country $code, country " . $self->{_country});
		} else {
			$self->{_logger}->trace("_code2country $code");
		}
	}
	local $SIG{__WARN__} = sub {
		if($_[0] !~ /No result found in country table/) {
			warn $_[0];
		}
	};
	my $rc = Locale::Object::Country->new(code_alpha2 => $code);
	local $SIG{__WARN__} = 'DEFAULT';
	return $rc;
}

# Wrapper to Locale::Object::Country->name which makes use of the cache
sub _code2countryname
{
	my ($self, $code) = @_;

	return unless($code);
	if($self->{_logger}) {
		$self->{_logger}->trace("_code2countryname $code");
	}
	unless($self->{_cache}) {
		my $country = $self->_code2country($code);
		if(defined($country)) {
			return $country->name;
		}
		return;
	}
	my $from_cache = $self->{_cache}->get("code2countryname/$code");
	if($from_cache) {
		if($self->{_logger}) {
			$self->{_logger}->trace("_code2countryname found in cache $from_cache");
		}
		return $from_cache;
	}
	if($self->{_logger}) {
		$self->{_logger}->trace('_code2countryname not in cache, storing');
	}
	my $country = $self->_code2country($code);
	if(defined($country)) {
		return $self->{_cache}->set("code2countryname/$code", $country->name, '1 month');
	}
}

=head1 AUTHOR

Nigel Horne, C<< <njh at bandsman.co.uk> >>

=head1 BUGS

If HTTP_ACCEPT_LANGUAGE is 3 characters, e.g., es-419,
sublanguage() returns undef.

Please report any bugs or feature requests to C<bug-cgi-lingua at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CGI-Lingua>.
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SEE ALSO

L<Locale::Country>
L<HTTP::BrowserDetect>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc CGI::Lingua


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=CGI-Lingua>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/CGI-Lingua>

=item * Search CPAN

L<http://search.cpan.org/dist/CGI-Lingua/>

=back


=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2018 Nigel Horne.

This program is released under the following licence: GPL2

=cut

1; # End of CGI::Lingua
