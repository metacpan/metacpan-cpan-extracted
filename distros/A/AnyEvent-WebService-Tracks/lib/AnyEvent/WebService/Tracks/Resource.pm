package AnyEvent::WebService::Tracks::Resource;

use strict;
use warnings;

use Carp qw(croak);
use namespace::clean;

our $VERSION = '0.02';

sub readonly {
    my ( $class, @fields ) = @_;

    no strict 'refs';

    foreach my $field (@fields) {
        *{$class . '::' . $field} = sub {
            my $self = shift;

            if(@_) {
                croak "$field is readonly";
            }
            return $self->{$field};
        };
    }
}

sub accessor {
    my ( $class, @fields ) = @_;

    no strict 'refs';

    foreach my $field (@fields) {
        *{$class . '::' . $field} = sub {
            my $self = shift;

            if(@_) {
                $self->{$field} = shift;
                $self->{'_dirty'}{$field} = 1;
            }
            return $self->{$field};
        };
    }
}

sub new {
    my ( $class, %params ) = @_;

    $params{'_dirty'} = {};

    return bless \%params, $class;
}

sub destroy {
    my ( $self, $cb ) = @_;

    $self->{'parent'}->do_delete([$self->resource_path, $self->id . '.xml'], sub {
        return $_[2];
    }, sub {
        my ( $headers ) = @_;

        if($self->{'parent'}->status_successful($headers->{'Status'})) {
            bless $self, 'AnyEvent::WebService::Tracks::DestroyedResource';
            $cb->(1);
        } else {
            $cb->(undef, $headers->{'status'});
        }
    });
}

sub update {
    my ( $self, $cb ) = @_;

    unless(%{$self->{'_dirty'}}) {
        $cb->($self);
        return;
    }

    my $xml = $self->{'parent'}->generate_xml($self->xml_root,
        { map { $_ => $self->{$_} } keys %{$self->{'_dirty'}} });
    my $outer = $xml;

    my $url = [$self->resource_path, $self->id . '.xml'];
    $self->{'parent'}->do_put($url, $xml, sub {
        return @_[1, 2];
    }, sub {
        my ( $xml, $headers ) = @_;
        
        if($self->{'parent'}->status_successful($headers->{'Status'})) {
            if($xml eq 'Success') {
                $self->{'parent'}->do_get($url, sub {
                    return $_[1];
                }, sub {
                    my ( $xml ) = @_;
                    my $other = $self->{'parent'}->parse_single(ref($self), $xml);
                    %$self = %$other;
                    $cb->($self);
                });
            } elsif($xml eq '') {
                $cb->(undef, 'Update failed');
            } else {
                my $other = $self->{'parent'}->parse_single(ref($self), $xml);
                %$self = %$other;
                $cb->($self);
            }
        } else {
            $cb->(undef, $headers->{'status'});
        }
    });
}

1;

__END__

=head1 NAME

AnyEvent::WebService::Tracks::Resource - Generic superclass for Tracks resources

=head1 VERSION

0.02

=head1 DESCRIPTION

AnyEvent::WebService::Tracks::Resource is a generic superclass for Context,
Project, and Todo objects, and provides common methods.

=head1 ACCESSORS

Accessors for resource objects don't actually update the object in Tracks;
calling the update method pushes the changes to the server.

=head1 METHODS

=head2 $resource->destroy($cb)

Destroys the resource in the Tracks installation, and provides either a truthy value
to the callback upon success, or a falsy value and an error message on failure.

=head2 $resource->update($cb)

Submits pending updates to Tracks.  Provides C<$resource> to the callback on
success, or a falsy value and and error message on failure.

=head1 AUTHOR

Rob Hoelz, C<< rob at hoelz.ro >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-AnyEvent-WebService-Tracks at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=AnyEvent-WebService-Tracks>. I will
be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2011 Rob Hoelz.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 SEE ALSO

L<AnyEvent::WebService::Tracks::Context>,
L<AnyEvent::WebService::Tracks::Project>,
L<AnyEvent::WebService::Tracks::Todo>,
L<AnyEvent::WebService::Tracks>

=begin comment

Undocumented methods (for Pod::Coverage)

=over

=item new

=item readonly

=item accessor

=back

=end comment

=cut
