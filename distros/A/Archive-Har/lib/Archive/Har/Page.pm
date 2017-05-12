package Archive::Har::Page;

use warnings;
use strict;
use Carp();
use Archive::Har::Page::PageTimings();

our $VERSION = '0.21';

sub new {
    my ( $class, $params ) = @_;
    my $self = {};
    bless $self, $class;
    if ( defined $params ) {
        $self->id( $params->{id} );
        if ( defined $params->{title} ) {
            $self->title( $params->{title} );
        }
        if ( defined $params->{startedDateTime} ) {
            $self->started_date_time( $params->{startedDateTime} );
        }
        $self->page_timings(
            Archive::Har::Page::PageTimings->new(
                $params->{pageTimings} || {}
            )
        );
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

sub id {
    my ( $self, $new ) = @_;
    my $old = $self->{id};
    if ( @_ > 1 ) {
        $self->{id} = $new;
    }
    return $old;
}

sub title {
    my ( $self, $new ) = @_;
    my $old = $self->{title};
    if ( @_ > 1 ) {
        $self->{title} = $new;
    }
    if ( defined $old ) {
        return $old;
    }
    else {
        return;
    }
}

sub started_date_time {
    my ( $self, $new ) = @_;
    my $old = $self->{startedDateTime};
    if ( @_ > 1 ) {
        if ( defined $new ) {
            my $date_regex = qr/\d{4}[-]\d{2}[-]\d{2}/smx;
            my $time_regex = qr/\d{2}:\d{2}:\d{2}[.]\d+/smx;
            my $zone_regex = qr/(?:[+]\d{2}:\d{2}|Z)/smx;
            if ( $new =~ /^${date_regex}T${time_regex}${zone_regex}$/smx ) {
                $self->{startedDateTime} = $new;
            }
            else {
                Carp::croak('started_date_time is not formatted correctly');
            }
        }
        else {
            $self->{startedDateTime} = '0000-00-00T00:00:00.0+00:00';
        }
    }
    if ( ( defined $old ) && ( $old eq '0000-00-00T00:00:00.0+00:00' ) ) {
        return;
    }
    else {
        return $old;
    }
}

sub page_timings {
    my ( $self, $new ) = @_;
    my $old = $self->{pageTimings};
    if ( @_ > 1 ) {
        $self->{pageTimings} = $new;
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

    my $name = $Archive::Har::Page::AUTOLOAD;
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
    my $json = { pageTimings => $self->page_timings(), };
    if ( defined $self->title() ) {
        $json->{title} = $self->title();
    }
    else {
        $json->{title} = 'Unknown';
    }
    if ( defined $self->started_date_time() ) {
        $json->{startedDateTime} = $self->started_date_time();
    }
    else {
        $json->{startedDateTime} = '0000-00-00T00:00:00.0+00:00';
    }
    if ( defined $self->id() ) {
        $json->{id} = $self->id();
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

Archive::Har::Page - Represents a single page inside the HTTP Archive

=head1 VERSION

Version '0.21'

=for stopwords pageref xml gzip HAR gzipped

=head1 SYNOPSIS

    use Archive::Har();

    my $http_archive_string = '"log": { "version": "1.1", .... ';
    my $har = Archive::Har->new();
    $har->string($http_archive_string);
    foreach my $page ($har->pages()) {
        $page->comment("Something interesting here");
        print "DateTime: " . $page->started_date_time() . "\n";
        print "Id: " . $page->id() . "\n";
        print "Title: ". $page->title() . "\n";
        my $timing = $page->page_timings();
        print "Comment: " . $page->comment() . "\n";
    }

=head1 DESCRIPTION
 
This Module is intended to provide an interface to create/read/update
Page objects in HTTP Archive (HAR) files.

=head1 SUBROUTINES/METHODS

=head2 started_date_time

returns the date and time stamp for the beginning of the page load (ISO 8601 format)

=head2 id

returns the unique identifier of a page within the Archive. This is referenced by the L<pageref|Archive::Har::Entry/"pageref"> method of related L<entries|Archive::Har::Entry>

=head2 title

returns the page title

=head2 page_timings

returns the L<page timings|Archive::Har::Page::PageTimings> object

=head2 comment

returns the comment about the Page

=head1 DIAGNOSTICS

=over

=item C<< started_date_time is not formatted correctly >>

The started_date_time field must be formatted like so

0000-00-00T00:00:00.0+00:00

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
