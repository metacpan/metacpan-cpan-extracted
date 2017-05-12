package Archive::Har::Entry::Request;

use warnings;
use strict;
use Carp();
use Archive::Har::Entry::Header();
use Archive::Har::Entry::Cookie();
use Archive::Har::Entry::Request::QueryString();
use Archive::Har::Entry::Request::PostData();

our $VERSION = '0.21';

sub _DOES_NOT_APPLY { return -1 }

sub new {
    my ( $class, $params ) = @_;
    my $self = {};
    bless $self, $class;
    if ( defined $params ) {
        $self->method( $params->{method} );
        $self->url( $params->{url} );
        $self->http_version( $params->{httpVersion} );
        my @cookies;
        if (   ( defined $params->{cookies} )
            && ( ref $params->{cookies} eq 'ARRAY' ) )
        {
            foreach my $cookie ( @{ $params->{cookies} } ) {
                push @cookies, Archive::Har::Entry::Cookie->new($cookie);
            }
        }
        $self->cookies( \@cookies );
        my @headers;
        if (   ( defined $params->{headers} )
            && ( ref $params->{headers} eq 'ARRAY' ) )
        {
            foreach my $header ( @{ $params->{headers} } ) {
                push @headers, Archive::Har::Entry::Header->new($header);
            }
        }
        $self->headers( \@headers );
        my @query_string;
        if (   ( defined $params->{queryString} )
            && ( ref $params->{queryString} eq 'ARRAY' ) )
        {
            foreach my $query_string ( @{ $params->{queryString} } ) {
                push @query_string,
                  Archive::Har::Entry::Request::QueryString->new($query_string);
            }
        }
        $self->query_string( \@query_string );
        if ( defined $params->{postData} ) {
            $self->post_data(
                Archive::Har::Entry::Request::PostData->new(
                    $params->{postData}
                )
            );
        }
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

sub method {
    my ( $self, $new ) = @_;
    my $old = $self->{method};
    if ( @_ > 1 ) {
        $self->{method} = defined $new ? uc $new : $new;
    }
    if ( defined $old ) {
        return $old;
    }
    else {
        return 'GET';
    }
}

sub url {
    my ( $self, $new ) = @_;
    my $old = $self->{url};
    if ( @_ > 1 ) {
        $self->{url} = $new;
    }
    if ( defined $old ) {
        return $old;
    }
    else {
        return 'http://example.com/';
    }
}

sub http_version {
    my ( $self, $new ) = @_;
    my $old = $self->{httpVersion};
    if ( @_ > 1 ) {
        $self->{httpVersion} = defined $new ? uc $new : $new;
    }
    if ( defined $old ) {
        return $old;
    }
    else {
        return 'HTTP/0.9';
    }
}

sub cookies {
    my ( $self, $new ) = @_;
    my $old = $self->{cookies};
    if ( @_ > 1 ) {
        $self->{cookies} = $new;
    }
    if ( ( defined $old ) && ( ref $old eq 'ARRAY' ) ) {
        return @{$old};
    }
    else {
        return ();
    }
}

sub headers {
    my ( $self, $new ) = @_;
    my $old = $self->{headers};
    if ( @_ > 1 ) {
        $self->{headers} = $new;
    }
    if ( ( defined $old ) && ( ref $old eq 'ARRAY' ) ) {
        return @{$old};
    }
    else {
        return ();
    }
}

sub query_string {
    my ( $self, $new ) = @_;
    my $old = $self->{queryString};
    if ( @_ > 1 ) {
        $self->{queryString} = $new;
    }
    if ( ( defined $old ) && ( ref $old eq 'ARRAY' ) ) {
        return @{$old};
    }
    else {
        return ();
    }
}

sub post_data {
    my ( $self, $new ) = @_;
    my $old = $self->{postData};
    if ( @_ > 1 ) {
        $self->{postData} = $new;
    }
    return $old;
}

sub headers_size {
    my ( $self, $new ) = @_;
    my $old = $self->{headersSize};
    if ( @_ > 1 ) {
        if ( ( defined $new ) && ( $new =~ /^(\d+)$/smx ) ) {
            $self->{headersSize} = $1 + 0;
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
        if ( ( defined $new ) && ( $new =~ /^(\d+)$/smx ) ) {
            $self->{bodySize} = $1 + 0;
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

    my $name = $Archive::Har::Entry::Request::AUTOLOAD;
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
    $json->{method}      = $self->method();
    $json->{url}         = $self->url();
    $json->{httpVersion} = $self->http_version();
    $json->{cookies}     = [ $self->cookies() ];
    $json->{headers}     = [ $self->headers() ];
    $json->{queryString} = [ $self->query_string() ];
    if ( defined $self->post_data() ) {
        $json->{postData} = $self->post_data();
    }
    if ( defined $self->body_size() ) {
        $json->{bodySize} = $self->body_size();
        if ( $self->body_size() == 0 ) {
            delete $json->{postData};
        }
    }
    else {
        $json->{bodySize} = _DOES_NOT_APPLY();
    }
    if ( defined $self->headers_size() ) {
        $json->{headersSize} = $self->headers_size();
    }
    else {
        $json->{headersSize} = _DOES_NOT_APPLY();
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

Archive::Har::Entry::Request - Represents a single http request inside the HTTP Archive

=head1 VERSION

Version '0.21'

=for stopwords HAR url http undef postData CRLF

=head1 SYNOPSIS

    use Archive::Har();

    my $http_archive_string = '"log": { "version": "1.1", .... ';
    my $har = Archive::Har->new();
    $har->string($http_archive_string);
    foreach my $entry ($har->entries()) {
        my $request = $entry->request();
        $request->comment("Something interesting here");
	print "Method: " . $request->method() . "\n";
	print "Url: " . $request->url() . "\n";
	print "HttpVersion: " . $request->http_version() . "\n";
	foreach my $header ($request->headers()) {
	}
	foreach my $cookie ($request->cookies()) {
	}
	foreach my $item ($request->query_string()) {
	}
	my $post_data = $request->post_data();
	print "Header Size: " . $request->headers_size() . "\n";
	print "Body Size: " . $request->body_size() . "\n";
	print "Comment: " . $request->comment() . "\n";
    }

=head1 DESCRIPTION
 
This Module is intended to provide an interface to create/read/update
Request objects in HTTP Archive (HAR) files.

=head1 SUBROUTINES/METHODS

=head2 new

returns a new Request object

=head2 method

returns the request method

=head2 url

returns the absolute url of the request (excluding fragments)

=head2 http_version

returns the version of the http request

=head2 headers

returns a list of L<http header|Archive::Har::Entry::Header> objects

=head2 cookies

returns a list of L<http cookie|Archive::Har::Entry::Cookie> objects

=head2 query_string

returns a list of the individual L<objects|Archive::Har::Entry::Request::QueryString> in the query string

=head2 post_data

returns the L<post data|Archive::Har::Entry::Request::PostData> object.  This may return undef if the postData is not defined.

=head2 headers_size

returns the total number of bytes in the http request up to and including the double CRLF before the start of the request body

=head2 body_size

returns the total number of bytes in the http request body

=head2 comment

returns the comment about the Request

=head1 DIAGNOSTICS

=over

=item C<< %s is not specified in the HAR 1.2 spec and does not start with an underscore >>

The HAR 1.2 specification allows undocumented fields, but they must start with an underscore

=back

=head1 CONFIGURATION AND ENVIRONMENT

Archive::Har::Entry::Request requires no configuration files or environment variables.  

=head1 DEPENDENCIES

Archive::Har::Entry::Request requires no additional non-core Perl modules

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
