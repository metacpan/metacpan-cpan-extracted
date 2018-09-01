package Bio::CIPRES::Message 0.001;

use 5.012;

use strict;
use warnings;

use overload
    '0+'     => sub {return $_[0]->{timestamp}->epoch},
    '""'     => sub {return $_[0]->{text}},
    fallback => 1;

use Carp;
use Time::Piece;
use XML::LibXML;

sub new {

    my ($class, $node) = @_;

        my $t = $node->findvalue('timestamp');
        $t =~ s/(\d\d):(\d\d)$/$1$2/;
        my $self = bless {
            timestamp => Time::Piece->strptime($t, "%Y-%m-%dT%H:%M:%S%z"),
            stage     => $node->findvalue('stage'),
            text      => $node->findvalue('text'),
        } => $class;

        # check for missing values
        map {length $self->{$_} || croak "Missing value for $_\n"} keys %$self;


    return $self;

}

sub timestamp { return $_[0]->{timestamp} };
sub stage     { return $_[0]->{stage}     };
sub text      { return $_[0]->{text}      };


1;

__END__

=head1 NAME

Bio::CIPRES::Message - A simple message class for the CIPRES API

=head1 SYNOPSIS

    for my $msg (@{ $job->messages }) {

        #$msg is a Bio::CIPRES::Message object

        say $msg->text;
        say $msg->timestamp->epoch;
        say $msg->stage;

    }

=head1 DESCRIPTION

C<Bio::CIPRES::Message> is a simple message class for the CIPRES API. Its purpose
is to parse the XML message nodes returned by CIPRES and provide an object that
can be used in different contexts. In string context it returns a textual
summary of the message, and in numeric context it returns the epoch time.

This class is not intended to be used directly by the end user but rather
returned by other class methods suchas C<Bio::CIPRES::Job::messages>.

=head1 EXPORTS

=head1 METHODS

=over 4

=item B<new>

    my $msg = Bio::CIPRES::Message->new($node);

Takes an C<XML::LibXML> node as the only argument and returns a new class
object. Typically not called by the end user.

=item B<timestamp>

    my $time = Bio::CIPRES::Message->timestamp;

Returns a C<Time::Piece> object representing the timestamp of the message.

=item B<stage>

    my $stage = Bio::CIPRES::Message->stage;

Returns a string containing the current stage of the job when the message was
generated.

=item B<text>

    my $text = Bio::CIPRES::Message->text;

Returns a string containing the primary text of the message. This is also the
value returned by auto-stringification.

=back

=head1 CAVEATS AND BUGS

Please reports bugs to the author.

=head1 AUTHOR

Jeremy Volkening <jdv@base2bio.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2016-2018 Jeremy Volkening

This program is free software: you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation, either version 3 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
details.

You should have received a copy of the GNU General Public License along with
this program.  If not, see <http://www.gnu.org/licenses/>.

=cut

