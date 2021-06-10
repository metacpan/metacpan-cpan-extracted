package App::Dex;
use Moo;
use List::Util qw( first );
use YAML::PP qw( LoadFile );
use IPC::Run3;

our $VERSION = '0.002000';

has config_file => (
    is      => 'ro',
    isa     => sub { die 'Config file not found' unless $_[0] && -e $_[0] },
    lazy    => 1,
    default => sub {
        first { -e $_ } @{shift->config_file_names};
    },
);

has config_file_names => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        return [ qw( dex.yaml .dex.yaml ) ],
    },
);

has config => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        LoadFile shift->config_file;
    },
);

has menu => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ( $self ) = @_;
        return [ $self->_menu_data( $self->config, 0 ) ];
    }
);

sub _menu_data {
    my ( $self, $config, $depth ) = @_;

    my @menu;
    foreach my $block ( @{$config} ) {
        push @menu, {
            name  => $block->{name},
            desc  => $block->{desc},
            depth => $depth,
        };
        if ( $block->{children} ) {
            push @menu, $self->_menu_data($block->{children}, $depth + 1);

        }
    }
    return @menu;
}

sub display_menu {
    my ( $self, $menu ) = @_;

    $menu = $self->menu unless $menu;

    foreach my $item ( @{$menu} ) {
        printf( "%s%-24s: %s\n", " " x ( 4 * $item->{depth} ), $item->{name}, $item->{desc}  );
    }
}

sub resolve_block {
    my ( $self, $path ) = @_;

    return $self->_resolve_block( $path, $self->config );
}

sub _resolve_block {
    my ( $self, $path, $config ) = @_;

    my $block;
    while ( defined ( my $segment = shift @{$path} ) ) {
        $block = first { $_->{name} eq $segment } @{$config};

        die "There is no such command.\n"
            unless $block;

        if ( @{$path} ) {
            $config = $block->{children};
            next;
        }
    }
    return $block;
}

sub process_block {
    my ( $self, $block ) = @_;

    if ( $block->{shell} ) {
        _run_block_shell( $block );
    }
}

sub _run_block_shell {
    my ( $block ) = @_;

    foreach my $command ( @{$block->{shell}} ) {
        run3( $command );
    }
}

1;

__END__

=encoding utf8

=head1 NAME

App::dex - Directory Execute

=head1 DESCRIPTION

B<dex> provides a command line utility for managing directory-specific commands.

=head1 USAGE

=head1 DEX FILE SPECIFICATION

=head1 AUTHOR

Kaitlyn Parkhurst (SymKat) I<E<lt>symkat@symkat.comE<gt>> ( Blog: L<http://symkat.com/> )

=head1 CONTRIBUTORS

=head1 SPONSORS

=head1 COPYRIGHT

Copyright (c) 2019 the App::dex L</AUTHOR>, L</CONTRIBUTORS>, and L</SPONSORS> as listed above.

=head1 LICENSE

This library is free software and may be distributed under the same terms as perl itself.

=head2 AVAILABILITY

The most current version of App::dec can be found at L<https://github.com/symkat/App-dex>
