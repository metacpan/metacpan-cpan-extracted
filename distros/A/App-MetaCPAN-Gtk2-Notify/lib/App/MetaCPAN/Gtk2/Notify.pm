package App::MetaCPAN::Gtk2::Notify;

use 5.006;
use strict;
use warnings;
our $VERSION = '0.05';

use JSON;
use LWP::UserAgent;
use Gtk2::Notify;
use File::Temp ();
use File::Spec;
use File::Slurp qw(write_file);

=head1 NAME

App::MetaCPAN::Gtk2::Notify - Notify about recent modules uploaded to CPAN

=head1 SYNOPSIS

    use App::MetaCPAN::Gtk2::Notify;

    App::MetaCPAN::Gtk2::Notify->run;

=head1 METHODS

=cut

my $search_url = 'http://api.metacpan.org/v0/release/_search';
my $post_data  = JSON::encode_json(
    {
        'size' => 20,
        'from' => 0,
        'sort' => [ { 'date' => { 'order' => 'desc', }, }, ],
        'query'  => { match_all => {} },
        'fields' => [qw(name author id)],
    }
);

my $ua = LWP::UserAgent->new(agent => "MetaCPAN Notify/$VERSION");

=head2 run

This starts notifier.

=cut

my %prev_id;

sub run {
    my ( $class, %params ) = @_;
    $prev_id{1} = 1 if $params{debug};
    while (1) {
        my @recent = get_recent();
        show_recent( \@recent ) if @recent;
        sleep 300;
    }
}

=head2 get_recent

Get list of 20 latest recent modules from MetaCPAN. Returns reference to array
of hashes. Each hash contain keys: author, name, id.

=cut

sub get_recent {
    my $resp = $ua->post( $search_url, Content => $post_data );
    if ( $resp->is_success ) {
        my $res = JSON::decode_json( $resp->content );
        return map { $_->{fields} } @{ $res->{hits}{hits} };
    }
    else {
        warn "Can't fetch recent modules from MetaCPAN: ", $resp->message;
        return;
    }
}

=head2 show_recent(\@recent)

Show notifications about recent packages

=cut

sub show_recent {
    my $recent = shift;

    # skip notifying on a first run
    if (%prev_id) {
        Gtk2::Notify->init('MetaCPAN_recent');
        for ( reverse @$recent ) {
            next if $prev_id{ $_->{id} };
            my ( $auth_name, $avatar ) = @{ get_author( $_->{author} ) };
            my $url = "https://metacpan.org/release/$_->{author}/$_->{name}";
            Gtk2::Notify->new( "$auth_name ($_->{author})", "uploaded <a href='$url'>$_->{name}</a>", $avatar || () )
              ->show;
        }
        Gtk2::Notify->uninit;
    }
    %prev_id = map { $_ => 1 } map { $_->{id} } @$recent;
}

my %authors;
my $tmpdir = File::Temp->newdir;

=head2 get_author($cpan_id)

Return author name by cpan_id

=cut

sub get_author {
    my $author = shift;
    unless ( $authors{$author} ) {
        my $resp = $ua->get("http://api.metacpan.org/v0/author/$author");
        if ( $resp->is_success ) {
            my $res         = JSON::decode_json( $resp->content );
            my $avatar      = $ua->get( $res->{gravatar_url} );
            my $avatar_file = File::Spec->catfile( $tmpdir, "$author.jpg" );
            if ( $avatar->is_success ) {
                write_file( $avatar_file, $avatar->content );
                $avatar_file = "$avatar_file";
            }
            else {
                $avatar_file = undef;
            }
            $authors{$author} = [ $res->{name}, $avatar_file ];
        }
        else {
            $authors{$author} = [ " ", undef ];
        }
    }
    return $authors{$author};
}

1;

=head1 AUTHOR

Pavel Shaydo, C<< <zwon at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Pavel Shaydo.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut
