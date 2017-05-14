#!/usr/bin/perl
#
# Annelidous - the flexibile cloud management framework
# Copyright (C) 2009  Eric Windisch <eric@grokthis.net>
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
# 
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

# 
# I didn't want to discard this, it might still be useful.
# That is why it was moved here to this module...
#

package Annelidous::Utility::Email;

# Email
use MIME::Lite::TT;

sub new {
	my $self={
	    @_
	};
	bless $self, shift;
	return $self;
}

# where @to is a client-list or any array of hashes containing key email.
# args (template, subject, from, (ClientList) @cl)
sub email_list {
	my $self=shift;
    my $template = shift;
    my $subject = shift;
    my $from = shift;
    my @cl = @_;

    foreach my $client (@cl) {
        my $msg = MIME::Lite::TT->new(
            From => $from,
            To => $client->{'email'},
            Subject => $subject,
            Template => $template,
            TmplOptions => {
                INCLUDE_PATH => 'email-tmpl'
            },
            TmplParams => $client
        );
        $msg->send;
    }
}

1;