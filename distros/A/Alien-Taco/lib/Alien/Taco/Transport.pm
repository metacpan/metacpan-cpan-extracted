# Taco Perl transport module.
# Copyright (C) 2013-2014 Graham Bell
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

=head1 NAME

Alien::Taco::Transport - Taco Perl transport module

=head1 DESCRIPTION

This package implements the communication between Taco clients
and servers.

=cut

package Alien::Taco::Transport;

use JSON;

use strict;

our $VERSION = '0.001';

=head1 METHODS

=over 4

=item new(in => $input, out => $output)

Construct a new object.  This stores the given input and output file
handles and instantiates a JSON processor object.

=cut

sub new {
    my $class = shift;
    my %opts = @_;

    my $json = new JSON();
    $json->convert_blessed(1);

    if (exists $opts{'filter_single'}) {
        $json->filter_json_single_key_object(@{$opts{'filter_single'}});
    }

    my $self = {
        in => $opts{'in'},
        out => $opts{'out'},
        json => $json,
    };

    return bless $self, $class;
}

=item read()

Attempt to read a message from the input filehandle.  Returns the decoded
message as a data structure or undef if nothing was read.

=cut

sub read {
    my $self = shift;
    my $in = $self->{'in'};

    my $text = '';
    while (<$in>) {
        last if /^\/\/ END/;
        $text .= $_;
    }

    return undef unless $text;
    return $self->{'json'}->decode($text);
}

=item write(\%message)

Encode the message and write it to the output filehandle.

=cut

sub write {
    my $self = shift;
    my $out = $self->{'out'};

    my $text = $self->{'json'}->encode(shift);

    local $\ = '';
    print $out $text;
    print $out "\n\/\/ END\n";
    $out->flush();
}

1;

__END__

=back

=cut
