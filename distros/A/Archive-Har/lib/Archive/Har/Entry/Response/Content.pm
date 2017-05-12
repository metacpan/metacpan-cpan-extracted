package Archive::Har::Entry::Response::Content;

use warnings;
use strict;
use Carp();

our $VERSION = '0.21';

sub new {
    my ( $class, $params ) = @_;
    my $self = {};
    bless $self, $class;
    if ( defined $params ) {
        $self->size( $params->{size} );
        $self->mime_type( $params->{mimeType} );
        if ( defined $params->{compression} ) {
            $self->compression( $params->{compression} );
        }
        if ( defined $params->{text} ) {
            $self->text( $params->{text} );
        }
        if ( defined $params->{encoding} ) {
            $self->encoding( $params->{encoding} );
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

sub mime_type {
    my ( $self, $new ) = @_;
    my $old = $self->{mimeType};
    if ( @_ > 1 ) {
        $self->{mimeType} = $new;
    }
    if ( defined $old ) {
        return $old;
    }
    else {
        return 'text/plain';
    }
}

sub size {
    my ( $self, $new ) = @_;
    my $old = $self->{size};
    if ( @_ > 1 ) {
        $self->{size} = $new;
    }
    if ( defined $old ) {
        return $old;
    }
    else {
        return 0;
    }
}

sub compression {
    my ( $self, $new ) = @_;
    my $old = $self->{compression};
    if ( @_ > 1 ) {
        $self->{compression} = $new;
    }
    return $old;
}

sub text {
    my ( $self, $new ) = @_;
    my $old = $self->{text};
    if ( @_ > 1 ) {
        $self->{text} = $new;
    }
    return $old;
}

sub encoding {
    my ( $self, $new ) = @_;
    my $old = $self->{encoding};
    if ( @_ > 1 ) {
        $self->{encoding} = $new;
    }
    return $old;
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

    my $name = $Archive::Har::Entry::Response::Content::AUTOLOAD;
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
    my $json = {
        mimeType => $self->mime_type(),
        size     => $self->size(),
    };
    if ( defined $self->compression() ) {
        $json->{compression} = $self->compression();
    }
    if ( defined $self->text() ) {
        $json->{text} = $self->text();
    }
    if ( defined $self->encoding() ) {
        $json->{encoding} = $self->encoding();
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

Archive::Har::Entry::Response::Content - Represents the content for a response inside the HTTP Archive

=head1 VERSION

Version '0.21'

=for stopwords HAR charset

=head1 SYNOPSIS

    use Archive::Har();

    my $http_archive_string = '"log": { "version": "1.1", .... ';
    my $har = Archive::Har->new();
    $har->string($http_archive_string);
    foreach my $entry ($har->entries()) {
        my $response = $entry->response();
	my $content = $response->content();
	print "Size: " . $content->size() . "\n";
	print "Compression: " . $content->compression() . "\n";
	print "MimeType: " . $content->mime_type() . "\n";
	print "Text: " . $content->text() . "\n";
	print "Encoding: " . $content->encoding() . "\n";
	print "Comment: " . $content->comment() . "\n";
    }

=head1 DESCRIPTION
 
This Module is intended to provide an interface to create/read/update
Content objects in HTTP Archive (HAR) files.

=head1 SUBROUTINES/METHODS

=head2 new

returns a new Content object

=head2 size

returns the length of the returned content in bytes

=head2 compression

returns the number of bytes saved due to compression

=head2 mime_type

returns the mime type of the response text.  The charset attribute is included if available

=head2 text

returns the plain text response.  If this field is not HTTP decoded, then the encoding field may be used

=head2 encoding

returns the encoding (such as base64) of the text field

=head2 comment

returns the comment about the response

=head1 DIAGNOSTICS

=over

=item C<< %s is not specified in the HAR 1.2 spec and does not start with an underscore >>

The HAR 1.2 specification allows undocumented fields, but they must start with an underscore

=back

=head1 CONFIGURATION AND ENVIRONMENT

Archive::Har::Page requires no configuration files or environment variables.  

=head1 DEPENDENCIES

Archive::Har::Page requires no additional non-core Perl modules

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
