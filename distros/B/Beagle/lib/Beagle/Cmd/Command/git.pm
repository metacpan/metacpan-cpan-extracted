package Beagle::Cmd::Command::git;
use Beagle::Util;
use Any::Moose;
extends qw/Beagle::Cmd::Command/;

has all => (
    isa           => 'Bool',
    is            => 'rw',
    cmd_aliases   => 'a',
    documentation => 'all',
    traits        => ['Getopt'],
);

has 'names' => (
    isa           => 'Str',
    is            => 'rw',
    documentation => 'names of beagles',
    traits        => ['Getopt'],
);

no Any::Moose;
__PACKAGE__->meta->make_immutable;

sub execute {
    my ( $self, $opt, $args ) = @_;

    my $cmd = shift @$args;
    die "beagle git cmd ..." unless $cmd;

    my @roots;

    if ( $self->all ) {
        my $all = roots();
        for my $name ( keys %$all ) {
            next unless $all->{$name}{type} && $all->{$name}{type} eq 'git';
            if ( $all->{$name}{local} && $all->{$name}{remote} ) {
                push @roots, $all->{$name}{local};
            }
        }
    }
    elsif ( $self->names ) {
        my $all = roots();
        for my $name ( @{to_array($self->names)} ) {
            next
              unless $all->{$name}
                  && $all->{$name}{type}
                  && $all->{$name}{type} eq 'git';
            if ( $all->{$name}{local} && $all->{$name}{remote} ) {
                push @roots, $all->{$name}{local};
            }
        }
    }
    else {
        my $root = current_root();
        die "$root is not of type git" unless root_type($root) eq 'git';

        @roots = $root;
    }

    if ( !@roots ) {
        die "please specify beagle by --name or --root";
    }

    $cmd =~ s!-!_!g;
    require Beagle::Wrapper::git;

    my $first = 1;
    for my $root (@roots) {
        puts '=' x term_width() unless $first;
        undef $first if $first;

        my $git = Beagle::Wrapper::git->new(
            root    => $root,
            verbose => $self->verbose,
        );
        puts root_name($root) . ':' unless @roots == 1;
        my ( $ret, $out ) = $git->$cmd(@$args);
        print $out if $ret;
    }
}


1;

__END__

=head1 NAME

Beagle::Cmd::Command::git - bridge to git

=head1 SYNOPSIS

    $ beagle git status
    $ beagle git log
    $ beagle git <any git cmd>

=head1 AUTHOR

    sunnavy <sunnavy@gmail.com>


=head1 LICENCE AND COPYRIGHT

    Copyright 2011 sunnavy@gmail.com

    This program is free software; you can redistribute it and/or modify it
    under the same terms as Perl itself.

