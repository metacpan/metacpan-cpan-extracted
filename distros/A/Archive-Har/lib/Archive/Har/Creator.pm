package Archive::Har::Creator;

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
        $self->version( $params->{version} );
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
        if ( defined $new ) {
            $self->{name} = $new;
        }
        else {
            $self->{name} = 'Unknown';
        }
    }
    if ( ( defined $old ) && ( $old eq 'Unknown' ) ) {
        return;
    }
    else {
        return $old;
    }
}

sub version {
    my ( $self, $new ) = @_;
    my $old = $self->{version};
    if ( @_ > 1 ) {
        if ( defined $new ) {
            $self->{version} = $new;
        }
        else {
            $self->{version} = 'Unknown';
        }
    }
    if ( ( defined $old ) && ( $old eq 'Unknown' ) ) {
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

    my $name = $Archive::Har::Creator::AUTOLOAD;
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
    if ( defined $self->name() ) {
        $json->{name} = $self->name();
    }
    else {
        $json->{name} = 'Unknown';
    }
    if ( defined $self->version() ) {
        $json->{version} = $self->version();
    }
    else {
        $json->{version} = 'Unknown';
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

Archive::Har::Creator - Represents the creator (software) of the HTTP Archive

=head1 VERSION

Version '0.21'

=for stopwords HAR

=head1 SYNOPSIS

    use Archive::Har();

    my $http_archive_string = '"log": { "version": "1.1", .... ';
    my $har = Archive::Har->new();
    $har->string($http_archive_string);
    $har->creator()->comment("Something interesting here");
    print "Name: " . $har->creator()->name() . "\n";
    print "Version: " . $har->creator()->version() . "\n";
    print "Comment: " . $har->creator()->comment() . "\n";

=head1 DESCRIPTION
 
This Module is intended to provide an interface to create/read/update
Creator objects in HTTP Archive (HAR) files.

=head1 SUBROUTINES/METHODS

=head2 new

returns a new Creator object

=head2 name

returns the name of the Creator

=head2 version

returns the version of the Creator

=head2 comment

returns the comment about the Creator

=head1 DIAGNOSTICS

=over

=item C<< %s is not specified in the HAR 1.2 spec and does not start with an underscore >>

The HAR 1.2 specification allows undocumented fields, but they must start with an underscore

=back

=head1 CONFIGURATION AND ENVIRONMENT

Archive::Har::Creator requires no configuration files or environment variables.  

=head1 DEPENDENCIES

Archive::Har::Creator requires no additional non-core Perl modules

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
