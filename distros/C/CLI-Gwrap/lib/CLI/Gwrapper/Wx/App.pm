#===============================================================================
#
#      PODNAME:  CLI::Gwrapper::Wx::App
#     ABSTRACT:  Wx::App for CLI::Gwrap
#
#       AUTHOR:  Reid Augustin
#        EMAIL:  reid@LucidPort.com
#      CREATED:  07/08/2013 12:08:30 PM
#===============================================================================

package CLI::Gwrapper::Wx::App;
use 5.008;
use strict;
use warnings;

use Moo 1.000;
use Types::Standard qw( Str InstanceOf );
# use MooseX::NonMoose;
# Help with combining Moose and Wx was found at http://cl.ly/197f818fd93974d07d60
use Wx;
extends 'Wx::App';
use Carp;

our $VERSION = '0.030'; # VERSION

has frame => (
    is       => 'ro',
    isa      => InstanceOf['Wx::Frame'],
    builder  => '_frame_builder',
    lazy     => 1,
);
has panel => (
    is       => 'ro',
    isa      => InstanceOf['Wx::Panel'],
);
has title => (
    is      => 'rw',
    isa     => Str,
    default => 'Gwrap Frame',
    trigger => sub {
        my ($self, $title) = @_;
        $self->frame->SetTitle($title);
    }
);


# Convert Moose-style constructor args to Wx::App constructor args
sub FOREIGNBUILDARGS {
    return;     # Wx::App constructor takes no arguments.
}

# we must provide an OnInit method to set up the Wx::App object
sub OnInit {
    my ($self) = @_;

    croak("frame not built\n") if (not defined $self->frame);
    return 1;   # true validates success
}

sub _frame_builder {
    my ($self) = @_;

    my $frame = Wx::Frame->new(
        undef,      # parent window - this is the top-level window
        -1,         # no window ID
        '??',       # $self->title isn't created yet
    );

    $self->{panel} = Wx::Panel->new(
        $frame,     # parent
        -1,         # no window ID
    );
    return $frame;
}

#__PACKAGE__->meta->make_immutable;  !! Don't do this for Wx::App !!

1;



=pod

=head1 NAME

CLI::Gwrapper::Wx::App - Wx::App for CLI::Gwrap

=head1 VERSION

version 0.030

=head1 DESCRIPTION

CLI::Gwrapper::Wx::App provides a Moo(se) Wx::App class for a CLI::Gwrap
graphics plugin.

=head1 SEE ALSO

CLI::Gwrap

=head1 AUTHOR

Reid Augustin <reid@hellosix.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Reid Augustin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__


