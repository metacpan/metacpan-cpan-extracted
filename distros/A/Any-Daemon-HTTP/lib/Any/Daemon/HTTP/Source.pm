# Copyrights 2013-2019 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of distribution Any-Daemon-HTTP. Meta-POD processed
# with OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package Any::Daemon::HTTP::Source;
use vars '$VERSION';
$VERSION = '0.29';


use warnings;
use strict;

use Log::Report    'any-daemon-http';

use Net::CIDR      qw/cidrlookup/;
use List::Util     qw/first/;
use HTTP::Status   qw/HTTP_FORBIDDEN/;

sub _allow_cleanup($);
sub _allow_match($$$$);


sub new(@)
{   my $class = shift;
    my $args  = @_==1 ? shift : +{@_};
    (bless {}, $class)->init($args);
}

sub init($)
{   my ($self, $args) = @_;

    my $path = $self->{ADHS_path}  = $args->{path} || '/';
    $self->{ADHS_allow} = _allow_cleanup $args->{allow};
    $self->{ADHS_deny}  = _allow_cleanup $args->{deny};
    $self->{ADHS_name}  = $args->{name} || $path;
    $self;
}

#-----------------

sub path()     {shift->{ADHS_path}}
sub name()     {shift->{ADHS_name}}

#-----------------

sub allow($$$$)
{   my ($self, $session, $req, $uri) = @_;
    if(my $allow = $self->{ADHS_allow})
    {   $self->_allow_match($session, $uri, $allow) or return 0;
    }
    if(my $deny = $self->{ADHS_deny})
    {    $self->_allow_match($session, $uri, $deny) and return 0;
    }
    1;
}

sub _allow_match($$$$)
{   my ($self, $session, $uri, $rules) = @_;
    my $peer = $session->get('peer');
    first { $_->($peer->{ip}, $peer->{host}, $session, $uri) } @$rules;
}

sub _allow_cleanup($)
{   my $p = shift or return;
    my @p;
    foreach my $r (ref $p eq 'ARRAY' ? @$p : $p)
    {   push @p
          , ref $r eq 'CODE'      ? $r
          : index($r, ':') >= 0   ? sub {cidrlookup $_[0], $r}    # IPv6
          : $r !~ m/[a-zA-Z]/     ? sub {cidrlookup $_[0], $r}    # IPv4
          : substr($r,0,1) eq '.' ? sub {$_[1] =~ qr/(^|\.)\Q$r\E$/i} # Domain
          :                         sub {lc($_[1]) eq lc($r)}     # hostname
    }
    @p ? \@p : undef;
}


sub collect($$$$)
{   my ($self, $vhost, $session, $req, $uri) = @_;

    $self->allow($session, $req, $uri)
        or return HTTP::Response->new(HTTP_FORBIDDEN);

    $self->_collect($vhost, $session, $req, $uri);
}

sub _collect($$$) { panic "must be extended" }

#-----------------------

#-----------------------

1;
