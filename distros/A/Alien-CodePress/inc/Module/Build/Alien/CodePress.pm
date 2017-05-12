# $Id$
# $Source$
# $Author$
# $HeadURL$
# $Revision$
# $Date$
package Module::Build::Alien::CodePress;
use base 'Module::Build';

use strict;
use warnings;

use Carp;
use English    qw( -no_match_vars );
use FindBin    qw($Bin);
use File::Path qw(mkpath);
use File::Copy qw(copy);
use File::Spec;
use lib File::Spec->catfile($Bin, 'lib');

use Alien::CodePress::Archive;


my $CODEPRESS_TARGET  = 'blib/lib/Alien/CodePress/';

# Fix up new so it takes hashref instead of hash.
sub new {
    my ($self, $options_ref) = @_;

    return $self->SUPER::new(%{ $options_ref });
}

sub ACTION_code {
    my $self = shift;
    $self->SUPER::ACTION_code(@_);
    $self->fetch_codepress();
    $self->install_codepress();
    return;
}

sub fetch_codepress {
    my ($self) = @_;
    return if -f Alien::CodePress::Archive->filename();

    eval 'require File::Fetch'; ## no critic
    if ($EVAL_ERROR) {
        $self->log_error('This feature requires File::Fetch', "\n");
        return;
    } 

    my $codepress_url = Alien::CodePress::Archive->url(); 

    $self->log_info('Downloading CodePress...', "\n");
    my $path = File::Fetch->new(
        uri => $codepress_url,
    )->fetch();
    if (not $path) {
        croak "Unable to fetch CodePress archive at $codepress_url\n";
    }

    return;
}

sub install_codepress {
    my ($self) = @_;

    my $archive = Alien::CodePress::Archive->filename();
    my $source  = $archive;
    my $dest    = File::Spec->catfile($CODEPRESS_TARGET, $archive);
    return if -d $dest;

    $self->log_info('Installing CodePress...', "\n");
    mkpath($CODEPRESS_TARGET);
    copy($source, $dest)
        or die "Couldn't copy [$source] --> [$dest]: $OS_ERROR";

    return;
}

1;

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
# End:
# vim: expandtab tabstop=4 shiftwidth=4 shiftround
