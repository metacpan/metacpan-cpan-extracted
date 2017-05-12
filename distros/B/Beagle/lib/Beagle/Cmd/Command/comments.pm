package Beagle::Cmd::Command::comments;
use Any::Moose;
use Beagle::Util;

extends qw/Beagle::Cmd::Command::ls/;

has 'parent' => (
    isa           => 'Str',
    is            => 'rw',
    documentation => 'parent id',
    cmd_aliases   => 'p',
    traits        => ['Getopt'],
);

override '_prepare' => sub {
    my $self = shift;
    $self->type('comment');
    return super;
};

override 'filter' => sub {
    my $self  = shift;
    my @found = super;
    my $pid   = $self->parent;
    return @found unless defined $pid;
    my @ret = resolve_entry( $pid, handle => current_handle() || undef );
    unless (@ret) {
        @ret = resolve_entry($pid) or die_entry_not_found($pid);
    }
    die_entry_ambiguous( $pid, @ret ) unless @ret == 1;

    my $id = $ret[0]->{id};
    return grep { $_->parent_id eq $id } @found;
};

sub command_names { 'comments' };


no Any::Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Beagle::Cmd::Command::comments - list comments

=head1 SYNOPSIS

    $ beagle comments
    $ beagle comments --parent id1 

=head1 AUTHOR

    sunnavy <sunnavy@gmail.com>


=head1 LICENCE AND COPYRIGHT

    Copyright 2011 sunnavy@gmail.com

    This program is free software; you can redistribute it and/or modify it
    under the same terms as Perl itself.

