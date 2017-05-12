package Ceph::Rados::List;

use 5.014002;
use strict;
use warnings;
use Carp;

our @ISA = qw();

our $VERSION = '0.01';

# Preloaded methods go here.

sub new {
    my ($class, $io) = @_;
    my $obj = open_ctx($io);
    bless $obj, $class;
    return $obj;
}

sub DESTROY {
    my $self = shift;
    $self->close;
}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Ceph::Rados - Perl extension for blah blah blah

=head1 SYNOPSIS

  use Ceph::Rados;
  blah blah blah

=head1 DESCRIPTListN

Stub documentation for Ceph::Rados, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.


=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

Alex, E<lt>alex@E<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Alex

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
