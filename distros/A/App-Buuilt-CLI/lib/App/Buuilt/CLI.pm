package App::Buuilt::CLI;
use 5.008001;
use strict;
use warnings;

our $VERSION = "0.02";

use Moo;
use EV;
use AnyEvent;
use AnyEvent::Filesys::Notify;
use Archive::Zip;
use Path::Class;

use Mojo::UserAgent;
use Mojo::Asset::File;

sub run {

    my ( $self, @args ) = @_;

    my $action    = shift @args;
    my $directory = shift @args;

    if ( $action eq 'checkout' ) {

        my $dir = dir($directory);

        if ( -e $dir ) {

            print "Error: Checkout directory already exists, please choose a fresh one";

        } else {

            $dir->mkpath;
            $self->checkout($directory);
        }

    } elsif ( $action eq 'watch' ) {

        $self->watch($directory);

    } else {

        print 'Usage: ./buuilt checkout|watch $directory' . "\n\n";

    }
}

sub config {

    return {

        host     => "",
        token    => "",
        theme_id => "",
    };

}

=head2 checkout

    Checkout the whole theme into the given directory

=cut

sub checkout {

    my ( $self, $directory ) = @_;

    my $file = file( $directory, '.buuilt.zip' );
    my $assets   = dir( $directory, 'assets' );
    my $elements = dir( $directory, 'elements' );

    my $config = $self->config();

    my $ua = Mojo::UserAgent->new;

    # Follow redirect
    $ua->max_redirects(5)->get( $config->{host} . "/api/theme/checkout" => $config )->res->content->asset->move_to($file);

    my $zip = Archive::Zip->new();

    $zip->read( $file->stringify );
    $zip->extractTree( 'assets', $assets );

}

=head2 watch

    Watch for changed or new files and directory, upload to cms

=cut

sub watch {

    my ( $self, $directory ) = @_;

    my $config = $self->config();

    my $assets = dir( $directory, 'assets' );

    my $notifier = AnyEvent::Filesys::Notify->new(
        dirs     => [$directory],
        interval => 2.0,                                        # Optional depending on underlying watcher
        filter   => sub { shift !~ /\.(swp|tmp|un~|sw\w)$/ },
        cb       => sub {
            my (@events) = @_;

            foreach my $event (@events) {

                my $dir = dir($directory);

                my $asset = -d $event->path ? dir $event->path : file $event->path;
                my $asset_relative = $asset->relative($assets);

                if ( $event->is_dir ) {

                    if ( $event->is_deleted ) {

                        $self->asset_delete($asset_relative);

                        printf STDERR ( "dir deleted  : %s\n", $asset_relative );
                    }

                } else {

                    if ( $event->is_created ) {

                        $self->asset_put( $asset_relative, $asset );
                        printf STDERR ( "file created :  %s\n", $asset_relative );

                    } elsif ( $event->is_modified ) {

                        $self->asset_put( $asset_relative, $asset );
                        printf STDERR ( "file modified: %s\n", $asset_relative );

                    } elsif ( $event->is_deleted ) {

                        $self->asset_delete($asset_relative);
                        printf STDERR ( "file deleted : %s\n", $asset_relative );
                    }

                }

            }

            # ... process @events ...
        },

        #parse_events => 1,    # Improves efficiency on certain platforms
    );

    # Run unless end
    AnyEvent->condvar->recv;

}

=head2 asset_put

    Put an asset example stylesheets/demo.css
    
=cut

sub asset_put {

    my ( $self, $asset_relative, $asset ) = @_;

    my $config = $self->config();

    my $ua = Mojo::UserAgent->new;
    my $tx = $ua->build_tx( PUT => $config->{host} . '/api/theme/assets/' . $asset_relative => $config );
    $tx->req->content->asset( Mojo::Asset::File->new( path => $asset ) );
    my $txr = $ua->start($tx);

    Mojo::IOLoop->start unless Mojo::IOLoop->is_running;

}

=head2 asset_delete

    Delete an asset, example stylesheet/demo.css

=cut

sub asset_delete {

    my ( $self, $asset_relative ) = @_;

    my $config = $self->config();

    my $ua  = Mojo::UserAgent->new;
    my $tx  = $ua->build_tx( DELETE => $config->{host} . '/api/theme/assets/' . $asset_relative => $config );
    my $txr = $ua->start($tx);

    Mojo::IOLoop->start unless Mojo::IOLoop->is_running;

}

1;
__END__

=encoding utf-8

=head1 NAME

App::Buuilt::CLI - Checkout, watch and upload theme assets for buuilt.it

=head1 SYNOPSIS

    use App::Buuilt::CLI;

=head1 DESCRIPTION

    App::Buuilt::CLI help you edit the assets for a buuilt-theme. You could checkout and watch for changes 


=head1 LICENSE

Copyright (C) Jens Gassmann.

    This library is free software; you can redistribute it and/or modify
    it under the same terms as Perl itself.

=head1 AUTHOR

    Jens Gassmann E<lt>jens.gassmann@atomix.deE<gt>

=cut

