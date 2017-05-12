package Archive::Har::Entry::Cache;

use warnings;
use strict;
use Carp();
use Archive::Har::Entry::Cache::Request();

our $VERSION = '0.21';

sub new {
    my ( $class, $params ) = @_;
    my $self = {};
    bless $self, $class;
    if ( defined $params ) {
        if ( defined $params->{beforeRequest} ) {
            $self->before_request(
                Archive::Har::Entry::Cache::Request->new(
                    $params->{beforeRequest}
                )
            );
        }
        elsif ( exists $params->{beforeRequest} ) {
            $self->before_request(undef);
        }
        if ( defined $params->{afterRequest} ) {
            $self->after_request(
                Archive::Har::Entry::Cache::Request->new(
                    $params->{afterRequest}
                )
            );
        }
        elsif ( exists $params->{afterRequest} ) {
            $self->after_request(undef);
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

sub before_request {
    my ( $self, $new ) = @_;
    my $old = $self->{beforeRequest};
    if ( @_ > 1 ) {
        $self->{beforeRequest} = $new;
    }
    return $old;
}

sub after_request {
    my ( $self, $new ) = @_;
    my $old = $self->{afterRequest};
    if ( @_ > 1 ) {
        $self->{afterRequest} = $new;
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

    my $name = $Archive::Har::Entry::Cache::AUTOLOAD;
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
    if ( defined $self->before_request() ) {
        $json->{beforeRequest} = $self->before_request();
    }
    elsif ( exists $self->{beforeRequest} ) {
        $json->{beforeRequest} = undef;
    }
    if ( defined $self->after_request() ) {
        $json->{afterRequest} = $self->after_request();
    }
    elsif ( exists $self->{afterRequest} ) {
        $json->{afterRequest} = undef;
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

Archive::Har::Entry::Cache - Represents the cache for a single request/response pair inside the HTTP Archive

=head1 VERSION

Version '0.21'

=for stopwords HAR

=head1 SYNOPSIS

    use Archive::Har();

    my $http_archive_string = '"log": { "version": "1.1", .... ';
    my $har = Archive::Har->new();
    $har->string($http_archive_string);
    foreach my $entry ($har->entries()) {
        my $cache = $entry->cache();
	my $before = $cache->before_request();
	my $after = $cache->after_request();
        $after->comment("Something interesting here");
	print "Comment: " . $cache->comment() . "\n";
    }

=head1 DESCRIPTION
 
This Module is intended to provide an interface to create/read/update
Cache objects in HTTP Archive (HAR) files.

=head1 SUBROUTINES/METHODS

=head2 new

returns a new Cache object

=head2 before_request

returns the L<state|Archive::Har::Entry::Cache::Request> of the cache before the request

=head2 after_request

returns the L<state|Archive::Har::Entry::Cache::Request> of the cache after the request

=head2 comment

returns the comment about the Cache

=head1 DIAGNOSTICS

=over

=item C<< %s is not specified in the HAR 1.2 spec and does not start with an underscore >>

The HAR 1.2 specification allows undocumented fields, but they must start with an underscore

=back

=head1 CONFIGURATION AND ENVIRONMENT

Archive::Har::Entry::Cache requires no configuration files or environment variables.  

=head1 DEPENDENCIES

Archive::Har::Entry::Cache requires no additional non-core Perl modules

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
