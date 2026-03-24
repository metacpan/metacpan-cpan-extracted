# ABSTRACT: Lock management via Git refs

package App::karr::Lock;
our $VERSION = '0.102';
use strict;
use warnings;


sub new {
    my ( $class, %args ) = @_;
    my $git = $args{git};
    unless ($git) {
        require App::karr::Git;
        $git = App::karr::Git->new( dir => $args{dir} // '.' );
    }
    return bless {
        git     => $git,
        task_id => $args{task_id},
    }, $class;
}

sub task_id { shift->{task_id} }
sub git     { shift->{git} }

sub ref_name {
    my ( $self, $task_id ) = @_;
    $task_id //= $self->task_id;
    return "refs/karr/tasks/$task_id/lock";
}

sub get {
    my ( $self, $task_id ) = @_;
    my $ref = $self->ref_name($task_id);
    my $content = $self->git->read_ref($ref);
    return $content;
}

sub acquire {
    my ( $self, $task_id, $email ) = @_;
    $task_id //= $self->task_id;
    my $ref = $self->ref_name($task_id);

    my $current = $self->get($task_id);
    if ( $current && $current ne $email ) {
        return ( 0, "locked by $current" );
    }

    $self->git->write_ref( $ref, $email );
    return ( 1, "acquired" );
}

sub release {
    my ( $self, $task_id, $email ) = @_;
    $task_id //= $self->task_id;
    my $ref = $self->ref_name($task_id);

    my $current = $self->get($task_id);
    if ( $current && $current ne $email ) {
        return ( 0, "locked by $current" );
    }

    $self->git->delete_ref($ref);
    return ( 1, "released" );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::karr::Lock - Lock management via Git refs

=head1 VERSION

version 0.102

=head1 SYNOPSIS

    my $lock = App::karr::Lock->new(git => $git);
    my ($ok, $msg) = $lock->acquire(12, 'agent@example.com');

=head1 DESCRIPTION

L<App::karr::Lock> manages lightweight per-task locks stored in Git refs. It is
used by commands such as C<karr pick> to avoid concurrent agents selecting the
same task at the same time.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-app-karr/issues>.

=head2 IRC

Join C<#ai> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
