package App::Oozie::Role::Info;

use 5.014;
use strict;
use warnings;

our $VERSION = '0.020'; # VERSION

use namespace::autoclean -except => [qw/_options_data _options_config/];

use Moo::Role;
use Ref::Util qw( is_arrayref );

with qw(
    App::Oozie::Role::Log
);

sub log_versions {
    my $self      = shift;
    my $log_level = shift || 'debug';
    my $me        = ref $self;
    my @classes   = ( [ $me, $self->VERSION ] );

    my $base_class = do {
        no strict qw(refs);
        my @isa =   grep { $_ ne $me }
                    map  {
                        is_arrayref $_ ? @{ $_ } : $_
                    }
                    @{ $me . '::ISA' };
        @isa ? $isa[0] : ();
    };

    if ( $base_class ) {
        push @classes, [ $base_class, $base_class->VERSION ];
    }

    for my $tuple ( @classes ) {
        my($name, $v) = @{ $tuple };
        my $msg = defined $v
                ? sprintf 'Running under %s %s', $name, $v
                : sprintf 'Running under %s', $name
                ;
        $self->logger->$log_level( $msg );
    }

    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Oozie::Role::Info

=head1 VERSION

version 0.020

=head1 SYNOPSIS

    use Moo;
    with qw(
        App::Oozie::Role::Info
    );
    sub method {
        my $self = shift;
        $self->log_versions if $self->verbose;
    }

=head1 DESCRIPTION

Helper to gather information about the tooling.

=head1 NAME

App::Oozie::Role::Info - Helper to gather information about the tooling.

=head1 Methods

=head2 log_versions

=head1 SEE ALSO

L<App::Oozie>.

=head1 AUTHORS

=over 4

=item *

David Morel

=item *

Burak Gursoy

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Booking.com.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
