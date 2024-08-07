# Copyrights 2013-2020 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of distribution Any-Daemon-HTTP. Meta-POD processed
# with OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package Any::Daemon::HTTP::Session;
use vars '$VERSION';
$VERSION = '0.30';


use strict;
use warnings;

use Log::Report    'any-daemon-http';

use Socket         qw(inet_aton AF_INET AF_INET6 PF_INET PF_INET6);


sub new(%)  {my $class = shift; (bless {}, $class)->init({@_})}
sub init($)
{   my ($self, $args) = @_;
    $self->{ADHC_store} = $args->{store} || {};
    $self;
}

#-----------------

sub client() {shift->{ADHC_client}}
sub get(@)   {my $s = shift->{ADHC_store}; wantarray ? @{$s}{@_} : $s->{$_[0]}}
sub set($$)  {$_[0]->{ADHC_store}{$_[1]} = $_[2]}

# should not be used
sub _store() {shift->{ADHC_store}}

1;
