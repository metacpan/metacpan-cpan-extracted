package Binance::API::Logger;

# MIT License
#
# Copyright (c) 2017 Lari Taskula  <lari@taskula.fi>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

use strict;
use warnings;

use Carp;

use Binance::Constants qw( :all );

=head1 NAME

Binance::API::Logger -- Logger for L<Binance::API>

=head1 DESCRIPTION

Provides a wrapper for your desired logger. Carps log calls higher than "debug"
level

=head1 SYNOPSIS

    use Binance::API;

    my $logger = Binance::API::Logger->new($log4perl);

    $logger->warn("This is a warning");

=head1 METHODS

=cut

=head2 new

    my $logger = Binance::API::Logger->new($log4perl);

Instantiates a new C<Binance::API::Logger> object.

B<PARAMETERS>

=over

=item A logger object that implements (at least) debug, warn,
error, fatal level logging.

[OPTIONAL]

=back

B<RETURNS>

A C<Binance::API::Logger> object.

=cut

sub new {
    my $class = shift;

    my $self = {
        logger => undef,
    };

    $self->{logger} = shift if @_;

    bless $self, $class;
}

sub AUTOLOAD {
    my $self = shift;

    my $level = our $AUTOLOAD;
    $level =~ s/.*://;

    my $message = shift;

    my $sub = (caller(1))[3];
    my $full_message = "[$sub] ". $message;

    if ($level eq 'debug' || $level eq 'trace') {
        carp $full_message if DEBUG;
    } else {
        carp $full_message;
    }

    if ($self->{logger} && $self->{logger}->can($level)) {
        $self->{logger}->$level($full_message);
    }
}

1;
