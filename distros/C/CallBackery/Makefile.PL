use 5.022000;

use strict;
use warnings;
use ExtUtils::MakeMaker;
use FindBin;

WriteMakefile(
  NAME         => 'CallBackery',
  VERSION_FROM => 'lib/CallBackery.pm',
  ABSTRACT     => 'CallBackery is a Mojolicious+Qoodoo Framework for building Web Applications',
  AUTHOR       => 'Tobias Oetiker <tobi@oetiker.ch>',
  LICENSE      => 'gpl_3',
  PREREQ_PM    => {
    'Mojolicious' => '9.33',
    'Mojolicious::Plugin::Qooxdoo' => '1.0.14',
    'Config::Grammar' => '1.13',
    'XS::Parse::Keyword' => '0.38',
    'Future::AsyncAwait' => '0.65',
    'Syntax::Keyword::Try' => '0.29',
    'Locale::PO' => '0.27',
    'JSON::Validator' => '5.14',
    'YAML::XS' => '0.88',
    'Text::CSV' => 0,
    'Excel::Writer::XLSX' => 0,
    'Test::Fatal' => 0,
    'Pod::Simple::Text' => 0,
    'Pod::Simple::HTML' => 0,
  },
  BUILD_REQUIRES => {
    'CPAN::Uploader' => 0
  },
  META_MERGE   => {
    requires  => {perl => '5.022000'},
    resources => {
      license     => 'http://opensource.org/licenses/GPL-3.0',
      repository  => 'https://github.com/oetiker/callbackery',
      bugtracker  => 'https://github.com/oetiker/callbackery/issues'
    },
    no_index => {directory => ['t']}
  },
  # dist => {
  #      PREOP => q{$(PERL) -i -p -e 's/CallBackery\@\d+(\.\d+){2}/CallBackery\@$(VERSION)/g' lib/Mojolicious/Command/generate/callbackery_app/PERL_MODULES}
  #},
  test => {TESTS => 't/*.t'}
);

sub MY::postamble {
   my $self = shift;
   my %r = (%{ $self->{PREREQ_PM} || {} }, %{ $self->{BUILD_REQUIRES} || {} }, %{ $self->{TEST_REQUIRES} || {} } );
   my $modules = join " ", grep !/^perl\~/, map { $r{$_} ? $_ .'~"'. $r{$_} .'"' : $_ } keys %r;
   my $tpd = "$FindBin::RealBin/thirdparty";
   warn "** call 'make thirdparty' to build missing dependencies ...\n";
   return <<"EOF";

#all:: README.md README

#README.md: $self->{VERSION_FROM}
#	\$(PERL) -I$tpd/lib/perl5 -MPod::Markdown::Github -e 'binmode(STDOUT, ":utf8");Pod::Markdown::Github->new->filter(q{$self->{VERSION_FROM}})' > README.md

#README: README.md
#	cp README.md README

thirdparty: $tpd/touch
	mkdir -p $tpd

CHANGES: $self->{VERSION_FROM} Makefile
	echo $self->{VERSION} `date +"%Y-%m-%d %H:%M:%S %z"` `git config user.name` '<'`git config user.email`'>' >> CHANGES.new
	\@echo >> CHANGES.new
	\@echo ' -' >> CHANGES.new
	\@echo >> CHANGES.new
	\@cat CHANGES >> CHANGES.new && mv CHANGES.new CHANGES
	\@\$\$EDITOR CHANGES

$tpd/touch: Makefile
	\$(NOECHO) \$(ECHO) "*** INSTALLING MISSING BITS FOR TESTING ***"
	curl -L https://cpanmin.us | PERL_CPANM_HOME=$tpd \$(PERL) - -q --notest --local-lib-contained $tpd $modules && touch $tpd/touch
EOF
}
