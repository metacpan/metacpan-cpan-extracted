package App::CPANCoverBadge;

# ABSTRACT: Get badge for cpancover

use v5.20;

use strict;
use warnings;

our $VERSION = 0.04;

use Badge::Simple ();
use File::HomeDir;
use Mojo::File;
use Mojo::SQLite;
use Mojo::UserAgent;
use Types::Dist;

use Mojo::Base -base, -signatures;

has sql     => \&_connect_db;
has ua      => sub { Mojo::UserAgent->new };
has db_file => sub {
    my $db_file = Mojo::File->new(
        File::HomeDir->my_home,
        'cpancover_badges.db'
    )->to_string;
};

sub badge ($self, $dist) {
    my $db     = $self->sql->db;
    my $select = q~SELECT badge FROM badges WHERE dist = ?~;
    my $result = $db->query( $select, $dist )->hash // {};
    my $badge  = $result->{badge};

    return $badge if $badge;

    my $rating = $self->_get_cpancover_rating( $dist ) // 'unknown';
    my $color  = $rating eq 'unknown' ?
        '#cccccc' :                       # gray
            $rating < 75 ?
            '#ff9999' :                   # red
                $rating < 90 ?
                '#ffcc99' :               # orange
                    $rating < 100 ?
                    '#ffff99' :           # yellow
                    '#99ff99';            # green

    my $default_font = Mojo::File->new( $INC{"Badge/Simple.pm"} )
        ->sibling('Simple', 'DejaVuSans.ttf')->to_string;

    my $font = $ENV{BADGE_FONT};
    $font    = $default_font if !$font;

    my $svg = Badge::Simple::badge(
        left  => 'CPANCover',
        right => $rating,
        color => $color,
        font  => $font,
    )->toString;

    $db->insert('badges', { dist => $dist, badge => $svg } );

    return $svg;
}

sub _get_cpancover_rating ($self, $dist) {
    my $url = sprintf "http://cpancover.com/latest/%s/index.html", $dist;
    my $tx  = $self->ua->get( $url );

    return if $tx->res->code != 200;

    my $rating = $tx->res->dom->find('#coverage_table>tfoot>tr.Total>td')->last->text;
    $rating =~ s{\A\s+}{};
    $rating =~ s{\s+\z}{};

    return $rating;
}

sub _connect_db ( $self ) {
    my $db = Mojo::SQLite->new( 'sqlite:' . $self->db_file );
 
    $db->migrations->name('badges_table')->from_string(<<'    EOF')->migrate;
    -- 1 up
        CREATE TABLE badges (
            dist VARCHAR(255) NOT NULL,
            badge TEXT,
            PRIMARY KEY (dist)
        );
    -- 1 down
        DROP TABLE badges
    EOF

    return $db;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::CPANCoverBadge - Get badge for cpancover

=head1 VERSION

version 0.04

=head1 SYNOPSIS

    use App::CPANCoverBadge;

    my $badger = App::CPANCoverBadge->new;
    my $badge  = $badger->badge( 'App-CPANCoverBadge-0.01' );
    
    say $badge;

=head1 ATTRIBUTES

=over 4

=item * db_file

=item * sql

=item * ua

=back

=head1 METHODS

=head2 badge

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
