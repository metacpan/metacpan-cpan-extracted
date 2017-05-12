package Archive::Har::Entry::Cache::Request;

use warnings;
use strict;
use Carp();

our $VERSION = '0.21';

sub new {
    my ( $class, $params ) = @_;
    my $self = {};
    bless $self, $class;
    if ( defined $params ) {
        if ( defined $params->{expires} ) {
            $self->expires( $params->{expires} );
        }
        $self->last_access( $params->{lastAccess} );
        $self->etag( $params->{eTag} );
        $self->hit_count( $params->{hitCount} );
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

sub expires {
    my ( $self, $new ) = @_;
    my $old = $self->{expires};
    if ( @_ > 1 ) {
        $self->{expires} = $new;
    }
    return $old;
}

sub last_access {
    my ( $self, $new ) = @_;
    my $old = $self->{lastAccess};
    if ( @_ > 1 ) {
        if ( defined $new ) {
            my $date_regex = qr/\d{4}[-]\d{2}[-]\d{2}/smx;
            my $time_regex = qr/\d{2}:\d{2}:\d{2}[.]\d+/smx;
            my $zone_regex = qr/(?:[+]\d{2}:\d{2}|Z)/smx;
            if ( $new =~ /^${date_regex}T${time_regex}${zone_regex}$/smx ) {
                $self->{lastAccess} = $new;
            }
            else {
                Carp::croak('last_access is not formatted correctly');
            }
        }
        else {
            $self->{lastAccess} = '0000-00-00T00-00-00';
        }
    }
    if ( ( defined $old ) && ( $old eq '0000-00-00T00-00-00' ) ) {
        return;
    }
    else {
        return $old;
    }
}

sub etag {
    my ( $self, $new ) = @_;
    my $old = $self->{eTag};
    if ( @_ > 1 ) {
        $self->{eTag} = $new;
    }
    if ( defined $old ) {
        return $old;
    }
    else {
        return q[];
    }
}

sub hit_count {
    my ( $self, $new ) = @_;
    my $old = $self->{hitCount};
    if ( @_ > 1 ) {
        $self->{hitCount} = $new;
    }
    if ( defined $old ) {
        return $old;
    }
    else {
        return 0;
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

    my $name = $Archive::Har::Entry::Cache::Request::AUTOLOAD;
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
    if ( defined $self->expires() ) {
        $json->{expires} = $self->expires();
    }
    if ( $self->last_access() ) {
        $json->{lastAccess} = $self->last_access();
    }
    else {
        $json->{lastAccess} = '0000-00-00T00-00-00';
    }
    $json->{eTag}     = $self->etag();
    $json->{hitCount} = $self->hit_count();
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

Archive::Har::Entry::Cache::Request - Represents a cache request for a cache inside the HTTP Archive

=head1 VERSION

Version '0.21'

=for stopwords HAR etag

=head1 SYNOPSIS

    use Archive::Har();

    my $http_archive_string = '"log": { "version": "1.1", .... ';
    my $har = Archive::Har->new();
    $har->string($http_archive_string);
    foreach my $entry ($har->entries()) {
        my $cache = $entry->cache();
	my $before_request = $cache->before_request();
        $before_request->comment("Something interesting here");
	print "Expires: " . $before_request->expires() . "\n";
	print "Last Access: " . $before_request->last_access() . "\n";
	print "eTag: " . $before_request->etag() . "\n";
	print "hitCount: " . $before_request->hit_count() . "\n";
	print "Comment: " . $before_request->comment() . "\n";
	my $after_request = $cache->after_request();
	print "Expires: " . $after_request->expires() . "\n";
	print "Last Access: " . $after_request->last_access() . "\n";
	print "eTag: " . $after_request->etag() . "\n";
	print "hitCount: " . $after_request->hit_count() . "\n";
	print "Comment: " . $after_request->comment() . "\n";
    }

=head1 DESCRIPTION
 
This Module is intended to provide an interface to create/read/update
Cache Request objects in HTTP Archive (HAR) files.

=head1 SUBROUTINES/METHODS

=head2 new

returns a new Cache Request object

=head2 expires

returns the expiration time of the cache entry

=head2 last_access

returns the last time the cache was accessed

=head2 etag

returns the etag of the cache

=head2 comment

returns the comment about the Cache Request

=head1 DIAGNOSTICS

=over

=item C<< last_access is not formatted correctly >>

The last_access field must be formatted like so

0000-00-00T00:00:00.0+00:00

=item C<< %s is not specified in the HAR 1.2 spec and does not start with an underscore >>

The HAR 1.2 specification allows undocumented fields, but they must start with an underscore

=back

=head1 CONFIGURATION AND ENVIRONMENT

Archive::Har::Cache::Request requires no configuration files or environment variables.  

=head1 DEPENDENCIES

Archive::Har::Cache::Request requires no additional non-core Perl modules

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
