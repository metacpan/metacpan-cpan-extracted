package Beagle::Cmd::Command::unfollow;
use Beagle::Util;

use Any::Moose;
extends qw/Beagle::Cmd::GlobalCommand/;

no Any::Moose;
__PACKAGE__->meta->make_immutable;

sub execute {
    my ( $self, $opt, $args ) = @_;
    die "beagle unfollow name [...]" unless @$args;
    require File::Path;

    my @unfollowed;
    for my $name (@$args) {
        my $all = roots();
        if ( exists $all->{$name} ) {
            delete $all->{$name};
            set_roots($all);
        }
        else {
            die "$name doesn't exist, maybe a typo?";
        }

        my $f_root = catdir( backends_root(), split /\//, $name );
        if ( -e $f_root ) {
            remove_tree($f_root);
        }
        for my $t ( '', '.drafts' ) {
            my $cache =
              encode( locale_fs => catfile( cache_root(), $name . $t ) );
            remove_tree($cache) if -e $cache;
        }
        my $map = relation;
        for my $id ( keys %$map ) {
            delete $map->{$id} if $map->{$id} eq $name;
        }
        set_relation( $map );

        push @unfollowed, $name;
    }

    puts "unfollowed ", join( ', ', @unfollowed ), '.';
}


1;

__END__

=head1 NAME

Beagle::Cmd::Command::unfollow - unfollow beagles

=head1 SYNOPSIS

    $ beagle unfollow foo bar

=head1 AUTHOR

    sunnavy <sunnavy@gmail.com>


=head1 LICENCE AND COPYRIGHT

    Copyright 2011 sunnavy@gmail.com

    This program is free software; you can redistribute it and/or modify it
    under the same terms as Perl itself.

