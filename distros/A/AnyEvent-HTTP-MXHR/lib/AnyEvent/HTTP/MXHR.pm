package AnyEvent::HTTP::MXHR;
use strict;
use AnyEvent '6.01';
use AnyEvent::HTTP;
use AnyEvent::Util qw(guard);
use base qw(Exporter);
our @EXPORT = qw(mxhr_get);
our $VERSION = '0.00007';

sub mxhr_get ($@) {
    my $cb = pop;
    my ($uri, %args) = @_;

    my $on_error = delete $args{on_error} || sub { 
        require Carp;
        Carp::confess("@_");
    };
    my $on_eof   = delete $args{on_eof} || sub { };
    my %state;
    $state{guard} = http_get $uri, %args,
        want_body_handle => 1,
        on_error  => $on_error,
        on_header => sub {
            my ($headers) = @_;

            if ($headers->{"content-type"} =~ m{^multipart/mixed\s*;\s*boundary="([^"]+)"}) {
                $state{boundary} = $1;
                $state{boundary_re} = qr!(?:^|\r?\n)--$state{boundary}\n?!;
                return 1;
            } else {
                %state = ();
                $on_error->("Header not found");
                return ();
            }
        },
        sub {
            my $handle = shift;
            if (! $handle) {
                undef $state{guard};
                %state = ();
                $on_error->("Connection failed") if $on_error;
                return ();
            }

            $state{handle} = $handle;

            my $callback; $callback = sub {
                my ($handle, $data) = @_;

                return unless %state;
                $data =~ s/^\s+//;
                if ($data !~ s/(?:^|\r?\n)--$state{boundary}\n?$// ) {
                    # shouldn't even get here
                    if ($handle->{on_error}) {
                        $handle->{on_error}->("No boundary found");
                    }
                    return;
                }

                if ($data !~ s/^(.+?)\015?\012\015?\012// ) {
                    # XXX opting to ignore the data, but should we?
                    $handle->push_read(regex => $state{boundary_re}, $callback);
                    return 1;
                }
                my $headers = $1;

                my %headers = map {
                    my ($n, $v) = split(/:\s*/, $_, 2);
                    # lower case it to align with the rest of AE::HTTP
                    $n = lc $n;
                    ($n, $v);
                } split(/\r?\n/, $headers);
                if (! eval { $cb->($data, \%headers, $handle) }) {
                    %state = ();
                    return;
                }

                $handle->push_read(regex => $state{boundary_re}, $callback);
                return 1;
            };
    
            $handle->push_read(regex => $state{boundary_re}, $callback );
            return 1;
        }
    ;

    return guard { %state = () };

}

1;

__END__

=head1 NAME

AnyEvent::HTTP::MXHR - AnyEvent MXHR Client

=head1 SYNOPSIS

    use AnyEvent::HTTP::MXHR;

    my $guard = mxhr_get $uri, [key => val,] sub {
        my ($body, $headers) = @_;

        # return true if you want to keep reading. return false
        # if you would like to stop
        return 1;
    };

=head1 DESCRIPTION

WARNING: alpha quality code!

=head1 FUNCTION

=head2 mxhr_get $uri, key => value..., $cb->($body, $headers, $handle)

Sends an HTTP GET request, and for each item in the multipar response, 
executes C<$cb>. C<$cb> receives the body of the item, and the sub headers
within that item (NOT the initial headers)

The callback should return a true value if it should keep reading.

=head1 AUTHOR

Daisuke Maki C<< <daisuke@endeworks.jp> >>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
