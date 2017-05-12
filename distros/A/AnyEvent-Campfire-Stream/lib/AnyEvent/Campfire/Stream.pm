package AnyEvent::Campfire::Stream;
{
  $AnyEvent::Campfire::Stream::VERSION = '0.0.3';
}

# Abstract: Receive Campfire streaming API in an event loop
use Moose;
use namespace::autoclean;

extends 'AnyEvent::Campfire';

use AnyEvent;
use AnyEvent::HTTP;
use URI;
use JSON::XS;
use Try::Tiny;

sub BUILD {
    my $self = shift;

    if ( !$self->authorization || !scalar @{ $self->rooms } ) {
        print STDERR
          "Not enough parameters provided. I Need a token and rooms\n";
        exit(1);
    }

    my %headers = (
        Accept        => '*/*',
        Authorization => $self->authorization,
    );

    my $on_json = sub {
        my $json = shift;
        if ( $json !~ /^\s*$/ ) {
            my $data;
            try {
                $data = decode_json($json);
                $self->emit( 'stream', $data );
            }
            catch {
                $self->emit( 'error', "Campfire data parse error: $_" );
            };
        }
    };

    my $on_header = sub {
        my ($hdr) = @_;
        if ( $hdr->{Status} !~ m/^2/ ) {
            $self->emit( 'error', "$hdr->{Status}: $hdr->{Reason}" );
            return;
        }
        return 1;
    };

    my $callback = sub {
        my ( $handle, $headers ) = @_;

        return unless $handle;

        my $chunk_reader = sub {
            my ( $handle, $line ) = @_;

            $line =~ /^([0-9a-fA-F]+)/ or die 'bad chunk (incorrect length)';
            my $len = hex $1;

            $handle->push_read(
                chunk => $len,
                sub {
                    my ( $handle, $chunk ) = @_;

                    $handle->push_read(
                        line => sub {
                            length $_[1]
                              and die 'bad chunk (missing last empty line)';
                        }
                    );

                    $on_json->($chunk);
                }
            );
        };
        my $line_reader = sub {
            my ( $handle, $line ) = @_;
            $on_json->($line);
        };

        $handle->on_error(
            sub {
                undef $handle;
                $self->emit( 'error', $_[2] );
            }
        );

        $handle->on_eof( sub { undef $handle } );
        if ( ( $headers->{'transfer-encoding'} || '' ) =~ /\bchunked\b/i ) {
            $handle->on_read(
                sub {
                    my ($handle) = @_;
                    $handle->push_read( line => $chunk_reader );
                }
            );
        }
        else {
            $handle->on_read(
                sub {
                    my ($handle) = @_;
                    $handle->push_read( line => $line_reader );
                }
            );
        }
    };

    for my $room ( @{ $self->rooms } ) {
        my $uri =
          URI->new("https://streaming.campfirenow.com/room/$room/live.json");
        http_request(
            'GET',
            $uri,
            headers          => \%headers,
            keepalive        => 1,
            want_body_handle => 1,
            on_header        => $on_header,
            $callback,
        );
    }

    return $self;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding utf-8

=head1 NAME

AnyEvent::Campfire::Stream

=head1 VERSION

version 0.0.3

=head1 SYNOPSIS

    use AnyEvent::Campfire::Stream;
    my $stream = AnyEvent::Campfire::Stream->new(
        token => 'xxx',
        rooms => '1234',    # hint: room id is in the url
                            # seperated by comma `,`
    );

    $stream->on('stream', sub {
        my ($s, $data) = @_;    # $s is $stream
        print "$data->{id}: $data->{body}\n";
    });

    $stream->on('error', sub {
        my ($s, $error) = @_;
        print STDERR "$error\n";
    });

=head1 SEE ALSO

=over

=item L<https://github.com/37signals/campfire-api/blob/master/sections/streaming.md>

=back

=head1 AUTHOR

Hyungsuk Hong <hshong@perl.kr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Hyungsuk Hong.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
