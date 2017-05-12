package Archive::Har::Entry::Cookie;

use warnings;
use strict;
use JSON();
use Carp();

our $VERSION = '0.21';

sub new {
    my ( $class, $params ) = @_;
    my $self = {};
    bless $self, $class;
    if ( defined $params ) {
        $self->name( $params->{name} );
        $self->value( $params->{value} );
        if ( defined $params->{path} ) {
            $self->path( $params->{path} );
        }
        if ( defined $params->{domain} ) {
            $self->domain( $params->{domain} );
        }
        if ( defined $params->{expires} ) {
            $self->expires( $params->{expires} );
        }
        if ( defined $params->{httpOnly} ) {
            $self->http_only( $params->{httpOnly} );
        }
        if ( defined $params->{secure} ) {
            $self->secure( $params->{secure} );
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

sub path {
    my ( $self, $new ) = @_;
    my $old = $self->{path};
    if ( @_ > 1 ) {
        $self->{path} = $new;
    }
    return $old;
}

sub domain {
    my ( $self, $new ) = @_;
    my $old = $self->{domain};
    if ( @_ > 1 ) {
        $self->{domain} = $new;
    }
    return $old;
}

sub expires {
    my ( $self, $new ) = @_;
    my $old = $self->{expires};
    if ( @_ > 1 ) {
        $self->{expires} = $new;
    }
    return $old;
}

sub http_only {
    my ( $self, $new ) = @_;
    my $old = $self->{httpOnly};
    if ( @_ > 1 ) {
        $self->{httpOnly} = $new;
    }
    if ( defined $old ) {
        return $old ? 1 : 0;
    }
    else {
        return;
    }
}

sub secure {
    my ( $self, $new ) = @_;
    my $old = $self->{secure};
    if ( @_ > 1 ) {
        $self->{secure} = $new;
    }
    if ( defined $old ) {
        return $old ? 1 : 0;
    }
    else {
        return;
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

    my $name = $Archive::Har::Entry::Cookie::AUTOLOAD;
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
    if ( defined $self->path() ) {
        $json->{path} = $self->path();
    }
    if ( defined $self->domain() ) {
        $json->{domain} = $self->domain();
    }
    if ( defined $self->expires() ) {
        $json->{expires} = $self->expires();
    }
    if ( defined $self->http_only() ) {
        $json->{httpOnly} = $self->http_only() ? JSON::true() : JSON::false();
    }
    if ( defined $self->secure() ) {
        $json->{secure} = $self->secure() ? JSON::true() : JSON::false();
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

Archive::Har::Entry::Cookie - Represents a single http cookie object for a request or response inside the HTTP Archive

=head1 VERSION

Version '0.21'

=for stopwords HAR httpOnly https

=head1 SYNOPSIS

    use Archive::Har();

    my $http_archive_string = '"log": { "version": "1.1", .... ';
    my $har = Archive::Har->new();
    $har->string($http_archive_string);
    foreach my $entry ($har->entries()) {
        my $request = $entry->request();
	foreach my $cookie ($request->cookies()) {
                $cookie->comment("Something interesting here");
		print "Name: " . $cookie->name() . "\n";
		print "Value: " . $cookie->value() . "\n";
		print "Path: " . $cookie->path() . "\n";
		print "Domain: " . $cookie->domain() . "\n";
		print "Expires: " . $cookie->expires() . "\n";
		print "httpOnly: " . $cookie->http_only() . "\n";
		print "secure: " . $cookie->secure() . "\n";
		print "Comment: " . $cookie->comment() . "\n";
	}
    }

=head1 DESCRIPTION
 
This Module is intended to provide an interface to create/read/update
Cookie objects in HTTP Archive (HAR) files.

=head1 SUBROUTINES/METHODS

=head2 name

returns the name of the cookie

=head2 value

returns the value of the cookie

=head2 path

returns the path of the cookie

=head2 domain

returns the domain of the cookie

=head2 expires

returns the expiry date (if any) of the cookie

=head2 http_only

returns a true/false value if the cookie is marked as httpOnly

=head2 secure

returns a true/false value if the cookie is marked as secure, to only be transmitted over https

=head2 comment

returns the comment about the cookie

=head1 DIAGNOSTICS

=over

=item C<< %s is not specified in the HAR 1.2 spec and does not start with an underscore >>

The HAR 1.2 specification allows undocumented fields, but they must start with an underscore

=back

=head1 CONFIGURATION AND ENVIRONMENT

Archive::Har::Entry::Cookie requires no configuration files or environment variables.  

=head1 DEPENDENCIES

Archive::Har::Entry::Cookie requires no additional non-core Perl modules

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
