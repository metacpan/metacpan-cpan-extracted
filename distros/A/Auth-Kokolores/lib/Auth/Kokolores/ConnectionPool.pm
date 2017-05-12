package Auth::Kokolores::ConnectionPool;

use strict;
use MooseX::Singleton;

# ABSTRACT: connection cache to hold connection handles
our $VERSION = '1.01'; # VERSION

has 'handles' => (
  is => 'ro', isa => 'HashRef', lazy => 1,
  default => sub { {} },
  traits => [ 'Hash' ],
  handles => {
    'add_handle' => 'set',
    'get_handle' => 'get',
    'clear_handle' => 'delete',
    'reset' => 'clear',
  }
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Auth::Kokolores::ConnectionPool - connection cache to hold connection handles

=head1 VERSION

version 1.01

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Markus Benning <ich@markusbenning.de>.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
