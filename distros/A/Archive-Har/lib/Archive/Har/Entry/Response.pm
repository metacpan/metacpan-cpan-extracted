package Archive::Har::Entry::Response;

use warnings;
use strict;
use Carp();
use Archive::Har::Entry::Header();
use Archive::Har::Entry::Cookie();
use Archive::Har::Entry::Response::Content();

our $VERSION = '0.21';

sub _DOES_NOT_APPLY { return -1 }

sub new {
    my ( $class, $params ) = @_;
    my $self = {};
    bless $self, $class;
    if ( defined $params ) {
        $self->status( $params->{status} );
        $self->status_text( $params->{statusText} );
        $self->http_version( $params->{httpVersion} );
        my @cookies;
        foreach my $cookie ( @{ $params->{cookies} } ) {
            push @cookies, Archive::Har::Entry::Cookie->new($cookie);
        }
        $self->cookies( \@cookies );
        my @headers;
        foreach my $header ( @{ $params->{headers} } ) {
            push @headers, Archive::Har::Entry::Header->new($header);
        }
        $self->headers( \@headers );
        $self->content(
            Archive::Har::Entry::Response::Content->new( $params->{content} ) );
        $self->redirect_url( $params->{redirectURL} );
        $self->headers_size( $params->{headersSize} );
        $self->body_size( $params->{bodySize} );
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

sub status {
    my ( $self, $new ) = @_;
    my $old = $self->{status};
    if ( @_ > 1 ) {
        $self->{status} = $new;
    }
    if ( defined $old ) {
        return $old;
    }
    else {
        return 0;
    }
}

sub status_text {
    my ( $self, $new ) = @_;
    my $old = $self->{statusText};
    if ( @_ > 1 ) {
        $self->{statusText} = $new;
    }
    if ( defined $old ) {
        return $old;
    }
    else {
        return 'Unknown';
    }
}

sub http_version {
    my ( $self, $new ) = @_;
    my $old = $self->{httpVersion};
    if ( @_ > 1 ) {
        $self->{httpVersion} = $new;
    }
    if ( defined $old ) {
        return $old;
    }
    else {
        return 'Unknown';
    }
}

sub headers {
    my ( $self, $new ) = @_;
    my $old = $self->{headers};
    if ( @_ > 1 ) {
        $self->{headers} = $new;
    }
    if ( defined $old ) {
        return @{$old};
    }
    else {
        return ();
    }
}

sub cookies {
    my ( $self, $new ) = @_;
    my $old = $self->{cookies};
    if ( @_ > 1 ) {
        $self->{cookies} = $new;
    }
    if ( defined $old ) {
        return @{$old};
    }
    else {
        return ();
    }
}

sub content {
    my ( $self, $new ) = @_;
    my $old = $self->{content};
    if ( @_ > 1 ) {
        $self->{content} = Archive::Har::Entry::Response::Content->new($new);
    }
    return $old;
}

sub redirect_url {
    my ( $self, $new ) = @_;
    my $old = $self->{redirectURL};
    if ( @_ > 1 ) {
        $self->{redirectURL} = $new;
    }
    return $old;
}

sub headers_size {
    my ( $self, $new ) = @_;
    my $old = $self->{headersSize};
    if ( @_ > 1 ) {
        if ( defined $new ) {
            $self->{headersSize} = $new + 0;
        }
        else {
            $self->{headersSize} = _DOES_NOT_APPLY();
        }
    }
    if ( ( defined $old ) && ( $old == _DOES_NOT_APPLY() ) ) {
        return;
    }
    else {
        return $old;
    }
}

sub body_size {
    my ( $self, $new ) = @_;
    my $old = $self->{bodySize};
    if ( @_ > 1 ) {
        if ( defined $new ) {
            $self->{bodySize} = $new + 0;
        }
        else {
            $self->{bodySize} = _DOES_NOT_APPLY();
        }
    }
    if ( ( defined $old ) && ( $old == _DOES_NOT_APPLY() ) ) {
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

    my $name = $Archive::Har::Entry::Response::AUTOLOAD;
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
    $json->{status}      = $self->status();
    $json->{statusText}  = $self->status_text();
    $json->{httpVersion} = $self->http_version();
    $json->{cookies}     = [ $self->cookies() ];
    $json->{headers}     = [ $self->headers() ];
    $json->{content}     = $self->content();
    $json->{redirectURL} = $self->redirect_url();
    if ( defined $self->headers_size() ) {
        $json->{headersSize} = $self->headers_size();
    }
    else {
        $json->{headersSize} = _DOES_NOT_APPLY();
    }
    $json->{headersSize} += 0;
    if ( defined $self->body_size() ) {
        $json->{bodySize} = $self->body_size();
    }
    else {
        $json->{bodySize} = _DOES_NOT_APPLY();
    }
    $json->{bodySize} += 0;
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

Archive::Har::Entry::Response - Represents a single http response inside the HTTP Archive

=head1 VERSION

Version '0.21'

=for stopwords HAR http CRLF

=head1 SYNOPSIS

    use Archive::Har();

    my $http_archive_string = '"log": { "version": "1.1", .... ';
    my $har = Archive::Har->new();
    $har->string($http_archive_string);
    foreach my $entry ($har->entries()) {
        my $response = $entry->response();
	print "Status: " . $response->status() . "\n";
	print "StatusText: " . $response->status_text() . "\n";
	print "HttpVersion: " . $response->http_version() . "\n";
	foreach my $header ($response->headers()) {
	}
	foreach my $cookie ($response->cookies()) {
	}
	my $content = $response->content();
	print "RedirectURL: " . $response->redirect_url() . "\n";
	print "Header Size: " . $response->headers_size() . "\n";
	print "Body Size: " . $response->body_size() . "\n";
	print "Comment: " . $response->comment() . "\n";
    }

=head1 DESCRIPTION
 
This Module is intended to provide an interface to create/read/update
Response objects in HTTP Archive (HAR) files.

=head1 SUBROUTINES/METHODS

=head2 new

returns a new Response object

=head2 status

returns the numeric status of the response

=head2 status_text

returns the status text of the response

=head2 http_version

returns the version of the http response

=head2 headers

returns a list of L<http header|Archive::Har::Entry::Header> objects

=head2 cookies

returns a list of L<http cookie|Archive::Har::Entry::Cookie> objects

=head2 content

returns L<details|Archive::Har::Entry::Response::Content> about the response body

=head2 redirect_url

returns the content of the Location header of the response, if any

=head2 headers_size

returns the total number of bytes in the http response up to and including the double CRLF before the start of the response body

=head2 body_size

returns the total number of bytes in the http response body

=head2 comment

returns the comment about the Entry

=head1 DIAGNOSTICS

=over

=item C<< %s is not specified in the HAR 1.2 spec and does not start with an underscore >>

The HAR 1.2 specification allows undocumented fields, but they must start with an underscore

=back

=head1 CONFIGURATION AND ENVIRONMENT

Archive::Har::Entry::Response requires no configuration files or environment variables.  

=head1 DEPENDENCIES

Archive::Har::Entry::Response requires no additional non-core Perl modules

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
