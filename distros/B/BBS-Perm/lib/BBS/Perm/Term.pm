package BBS::Perm::Term;

use warnings;
use strict;
use Carp;
use Glib qw/TRUE FALSE/;
use Gnome2::Vte;
use File::Spec::Functions 'file_name_is_absolute';

sub new {
    my ( $class, %opt ) = @_;
    my $self = {%opt};
    $self->{widget}   = Gtk2::HBox->new unless $self->{widget};
    $self->{terms}    = [];
    $self->{titles}   = [];
    $self->{encoding} = [];
    bless $self, ref $class || $class;
}

sub init {    # initiate a new term
    my ( $self, $conf ) = @_;
    my $term = Gnome2::Vte::Terminal->new;
    push @{ $self->{terms} },  $term;
    push @{ $self->{titles} }, $conf->{title}
      || $conf->{username} . '@' . $conf->{site};
    push @{ $self->{encoding} }, $conf->{encoding};

    if ( defined $self->{current} ) {    # has term already?
        $self->term->hide;
    }

    $self->{current} = $#{ $self->{terms} };
    $self->widget->pack_start( $self->term, TRUE, TRUE, 0 );
    $self->term->show;
    $self->term->grab_focus;

    if ( $conf->{encoding} ) {
        $term->set_encoding( $conf->{encoding} );
    }

    if ( $conf->{font} ) {
        my $font = Pango::FontDescription->from_string( $conf->{font} );
        $term->set_font($font);
    }

    if ( $conf->{color} ) {
        my @elements = qw/foreground background dim bold cursor highlight/;
        for (@elements) {
            if ( $conf->{color}{$_} ) {
                no strict 'refs';
                "Gnome2::Vte::Terminal::set_color_$_"->(
                    $term, Gtk2::Gdk::Color->parse( $conf->{color}{$_} )
                );
            }
        }
    }

    if ( $conf->{background_file} && -e $conf->{background_file} ) {
        $term->set_background_image_file( $conf->{background_file} );
    }

    if ( $conf->{background_transparent} ) {
        $term->set_background_transparent(1);
    }

    if ( defined $conf->{opacity} ) {
        $conf->{opacity} *= 65535 if $conf->{opacity} <= 1;
        $term->set_opacity($conf->{opacity});
    }

    if ( defined $conf->{mouse_autohide} ) {
        $term->set_mouse_autohide( $conf->{mouse_autohide} );
    }

    my $timeout = defined $conf->{timeout} ? $conf->{timeout} : 60;
    if ($timeout) {
        $term->{timer} = Glib::Timeout->add( 1000 * $timeout,
            sub { $term->feed_child( chr 0 ); return TRUE; }, $term );
    }
}

sub clean {    # called when child exited
    my $self = shift;
    my ( $current, $new_pos );
    $new_pos = $current = $self->{current};
    if ( @{ $self->{terms} } > 1 ) {
        if ( $current == @{ $self->{terms} } - 1 ) {
            $new_pos = 0;
        }
        else {
            $new_pos++;
        }
        $self->term->hide;
        $self->{terms}->[$new_pos]->show;
        $self->{terms}->[$new_pos]->grab_focus;
    }
    else {
        undef $new_pos;
    }
    $self->widget->remove( $self->term );
    $self->term->destroy;
    splice @{ $self->{terms} }, $current, 1;
    $self->{current} = $new_pos == 0 ? 0 : $new_pos - 1
      if defined $new_pos;
}

sub term {    # get current terminal
    my $self = shift;
    return $self->{terms}->[ $self->{current} ]
      if defined $self->{current};
}

sub switch {    # switch terms, -1 for left, 1 for right
    my ( $self, $offset ) = @_;
    return unless $offset;
    return unless @{ $self->{terms} } > 1;

    my ( $current, $new_pos );
    $new_pos = $current = $self->{current};

    if ( $offset == 1 ) {
        if ( $current >= @{ $self->{terms} } - 1 ) {
            $new_pos = 0;
        }
        else {
            $new_pos++;
        }
    }
    elsif ( $offset == -1 ) {
        if ( $current == 0 ) {
            $new_pos = @{ $self->{terms} } - 1;
        }
        else {
            $new_pos--;
        }
    }
    $self->term->hide if defined $self->term;
    $self->{current} = $new_pos;
    if ( $self->term ) {
        $self->term->show;
        $self->term->grab_focus;
    }
}

sub connect {
    my ( $self, $conf, $file, $site ) = @_;
    my $agent = $conf->{agent} || $self->{agent};

    # check if it's a perl script
    my $use_current_perl;

    unless ( file_name_is_absolute( $agent ) ) {
        require File::Which;
        my $path = File::Which::which( $agent );
        if ( $path ) {
            $agent = $path;
        }
        else {
            die "can't find $agent";
        }
    }

    if ( -T $agent ) {
        open my $fh, '<', $agent or die "can't open $agent: $!";
        my $shebang = <$fh>;
        if ( $shebang =~ m{#!/usr/bin/(?:perl|env\s+perl)} ) {
            $use_current_perl = 1;
        }
    }
    elsif ( !-e $agent ) {
        die "$agent doesn't exist";
    }

    if ($agent) {
        $self->term->fork_command(
            ( $use_current_perl ? $^X : $agent ),
            (
                [
                    ( $use_current_perl ? ($^X) : () ),
                    $agent,
                    $conf->{protocol} =~ /ssh|telnet/ ? ( $file, $site ) : ()
                ]
            ),
            undef, q{}, FALSE, FALSE, FALSE
        );
    }
    else {
        croak 'seems something wrong with your agent script';
    }
}

sub title {
    my $self = shift;
    return $self->{titles}[ $self->{current} ];
}

sub encoding {
    my $self = shift;
    return $self->{encoding}[ $self->{current} ];
}

sub text {    # get current terminal's text
              # list context is needed.
    my $self = shift;
    if ( $self->term ) {
        my ($text) = $self->term->get_text( sub { return TRUE } );
        return $text;
    }
}

sub widget {
    return shift->{widget};
}

1;

__END__

=head1 NAME

BBS::Perm::Term - a multi-terminals component based on Vte for BBS::Perm

=head1 SYNOPSIS

    use BBS::Perm::Term;
    my $term = BBS::Perm::Term->new;

=head1 DESCRIPTION
    
L<BBS::Perm::Term> is a Gnome2::Vte based terminal, mainly for BBS::Perm.
In fact, it's a transperant wrapper to Gnome2::Vte.

=head1 INTERFACE

=over 4

=item new( agent => $agent, widget => $widget )

create a new BBS::Perm::Term object.

$widget is a Gtk2::HBox or Gtk2::VBox object, which will be the
container of our terminals, default is a new Gtk2::HBox object.

$agent designate our agent script, default is 'bbs-perm-agent'. 

$agent will be called as "$agent $file $sitename",
where $file and $sitename have the same meanings as BBS::Perm::Config's,
so our script can get enough information by these two arguments.

=item term

return the current terminal, which is a Gnome2::Vte::Terminal object, so you can
do anything a Gnome2::Vte::Terminal object can do, ;-)

=item init( $conf )

initiate the terminal to be our `current' terminal. 
$conf is the same as the return value of BBS::Perm::Config object's
setting method.

=item connect

let the current terminal connect to the BBS server.

=item switch( $direction )

our object could have many Gnome2::Vte::Terminal objects, this method help us
switch among them, choosing some as the current terminal.
-1 for left, 1 for right.

=item title

get current terminal's title.

=item encoding

get current terminal's encoding.

=item text

get current terminal's text. ( just plain text, not a colorful one, ;-)

=item clean

when an agent script exited, this method will be call, for cleaning, of cause.

=back

=head1 AUTHOR

sunnavy  C<< <sunnavy@gmail.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007-2011, sunnavy C<< <sunnavy@gmail.com> >>. 

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

