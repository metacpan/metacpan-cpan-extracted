# $Id$

use strict;
use Text::Wrap;
use File::Spec;
use lib './t/lib';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME            => 'CGI::Session::Driver::aggregator',
    VERSION_FROM    => 'lib/CGI/Session/Driver/aggregator.pm',
    PREREQ_PM       => {
        'CGI::Session'       => 4.00,
        'Test::More'         => 0,
    },
    ABSTRACT        => 'Persistent session data in CGI applications',
    AUTHOR          => 'Kazuhiro Oinuma <oinume@cpan.org>',
    clean           => { FILES => [ 't/tmp' ] },
);


package MY;
use strict;

sub postamble {
    return <<'MAKE_TEXT';
prepare_dist ::	metafile manifest dist
	$(NOECHO) $(NOOP)
MAKE_TEXT
}

sub libscan {
    my ($self, $path) = @_;
    return '' if $path =~ m/\.svn/;
    return $path;
}

