package BBS::Perm::Plugin::Feed;

use warnings;
use strict;
use Carp;
use Gtk2;
use Glib qw/TRUE FALSE/;
use File::Slurp;
use Encode;

sub new {
    my ( $class, %args ) = @_;
    my $self = {};
    bless $self, ref $class || $class;

    my $entry  = Gtk2::Entry->new;
    my $label  = Gtk2::Label->new_with_mnemonic( $args{label} || '_Feed: ' );
    my $widget = $args{widget} || Gtk2::HBox->new;
    $widget->pack_start( $label, FALSE, FALSE, 0 );
    $widget->pack_start( $entry, TRUE,  TRUE,  0 );
    $entry->signal_connect( changed => sub { $self->_update_store } );
    my $entry_c = Gtk2::EntryCompletion->new;
    $entry->set_completion($entry_c);
    my $store = Gtk2::ListStore->new('Glib::String');

    $entry_c->set_model($store);
    $entry_c->set_text_column(0);
    $entry_c->set_popup_completion(TRUE);
    $entry_c->set_inline_completion(TRUE);
    $self->{entry}    = $entry;
    $self->{label}    = $label;
    $self->{_entry_c} = $entry_c;
    $self->{_store}   = $store;
    $self->{widget}   = $widget;
    return $self;
}

sub _update_store {
    my $self  = shift;
    my $store = $self->{_store};
    my $text  = $self->{entry}->get_text;
    $store->clear;
    if ( $text =~ m{^([^:]*.*/)} ) {
        my $dir = $1;
        my $dh;
        opendir $dh, $1;

        my @names = map { $dir . $_ }
          grep { ( $_ !~ /^\./ ) && ( -d "$dir/$_" || -T "$dir/$_" ) }
          readdir $dh;
        for (@names) {
            my $iter = $store->append;
            $store->set( $iter, 0, $_ );
        }
        closedir $dh;
    }
}

sub text {
    my $self  = shift;
    my $input = $self->entry->get_text;
    my $text;

    my $encoding = 'utf8';    # default is utf8
    if ( $ENV{LLC_ALL} && $ENV{LLC_ALL} =~ /\.(.*)$/ ) {
        $encoding = lc $1;
    }
    elsif ( $ENV{LANG} && $ENV{LANG} =~ /\.(.*)$/ ) {
        $encoding = lc $1;
    }

    if ( $input =~ /^\s*:\s*(.*)/ ) {
        $text = decode $encoding, `$1`;
    }
    elsif ( -f $input ) {
        $text = decode $encoding, read_file($input);
    }
    else {
        carp 'bad input';
    }
    return $text;
}

sub widget {
    return shift->{widget};
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

sub DESTROY { }

1;

__END__

=head1 NAME

BBS::Perm::Plugin::Feed - a feed plugin for BBS::Perm

=head1 SYNOPSIS

    use BBS::Perm::Plugin::Feed;
    my $feed = BBS::Perm::Plugin::Feed->new( label => 'Feed' );
    my $feed_widget = $feed->widget;
    my $text = $feed->text;

=head1 DESCRIPTION

BBS::Perm::Plugin::Feed provides a feed widget for BBS::Perm. 
If the first letter of user input is ':', the input is seemd as a command, and
the command's output will be committed to BBS::Perm::Term's current terminal, else
the user input is seemed as a file path, and the file contents will be
commited to the terminal.

=head1 INTERFACE

=over 4

=item new( label => $label, widget => $widget )

Create a new BBS::Perm::Plugin::Feed object.

$widget is a Gtk2::HBox object, default is a new one.

$label is a string, name it to what you want, default is '_Feed'.

=item text

Get the contents of user's input, it's either a command's output or a file's
contents.

Caveat: command output and file contents are decoded by your system LANG or
LC_ALL setting. So, you'd better update the encoding of your file in 
accordance with your system settings.

=item widget

Get our object's widget. 

=back

=head1 AUTHOR

sunnavy  C<< <sunnavy@gmail.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007-2011, sunnavy C<< <sunnavy@gmail.com> >>. 

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

