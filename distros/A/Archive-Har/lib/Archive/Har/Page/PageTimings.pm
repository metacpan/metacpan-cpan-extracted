package Archive::Har::Page::PageTimings;

use warnings;
use strict;
use Carp();

our $VERSION = '0.21';

sub _DOES_NOT_APPLY { return -1 }

sub new {
    my ( $class, $params ) = @_;
    my $self = {};
    bless $self, $class;
    if ( defined $params ) {
        $self->on_content_load( $params->{onContentLoad} );
        $self->on_load( $params->{onLoad} );
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

sub on_content_load {
    my ( $self, $new ) = @_;
    my $old = $self->{onContentLoad};
    if ( @_ > 1 ) {
        if ( defined $new ) {
            if ( $new =~ /^(\d+(?:[.]\d+)?|-1)$/smx ) {
                $self->{onContentLoad} = $1 + 0;
            }
            else {
                Carp::croak('on_content_load must be a positive number or -1');
            }
        }
        else {
            $self->{onContentLoad} = _DOES_NOT_APPLY();
        }
    }
    if ( ( defined $old ) && ( $old == _DOES_NOT_APPLY() ) ) {
        return;
    }
    else {
        return $old;
    }
}

sub on_load {
    my ( $self, $new ) = @_;
    my $old = $self->{onLoad};
    if ( @_ > 1 ) {
        if ( defined $new ) {
            if ( $new =~ /^(\d+(?:[.]\d+)?|\-1)$/smx ) {
                $self->{onLoad} = $1 + 0;
            }
            else {
                Carp::croak('on_load must be a positive number or -1');
            }
        }
        else {
            $self->{onLoad} = _DOES_NOT_APPLY();
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

    my $name = $Archive::Har::Page::PageTimings::AUTOLOAD;
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
    if ( defined $self->on_content_load() ) {
        $json->{onContentLoad} = $self->on_content_load();
    }
    else {
        $json->{onContentLoad} = _DOES_NOT_APPLY();
    }
    if ( defined $self->on_load() ) {
        $json->{onLoad} = $self->on_load();
    }
    else {
        $json->{onLoad} = _DOES_NOT_APPLY();
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

Archive::Har::Page::PageTimings - Represents detailed timing of page within the HTTP Archive

=head1 VERSION

Version '0.21'

=for stopwords HAR PageTimings undef

=head1 SYNOPSIS

    use Archive::Har();

    my $http_archive_string = '"log": { "version": "1.1", .... ';
    my $har = Archive::Har->new();
    $har->string($http_archive_string);
    foreach my $page ($har->pages()) {
        my $timings = $page->pageTimings();
        $timings->comment("Something interesting here");
	print "onContentLoad for " . $page->title() . ": " . $timings->on_content_load() . "\n";
	print "onLoad for " . $page->title() . ": " . $timings->on_load() . "\n";
        print "Comment for " . $page->title() . ": " . $timings->comment() . "\n";
    }

=head1 DESCRIPTION
 
This Module is intended to provide an interface to create/read/update
PageTimings objects in HTTP Archive (HAR) files.

=head1 SUBROUTINES/METHODS

=head2 new

returns a new PageTimings object

=head2 on_content_load

returns the number of milliseconds since L<$har-E<gt>page()-E<gt>started_date_time()|Archive::Har::Page/"started_date_time"> that the content of the page loaded or undef if the timing does not apply

=head2 on_load

returns the number of milliseconds since L<$har-E<gt>page()-E<gt>started_date_time()|Archive::Har::Page/"started_date_time"> that the page loaded or undef if the timing does not apply

=head2 comment

returns the comment about the page timing

=head1 DIAGNOSTICS

=over

=item C<< on_content_load must be a positive number or -1 >>

This field is measured as a number of milliseconds

=item C<< on_load must be a positive number or -1 >>

This field is measured as a number of milliseconds

=item C<< %s is not specified in the HAR 1.2 spec and does not start with an underscore >>

The HAR 1.2 specification allows undocumented fields, but they must start with an underscore

=back

=head1 CONFIGURATION AND ENVIRONMENT

Archive::Har::Page::PageTimings requires no configuration files or environment variables.  

=head1 DEPENDENCIES

Archive::Har::Page::PageTimings requires no additional non-core Perl modules

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
