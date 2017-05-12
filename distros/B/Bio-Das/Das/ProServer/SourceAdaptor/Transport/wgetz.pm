package Bio::Das::ProServer::SourceAdaptor::Transport::wgetz;

# wgetz.pm
# A ProServer transport module for wgetz (SRS web access)
#
# Andreas Kahari, andreas.kahari@ebi.ac.uk
#

use strict;
use warnings;

use Bio::Das::ProServer::SourceAdaptor::Transport::generic;

use vars qw(@ISA);
@ISA = qw(Bio::Das::ProServer::SourceAdaptor::Transport::generic);

use LWP::UserAgent;

sub _useragent
{
    # Caching an LWP::UserAgent instance within the current
    # object.

    my $self = shift;

    if (!defined $self->{_useragent}) {
	$self->{_useragent} = new LWP::UserAgent(
	    env_proxy	=> 1,
	    keep_alive	=> 1,
	    timeout	=> 30
	);
    }

    return $self->{_useragent};
}

sub init
{
    my $self = shift;
    $self->_useragent();
}

sub query
{
    my $self = shift;

    my $swgetz = $self->config->{wgetz} ||
	'http://srs.ebi.ac.uk/srsbin/cgi-bin/wgetz';

    my $query = my $squery = join '+', @_;

    # Remove characters not allowed in transport.
    $swgetz =~ s/[^\w.\/:-]//;
    # Remove characters not allowed in query.
    $squery =~ s/[^\w[\](){}.><:'" |+-]//;

    if ($squery ne $query) {
	warn "Detainted '$squery' != '$query'";
    }

    my $reply = $self->_useragent()->get("$swgetz?$squery+-ascii");

    if (!$reply->is_success()) {
	warn "wgetz request failed: $swgetz?$squery+-ascii\n";
    }

    return $reply->content();
}

1;
