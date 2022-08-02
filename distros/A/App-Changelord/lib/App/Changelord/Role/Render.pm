package App::Changelord::Role::Render;
our $AUTHORITY = 'cpan:YANICK';
$App::Changelord::Role::Render::VERSION = 'v0.0.1';
use v5.36.0;

use Moo::Role;

use List::AllUtils qw/ pairmap partition_by /;

sub render_header ($self) {

    my $output = "# Changelog";

    my $name = $self->changelog->{project}{name};

    my %links = ();

    if ( $self->changelog->{project}{homepage} ) {
        $name = "[$name][homepage]";
        $links{homepage} = $self->changelog->{project}{homepage};
    }

    $output .= " for $name" if $name;

    if (%links) {
        $output .= "\n\n";
        $output .= $self->render_refs(%links);
    }

    $output .= "\n\n";

}

sub render_refs ( $self, %links ) {
    my $output = '';

    for my $ref ( sort keys %links ) {
        $output .= "    [$ref]: $links{$ref}\n";
    }

    return $output . "\n";
}

sub as_markdown ($self, $with_next = 1) {
    my $changelog = $self->changelog;

    my $output = $self->render_header;

    my $n = 0;
    $output .= join "\n",
      map { $self->render_release( $_, $n++ ) }
      grep {
          $with_next ? 1 : ( $_->{version} && $_->{version} ne 'NEXT' )
      }
      $changelog->{releases}->@*;

    return $output;
}

sub render_release ( $self, $release, $n = 0 ) {

    # it's a string? Okay then!
    return $release unless ref $release;

    my $version = $release->{version} || ( $n ? '???' : 'NEXT' );
    my $date    = $release->{date};

    my $output = '';

    $output .= "## $version";
    $output .= ", $date" if $date;

    $output .= "\n";

    if ( $release->{changes} ) {
        my @changes =
          map { ref ? $_ : { desc => $_ } } $release->{changes}->@*;

        my @keywords = map { $_->{keywords}->@* } $self->change_types->@*;

        # find the generics
        my @generics = grep {
            my $type = $_->{type};

            my $res = !$type;

            if ( $type and not grep { $type eq $_ } @keywords ) {
                $res = 1;
                warn "change type '$type' is not recognized\n";
            }
            $res;
        } @changes;

        $output .= "\n" if @generics;
        $output .= join '', map { $self->render_change($_) } @generics;

        my %keyword_mapping = map {
            my $title = $_->{title};
            map { $_ => $title } $_->{keywords}->@*;
        } $self->change_types->@*;

        my %groups = partition_by {
            no warnings qw/ uninitialized /;
            $keyword_mapping{ $_->{type} } || ''
        }
        @changes;

        for my $type ( $self->change_types->@* ) {
            my $c = $groups{ $type->{title} } or next;
            $output .= "\n### $type->{title}\n\n";
            $output .= $self->render_change($_) for $c->@*;
        }
    }

    my $links = '';
    $output =~ s/(\n  \[.*?\]: .*?)\n/$links .= $1;''/gem;

    return $output . $links . "\n";
}

sub render_change ( $self, $change ) {
    my $out = "  * " . $change->{desc};

    my $link = "";

    if ( $change->{ticket} ) {
        $out .= " [$change->{ticket}]";
        if ( $self->changelog->{project}{ticket_url} ) {
            local $_ = $change->{ticket};
            eval $self->changelog->{project}{ticket_url};
            warn $@ if $@;
            if ($_) {
                $link = "  [$change->{ticket}]: $_";
                $out .= "\n\n$link";
            }
        }
    }

    return $out . "\n";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Changelord::Role::Render

=head1 VERSION

version v0.0.1

=head1 AUTHOR

Yanick Champoux <yanick@babyl.ca>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
