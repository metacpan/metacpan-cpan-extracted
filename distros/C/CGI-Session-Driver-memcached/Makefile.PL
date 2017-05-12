# $Id$

use strict;
use lib './t/lib';
use ExtUtils::MakeMaker;

my $has_fast = 0;
my $message = '';
eval "require Cache::Memcached::Fast";
unless ($@) {
    $has_fast = 1;
}

my %prereq_pm = (
    'CGI::Session'       => 4.00,
    'Test::More'         => undef,
);
if ($has_fast) {
    print "[info] You have Cache::Memcached::Fast, so CGI::Session::Driver::memcached may work faster.\n";
}
else {
    print "[info] If you install Cache::Memcached::Fast, it makes CGI::Session::Driver::memcached faster.\n";
    $prereq_pm{'Cache::Memcached'} = undef;
}

WriteMakefile(
    NAME            => 'CGI::Session::Driver::memcached',
    VERSION_FROM    => 'lib/CGI/Session/Driver/memcached.pm',
    PREREQ_PM       => \%prereq_pm,
    ABSTRACT        => 'Persistent session data in CGI applications',
    AUTHOR          => 'Kazuhiro Oinuma <oinume@cpan.org>',
#    clean           => { FILES => [ 't/cgisess.*', 't/sessiondata' ] },
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

