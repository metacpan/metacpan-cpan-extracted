package Beagle::Cmd::Command::which;
use Beagle::Util;
use Any::Moose;

extends qw/Beagle::Cmd::Command/;

no Any::Moose;
__PACKAGE__->meta->make_immutable;

sub execute {
    my ( $self, $opt, $args ) = @_;
    my $all = roots();
    puts current_handle() ? current_handle()->name : 'global';
}

1;

__END__

=head1 NAME

Beagle::Cmd::Command::which - show current beagle's name

=head1 SYNOPSIS

    $ beagle which

=head1 AUTHOR

    sunnavy <sunnavy@gmail.com>


=head1 LICENCE AND COPYRIGHT

    Copyright 2011 sunnavy@gmail.com

    This program is free software; you can redistribute it and/or modify it
    under the same terms as Perl itself.

