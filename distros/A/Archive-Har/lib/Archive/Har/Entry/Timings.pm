package Archive::Har::Entry::Timings;

use warnings;
use strict;
use Carp();
use Archive::Har::Entry::Cache::Request();

our $VERSION = '0.21';

sub _DOES_NOT_APPLY { return -1 }

sub new {
    my ( $class, $params ) = @_;
    my $self = {};
    bless $self, $class;
    if ( defined $params ) {
        if ( defined $params->{blocked} ) {
            $self->blocked( $params->{blocked} );
        }
        if ( defined $params->{dns} ) {
            $self->dns( $params->{dns} );
        }
        if ( defined $params->{connect} ) {
            $self->connect( $params->{connect} );
        }
        $self->send( $params->{send} );
        $self->wait( $params->{wait} );
        $self->receive( $params->{receive} );
        if ( defined $params->{ssl} ) {
            $self->ssl( $params->{ssl} );
        }
        if ( defined $params->{comment} ) {
            $self->comment( $params->{comment} );
        }
        foreach my $key ( sort { $a cmp $b } keys %{$params} ) {
            if ( $key =~ /^_[[:alnum:]]+$/smx ) {    # private fields
                $self->$key( $params->{$key} );
            }
        }
    }
    return $self;
}

sub blocked {
    my ( $self, $new ) = @_;
    my $old = $self->{blocked};
    if ( @_ > 1 ) {
        if ( defined $new ) {
            $self->{blocked} = $new + 0;
        }
        else {
            $self->{blocked} = _DOES_NOT_APPLY();
        }
    }
    if ( ( defined $old ) && ( $old eq _DOES_NOT_APPLY() ) ) {
        return;
    }
    else {
        return $old;
    }
}

sub dns {
    my ( $self, $new ) = @_;
    my $old = $self->{dns};
    if ( @_ > 1 ) {
        if ( defined $new ) {
            $self->{dns} = $new + 0;
        }
        else {
            $self->{dns} = _DOES_NOT_APPLY();
        }
    }
    if ( ( defined $old ) && ( $old eq _DOES_NOT_APPLY() ) ) {
        return;
    }
    else {
        return $old;
    }
}

sub connect {
    my ( $self, $new ) = @_;
    my $old = $self->{connect};
    if ( @_ > 1 ) {
        if ( defined $new ) {
            $self->{connect} = $new + 0;
        }
        else {
            $self->{connect} = _DOES_NOT_APPLY();
        }
    }
    if ( ( defined $old ) && ( $old eq _DOES_NOT_APPLY() ) ) {
        return;
    }
    else {
        return $old;
    }
}

sub send {
    my ( $self, $new ) = @_;
    my $old = $self->{send};
    if ( @_ > 1 ) {
        $self->{send} = $new;
    }
    return $old;
}

sub wait {
    my ( $self, $new ) = @_;
    my $old = $self->{wait};
    if ( @_ > 1 ) {
        $self->{wait} = $new;
    }
    return $old;
}

sub receive {
    my ( $self, $new ) = @_;
    my $old = $self->{receive};
    if ( @_ > 1 ) {
        $self->{receive} = $new;
    }
    return $old;
}

sub ssl {
    my ( $self, $new ) = @_;
    my $old = $self->{ssl};
    if ( @_ > 1 ) {
        if ( defined $new ) {
            $self->{ssl} = $new;
        }
        else {
            $self->{ssl} = _DOES_NOT_APPLY();
        }
    }
    if ( ( defined $old ) && ( $old eq _DOES_NOT_APPLY() ) ) {
        return;
    }
    else {
        return $old;
    }
}

sub comment {
    my ( $self, $new ) = @_;
    my $old = $self->{comment};
    if ( @_ > 1 ) {
        $self->{comment} = $new;
    }
    return $old;
}

sub AUTOLOAD {
    my ( $self, $new ) = @_;

    my $name = $Archive::Har::Entry::Timings::AUTOLOAD;
    $name =~ s/.*://smx;    # strip fully-qualified portion

    my $old;
    if ( $name =~ /^_[[:alnum:]]+$/smx ) {    # private fields
        $old = $self->{$name};
        if ( @_ > 1 ) {
            $self->{$name} = $new;
        }
    }
    elsif ( $name eq 'DESTROY' ) {
    }
    else {
        Carp::croak(
"$name is not specified in the HAR 1.2 spec and does not start with an underscore"
        );
    }
    return $old;
}

sub TO_JSON {
    my ($self) = @_;
    my $json = {};
    if ( defined $self->blocked() ) {
        $json->{blocked} = $self->blocked() + 0;
    }
    else {
        $json->{blocked} = _DOES_NOT_APPLY();
    }
    if ( defined $self->dns() ) {
        $json->{dns} = $self->dns() + 0;
    }
    else {
        $json->{dns} = _DOES_NOT_APPLY();
    }
    if ( defined $self->connect() ) {
        $json->{connect} = $self->connect() + 0;
    }
    else {
        $json->{connect} = _DOES_NOT_APPLY();
    }
    $json->{send}    = ( $self->send()    || 0 ) + 0;
    $json->{wait}    = ( $self->wait()    || 0 ) + 0;
    $json->{receive} = ( $self->receive() || 0 ) + 0;
    if ( defined $self->ssl() ) {
        $json->{ssl} = $self->ssl() + 0;
    }
    else {
        $json->{ssl} = _DOES_NOT_APPLY();
    }
    if ( defined $self->comment() ) {
        $json->{comment} = $self->comment();
    }
    foreach my $key ( sort { $a cmp $b } keys %{$self} ) {
        next if ( !defined $self->{$key} );
        if ( $key =~ /^_[[:alnum:]]+$/smx ) {    # private fields
            $json->{$key} = $self->{$key};
        }
    }

    return $json;
}

1;
__END__

=head1 NAME

Archive::Har::Entry::Timings - Represents the timings for the individual phases during a request/response pair inside the HTTP Archive

=head1 VERSION

Version '0.21'

=for stopwords HAR undef dns DNS TCP ssl

=head1 SYNOPSIS

    use Archive::Har();

    my $http_archive_string = '"log": { "version": "1.1", .... ';
    my $har = Archive::Har->new();
    $har->string($http_archive_string);
    foreach my $entry ($har->entries()) {
        my $timings = $entry->timings();
        $timings->comment("Something interesting here");
	print "Blocked: " . $timings->blocked() . "\n";
	print "DNS: " . $timings->dns() . "\n";
	print "Connect: " . $timings->connect() . "\n";
	print "Send: " . $timings->send() . "\n";
	print "Wait: " . $timings->wait() . "\n";
	print "Receive: " . $timings->receive() . "\n";
	print "Ssl: " . $timings->ssl() . "\n";
	print "Comment: " . $timings->comment() . "\n";
    }

=head1 DESCRIPTION
 
This Module is intended to provide an interface to create/read/update
Timings objects in HTTP Archive (HAR) files.

=head1 SUBROUTINES/METHODS

=head2 new

returns a new Timings object

=head2 blocked

returns the time in milliseconds spent waiting for a network connection.  The function will return undef if it does not apply to the current request

=head2 dns

returns the time in milliseconds spent in DNS resolution of the host name.  The function will return undef if it does not apply to the current request

=head2 connect

returns the time in milliseconds spent making the TCP connection.  The function will return undef if it does not apply to the current request

=head2 send

returns the time in milliseconds spent sending the request to the server.

=head2 wait

returns the time in milliseconds spent waiting for a response from the server.

=head2 receive

returns the time in milliseconds spent reading the response from the server.

=head2 ssl

returns the time in milliseconds spent negotiating the SSL/TLS session.  The function will return undef if it does not apply to the current request

=head2 comment

returns the comment about the page timings

=head1 DIAGNOSTICS

=over

=item C<< %s is not specified in the HAR 1.2 spec and does not start with an underscore >>

The HAR 1.2 specification allows undocumented fields, but they must start with an underscore

=back

=head1 CONFIGURATION AND ENVIRONMENT

Archive::Har::Entry::Timings requires no configuration files or environment variables.  

=head1 DEPENDENCIES

Archive::Har::Entry::Timings requires no additional non-core Perl modules

=head1 INCOMPATIBILITIES

None reported

=head1 AUTHOR

David Dick, C<< <ddick at cpan.org> >>

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to C<bug-archive-har at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Archive-Har>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 LICENSE AND COPYRIGHT

Copyright 2015 David Dick.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.
