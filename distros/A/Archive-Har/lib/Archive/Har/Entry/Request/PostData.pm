package Archive::Har::Entry::Request::PostData;

use warnings;
use strict;
use Carp();
use Archive::Har::Entry::Request::PostData::Params();

our $VERSION = '0.21';

sub new {
    my ( $class, $params ) = @_;
    my $self = {};
    bless $self, $class;
    if ( defined $params ) {
        $self->mime_type( $params->{mimeType} );
        if (   ( defined $params->{params} )
            && ( ref $params->{params} eq 'ARRAY' )
            && ( scalar @{ $params->{params} } > 0 ) )
        {
            my @params;
            foreach my $param ( @{ $params->{params} } ) {
                push @params,
                  Archive::Har::Entry::Request::PostData::Params->new($param);
            }
            $self->params( \@params );
        }
        elsif ( defined $params->{text} ) {
            $self->text( $params->{text} );
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
    return $old;
}

sub text {
    my ( $self, $new ) = @_;
    my $old = $self->{text};
    if ( @_ > 1 ) {
        delete $self->{params};
        $self->{text} = $new;
    }
    return $old;
}

sub params {
    my ( $self, $new ) = @_;
    my $old = $self->{params};
    if ( @_ > 1 ) {
        delete $self->{text};
        $self->{params} = [];
        if ( ( defined $new ) && ( ref $new eq 'ARRAY' ) ) {
            foreach my $param ( @{$new} ) {
                push @{ $self->{params} }, $param;
            }
        }
    }
    if ( defined $old ) {
        return @{$old};
    }
    else {
        return ();
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

    my $name = $Archive::Har::Entry::Request::PostData::AUTOLOAD;
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
    $json->{mimeType} = $self->mime_type();
    $json->{params}   = [ $self->params() ];
    if ( defined $self->text() ) {
        $json->{text} = $self->text();
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

Archive::Har::Entry::Request::PostData - Represents a single name/value pair from the query string for a request inside the HTTP Archive

=head1 VERSION

Version '0.21'

=for stopwords HAR PostData undef params

=head1 SYNOPSIS

    use Archive::Har();

    my $http_archive_string = '"log": { "version": "1.1", .... ';
    my $har = Archive::Har->new();
    $har->string($http_archive_string);
    foreach my $entry ($har->entries()) {
        my $request = $entry->request();
	my $postData = $request->postData();
	if (defined $postData) {
            print "MimeType: " . $postData->mime_type() . "\n";
            print "Text: " . $postData->text() . "\n";
            foreach my $element ($postData->params()) {
            }
            print "Comment: " . $postData->comment() . "\n";
        }
    }

=head1 DESCRIPTION
 
This Module is intended to provide an interface to create/read/update
PostData objects in HTTP Archive (HAR) files.

=head1 SUBROUTINES/METHODS

=head2 new

returns a new PostData object

=head2 mime_type

returns the mime type of the posted data

=head2 text

returns the plain text posted data.  It will return undef if params has been defined

=head2 params

returns a list of L<posted parameters|Archive::Har::Entry::Request::PostData::Params>

=head2 comment

returns the comment about the Post Data

=head1 DIAGNOSTICS

=over

=item C<< %s is not specified in the HAR 1.2 spec and does not start with an underscore >>

The HAR 1.2 specification allows undocumented fields, but they must start with an underscore

=back

=head1 CONFIGURATION AND ENVIRONMENT

Archive::Har::Entry::Request::PostData requires no configuration files or environment variables.  

=head1 DEPENDENCIES

Archive::Har::Entry::Request::PostData requires no additional non-core Perl modules

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
