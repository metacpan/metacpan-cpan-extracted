package Blitz;

use strict;
use warnings;

use Blitz::API;
use Blitz::Exercise;
use Blitz::Sprint;
use Blitz::Rush;

=head1 NAME

Blitz - Perl module for API access to Blitz

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

Blitz provides an interface to the blitz API. Blitz is a
performance and load testing application for testing cloud service apps. 
More information on blitz can be found at http://blitz.io


    use Blitz;

    my $blitz = Blitz->new;

=cut

=head1 SUBROUTINES/METHODS

=head2 new

# Create a new Blitz object

    my $blitz = Blitz->new;

=cut

sub new {
    my $name = shift;
    my $this = shift || {};
    my $self = {
        _authenticated => 0,
        credentials => {
            username => $this->{username},
            api_key   => $this->{api_key},
            host     => $this->{host} || 'blitz.io',
            port     => $this->{port} || 80,
        }
    };
    bless $self;
    return $self;
}


sub _get_set_credentials {
    my $self = shift;
    my $field = shift;
    my $value = shift;
    if ($value) {
        $self->{credentials}{$field} = $value;
    }
    return $self->{credentials}{$field};
}

=head2 username

# Get the currently configured username

    my $user = $blitz->username;

# Set the username

    my $user = $blitz->username('joe@joe.org');

=cut

sub username {
    my $self = shift;
    return _get_set_credentials($self, 'username', @_);
}

=head2 api_key

# Get the currently configured api_key

    my $api_key = $blitz->api_key;

# Set the api_key

    my $api_key = $blitz->api_key('706d5cfbd3338ba110bfg6f46d91f8f3');

=cut

sub api_key {
    my $self = shift;
    return _get_set_credentials($self, 'api_key', @_);
}


=head2 host

# Get the currently configured host

    my $host = $blitz->host;

# Set the host

    my $host = $blitz->host('foo.com');

=cut

sub host {
    my $self = shift;
    return _get_set_credentials($self, 'host', @_);
}

=head2 port

# Get the currently configured port

    my $port = $blitz->port;

# Set the host

    my $port = $blitz->port(8080);

=cut

sub port {
    my $self = shift;
    return _get_set_credentials($self, 'port', @_);
}

=head2 authenticated

Have we been authenticated?

    my $auth = $blitz->authenticated;

=cut

sub authenticated {
    my $self = shift;
    return $self->{_authenticated};
}

=head2 get_client

fetches the existing client object, or 
creates a new Blitz::API->client object

    my $client = $blitz->get_client;
    
=cut

sub get_client {
    my $self = shift;
    if (! $self->{client}) {
        my $client = Blitz::API->client($self->{credentials});
        $self->{client} = $client;
    }
    return $self->{client};
}

sub _run {
    my ($self, $obj, $options, $callback) = @_;
    if ($self->{_authenticated}) {
        my $exercise = $obj->new(
                $self,
                $options,
                $callback
            );
        $exercise->execute();
    }
    else {
        my $client = $self->get_client;
        $client->login(
            sub { 
                my $self = shift;
                my $result = shift;
                if ($result->{ok}) {
                    $self->{_authenticated} = 1;
                    $self->{credentials}{api_key} = $result->{api_key};
                    my $exercise = $obj->new(
                        $self,
                        $options, 
                        $callback
                        );
                    $exercise->execute();
                }
                else {
                    &$callback($result, $result->{error});
                }
            }
        );
    }
}


=head2 sprint

# Sprint

    $blitz->sprint(
        {
            url => 'www.mycoolapp.com',
            region => 'california',
            },
            callback
        }
    );


=cut

sub sprint {
    my $self = shift;
    my $options = shift;
    my $callback = shift;
    _run($self, 'Blitz::Sprint', $options, $callback);
}

=head2 rush

# Rush

    $blitz->rush(
        {
            url => 'www.mycoolapp.com',
            region => 'california',
            pattern => [
                {
                    start => 1,
                    end => 100,
                    duration => 60,
                }
            ]
        },
        callback
        }
    );


=cut


sub rush {
    my $self = shift;
    my $options = shift;
    my $callback = shift;
    _run($self, 'Blitz::Rush', $options, $callback);
}

=head1 AUTHOR

Ben Klaas, C<< <ben at benklaas.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-blitz at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Blitz>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Blitz


You can also look for information at:

=over 4

=item * Github: Open source code repository

L<http://github.com/bklaas/blitz-perl>

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Blitz>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Blitz>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Blitz>

=item * Search CPAN

L<http://search.cpan.org/dist/Blitz/>

=back


=head1 ACKNOWLEDGEMENTS

Thanks to Guilherme Hermeto and Kowsik Guruswamy for assistance
in understanding the blitz API and requirements of the Perl client.

=head1 LICENSE AND COPYRIGHT

This software is under the MIT license

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=cut

1; # End of Blitz
