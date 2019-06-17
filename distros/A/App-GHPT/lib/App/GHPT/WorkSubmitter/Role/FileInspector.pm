package App::GHPT::WorkSubmitter::Role::FileInspector;

use App::GHPT::Wrapper::OurMoose::Role;

our $VERSION = '1.000012';

use IPC::Run3 qw( run3 );

sub file_contents ( $self, $path ) {
    state %cache;
    return $cache{$path} if exists $cache{$path};

    my @command = (
        'git',
        'show',
        "HEAD:$path",
    );

    run3 \@command, \undef, \my $output, \my $error;
    if ( $error || $? ) {
        die join q{ }, 'Problem running git show', @command, $error, $?;
    }

    $cache{$path} = $output;

    return $output;
}

1;

# ABSTRACT: Role for examining the committed version of the file

__END__

=pod

=encoding UTF-8

=head1 NAME

App::GHPT::WorkSubmitter::Role::FileInspector - Role for examining the committed version of the file

=head1 VERSION

version 1.000012

=head1 SUPPORT

Bugs may be submitted through L<https://github.com/maxmind/App-GHPT/issues>.

=head1 AUTHORS

=over 4

=item *

Mark Fowler <mark@twoshortplanks.com>

=item *

Dave Rolsky <autarch@urth.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by MaxMind, Inc.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
