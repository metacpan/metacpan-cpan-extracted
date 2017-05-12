package Archive::Har::Entry::Request::PostData::Params;

use warnings;
use strict;
use Carp();

our $VERSION = '0.21';

sub new {
    my ( $class, $params ) = @_;
    my $self = {};
    bless $self, $class;
    if ( defined $params ) {
        $self->name( $params->{name} );
        $self->value( $params->{value} );
        if ( defined $params->{fileName} ) {
            $self->file_name( $params->{fileName} );
        }
        if ( defined $params->{contentType} ) {
            $self->content_type( $params->{contentType} );
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

sub name {
    my ( $self, $new ) = @_;
    my $old = $self->{name};
    if ( @_ > 1 ) {
        $self->{name} = $new;
    }
    return $old;
}

sub value {
    my ( $self, $new ) = @_;
    my $old = $self->{value};
    if ( @_ > 1 ) {
        $self->{value} = $new;
    }
    return $old;
}

sub file_name {
    my ( $self, $new ) = @_;
    my $old = $self->{fileName};
    if ( @_ > 1 ) {
        $self->{fileName} = $new;
    }
    return $old;
}

sub content_type {
    my ( $self, $new ) = @_;
    my $old = $self->{contentType};
    if ( @_ > 1 ) {
        $self->{contentType} = $new;
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

    my $name = $Archive::Har::Entry::Request::PostData::Params::AUTOLOAD;
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
    $json->{name}  = $self->name();
    $json->{value} = $self->value();
    if ( defined $self->file_name() ) {
        $json->{fileName} = $self->file_name();
    }
    if ( defined $self->content_type() ) {
        $json->{contentType} = $self->content_type();
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

Archive::Har::Entry::Request::PostData::Params - Represents a single name/value pair from the query string for a request inside the HTTP Archive

=head1 VERSION

Version '0.21'

=for stopwords HAR PostData Params

=head1 SYNOPSIS

    use Archive::Har();

    my $http_archive_string = '"log": { "version": "1.1", .... ';
    my $har = Archive::Har->new();
    $har->string($http_archive_string);
    foreach my $entry ($har->entries()) {
        my $request = $entry->request();
        my $postData = $request->postData();
        if (defined $postData) {
            foreach my $param ($postData->params()) {
                print "Name: " . $element->name() . "\n";
                print "Value: " . $element->value() . "\n";
                print "File Name: " . $element->file_name() . "\n";
                print "Content Type: " . $element->content_type() . "\n";
                print "Comment: " . $element->comment() . "\n";
            }
        }
    }

=head1 DESCRIPTION
 
This Module is intended to provide an interface to create/read/update
PostData Params objects in HTTP Archive (HAR) files.

=head1 SUBROUTINES/METHODS

=head2 new

returns a new Params object

=head2 name

returns the name of the parameter in the posted data

=head2 value

returns the value of the parameter in the posted data or content of the posted file

=head2 file_name

returns the name of the posted file

=head2 content_type

returns the content type of the posted file

=head2 comment

returns the comment about the parameters

=head1 DIAGNOSTICS

=over

=item C<< %s is not specified in the HAR 1.2 spec and does not start with an underscore >>

The HAR 1.2 specification allows undocumented fields, but they must start with an underscore

=back

=head1 CONFIGURATION AND ENVIRONMENT

Archive::Har::Entry::Request::PostData::Params requires no configuration files or environment variables.  

=head1 DEPENDENCIES

Archive::Har::Entry::Request::PostData::Params requires no additional non-core Perl modules

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
