package BBS::Perm;

use 5.008;
use warnings;
use strict;
use Carp;
use Regexp::Common qw/URI/;
use Encode;
use BBS::Perm::Term;
use BBS::Perm::Config;
use UNIVERSAL::require;
use UNIVERSAL::moniker;

our $VERSION = '1.01';

my %component = (
    IP   => 0,
    URI  => 0,
    Feed => 0,
);

sub new {
    my ( $class, %opt ) = @_;
    my $self = {};
    $opt{accel} = 1 unless exists $opt{accel};

    if ( $self->{window} ) {
        if ( ref $self->{window} eq 'Gtk2::Window' ) {
            $self->{window} = $opt{window};
        }
        else {
            croak 'window must be a Gtk2::Window object';
        }
    }
    else {
        $self->{window} = Gtk2::Window->new;
    }

    bless $self, ref $class || $class;

    if ( $opt{config} ) {
        $self->{config} = BBS::Perm::Config->new( %{ $opt{config} } );
    }
    else {
        croak 'BBS::Perm must have config option';
    }

    $self->{term} = BBS::Perm::Term->new( $opt{term} ? %{ $opt{term} } : () );

    for ( keys %component ) {
        if ( $component{$_} ) {
            $_ = 'BBS::Perm::Plugin::' . $_;
            $_->require or die $@;
            my $key = $_->moniker;
            $self->{$key} =
              $_->new( %{ $self->config->setting('global')->{plugins}{$key} },
                defined $opt{$key} ? %{ $opt{$key} } : () );
        }
    }

    if ( $opt{accel} ) {
        $self->_register_accel;
    }

    if ( $component{Feed} ) {
        $self->feed->entry->signal_connect(
            activate => sub {
                my $text = $self->feed->text || q{};
                $text =~ s/(\033)/$1$1/g;    # term itself will eat an escape
                $self->term->term->feed_child_binary(
                    encode $self->term->encoding, $text );
                $self->feed->entry->set_text(q{});
                $self->term->term->grab_focus;
            }
        );
    }

    return $self;
}

sub _clean {                                 # be called when an agent exited
    my $self = shift;
    $self->term->clean;
    if ( $self->term->term ) {
        $self->window->set_title( $self->term->title );
    }
    else {

  #        $self->window->set_title($self->config->setting('global')->{title} ||
  #                'bbs-perm' );
        Gtk2->main_quit;
    }
}

sub _switch {
    my ( $self, $direct ) = @_;
    $self->term->switch($direct);
    $self->window->set_title( $self->term->title );
}

sub _register_accel {
    my $self  = shift;
    my %accel = (
        quit       => 'MW-q',
        copy       => 'MW-c',
        paste      => 'MW-v',
        fullscreen => 'MW-f',
        close_tab  => 'MW-w',
        left_tab   => 'M-[',
        right_tab  => 'M-]',
        feed       => 'M-f',
        $self->config->setting('global')->{shortcuts}
        ? %{ $self->config->setting('global')->{shortcuts} }
        : ()
    );

    my $fullscreen = 0;
    my @accels = (
        [
            $self->_parse_shortcut( $accel{quit} ),
            ['mask'],
            sub { Gtk2->main_quit }
        ],
        [
            $self->_parse_shortcut( $accel{close_tab} ),
            ['mask'],
            sub { $self->term->clean }
        ],
        [
            $self->_parse_shortcut( $accel{copy} ),
            ['mask'],
            sub {
                my $focus = $self->window->get_focus;
                $focus->copy_clipboard if $focus;
              }
        ],
        [
            $self->_parse_shortcut( $accel{paste} ),
            ['mask'],
            sub {
                my $focus = $self->window->get_focus;
                $focus->paste_clipboard if $focus;
              }
        ],
        [
            $self->_parse_shortcut( $accel{fullscreen} ),
            ['mask'],
            sub {
                if ($fullscreen) {
                    $self->window->unfullscreen;
                    $fullscreen = 0;
                }
                else {
                    $self->window->fullscreen;
                    $fullscreen = 1;
                }
              }
        ],
        [
            $self->_parse_shortcut( $accel{left_tab} ),
            ['mask'],
            sub { $self->_switch(-1) }
        ],
        [
            $self->_parse_shortcut( $accel{right_tab} ),
            ['mask'],
            sub { $self->_switch(1) }
        ],
    );

    if ( $component{Feed} ) {
        push @accels, [
            $self->_parse_shortcut( $accel{feed} ),
            ['mask'],
            sub {
                if ( $self->feed->entry->has_focus ) {
                    $self->term->term->grab_focus if $self->term->term;
                }
                else {
                    $self->feed->entry->grab_focus;
                }
            },
        ];
    }

    if ( $component{URI} ) {
        for my $key ( 0 .. 9 ) {
            push @accels, [
                $key,
                ['mod1-mask', 'super-mask'],
                ['mask'],
                sub {
                    my $uri;
                    if ( $key > 0 ) {
                        if ( $key == 9 ) {
                            # 9 means last one
                            $uri = $self->uri->uri->[-1];
                        }
                        else {
                            $uri = $self->uri->uri->[ $key - 1 ];
                        }
                    }

                    $uri ||=
                      $self->config->setting('global')->{plugins}{uri}{default};
                    $self->uri->browse($uri);
                },
            ];
        }
    }

    for my $site ( $self->config->sites ) {
        my $shortcut = $self->config->setting($site)->{shortcut};
        next unless $shortcut;
        push @accels, [
            $self->_parse_shortcut($shortcut),
            ['mask'],
            sub {
                $self->connect($site);
              }
        ];
    }


    my $window = $self->{window};
    my $accel  = Gtk2::AccelGroup->new;
    $accel->connect( ord $_->[0], @$_[ 1 .. 3 ] ) for @accels;
    $window->add_accel_group($accel);
}

sub _parse_shortcut {
    my $self = shift;
    my $str = shift or return;

    my %mask;
    return unless $str =~ /([CMSW]+)-(.)/i;
    my $char = $2;
    for ( split //, $1 ) {
        if (/C/i) {
            $mask{'control-mask'} = 1;
        }
        elsif (/M/i) {
            $mask{'mod1-mask'} = 1;
        }
        elsif (/S/i) {
            $mask{'shift-mask'} = 1;
        }
        elsif (/W/i) {
            $mask{'super-mask'} = 1;
        }
        else {
            warn "invalid mask: $_";
        }
    }
    return ( $char, [ keys %mask ] );
}

sub import {
    my $class = shift;
    my @list  = @_;
    for (@list) {
        if ( defined $component{$_} ) {
            $component{$_} = 1;
        }
    }
}

sub connect {
    my ( $self, $site ) = @_;
    if ( !$site ) {

        # get the default ones
        my $default = $self->config->setting('global')->{default};
        if ($default) {
            for ( ref $default eq 'ARRAY' ? @$default : $default ) {
                $self->connect($_);
            }
        }
        return;
    }

    my $conf = $self->config->setting($site);
    $self->term->init($conf);

    $self->term->term->signal_connect(
        contents_changed => sub {
            $self->_contents_changed;
        },
    );

    $self->term->term->signal_connect( child_exited => sub { $self->_clean } );
    $self->window->set_title( $self->term->title );

    $self->term->connect( $conf, $self->config->file, $site );
}

sub _contents_changed {
    my $self = shift;
    my $text = encode 'utf8', $self->term->text;

    if ( $component{URI} ) {
        $self->uri->clear;    # clean previous uri
        $self->uri->push($1)
          while $text =~ /($RE{URI}{HTTP} | $RE{URI}{FTP})/gx;
    }
    if ( $component{IP} ) {
        $self->ip->clear;     # and ip info.
        $self->ip->add($1) while ( $text =~ /(\d+\.\d+\.\d+\.(?:\d+|\*))/g );
        $self->ip->show;
    }
}

sub AUTOLOAD {
    our $AUTOLOAD;
    no strict 'refs';
    if ( $AUTOLOAD =~ /.*::(.*)/ ) {
        my $element = $1;
        *$AUTOLOAD = sub { return shift->{$element} };
        goto &$AUTOLOAD;
    }

}

# we need this because of AUTOLOAD
sub DESTROY { }

1;

__END__

=head1 NAME

BBS::Perm - a BBS client based on vte

=head1 SYNOPSIS

    use BBS::Perm qw/Feed IP URI/;
    my $perm = BBS::Perm->new(
        perm   => { accel => 1 },
        config => { file   => '.bbs-perm/config.yml' },
        ip => { encoding => 'gbk' }
    );

=head1 DESCRIPTION

C<Perm> means C<Perl> + C<Term> here.

here is a list L<BBS::Perm> can supply:

1. multiple terminals and quickly switch between them.

2. anti-idle

3. commit stuff from file or even command output directly.

4. browse URIs quickly.

5. show information of IPv4 addresses, thanks to L<IP::QQWry>.

6. build your window layout freely.

7. use your own agent script.


Check out bin/bbs-perm and examples/bbspermrc for example.

=head1 INTERFACE

=over 4

=item new ( %opt )

Create a new BBS::Perm object.

%opt is some configuration options:

{ config => $config, $uri => $uri, perm => $perm }

All the values of %opt are hashrefs.

For each component, there can be a configuration pair for it.
perm => $perm is for BBS::Perm itself, where $perm is as follows:

=over 4

=item window => $window

    $window is a Gtk2::Window object, which is your main window.

=item accel => 1 | 0

     use accelerator keys or not, default is 1

=back

=item connect($sitename)

connect to $sitename.

=item config, uri, ip, ...

For each sub component, there's a method with the componnet's last
name(lowcase), so you can get each sub component from a BBS::Perm object.

e.g. $self->config is the BBS::Perm::Config object.

=item window

return the main window object, which is a Gtk2::Window object.

=back

=head1 DEPENDENCIES

L<Gtk2>, L<Regexp::Common>, L<UNIVERSAL::require>, L<UNIVERSAL::moniker>,
L<File::Which>

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

When a terminal is destroyed, if there is a warning like
"gdk_window_invalidate_maybe_recurse: assertion `window != NULL' failed",
please update you vte lib to 0.14 or above, then this bug will be gone.

=head1 AUTHOR

sunnavy  C<< <sunnavy@gmail.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007-2011, sunnavy C<< <sunnavy@gmail.com> >>. 

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

