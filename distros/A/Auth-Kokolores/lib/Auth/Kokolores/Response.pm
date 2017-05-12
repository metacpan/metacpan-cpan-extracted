package Auth::Kokolores::Response;

use Moose;

# ABSTRACT: kokolores response object
our $VERSION = '1.01'; # VERSION

has 'success' => (
  is => 'ro',
  isa => 'Bool',
  default => 0
);

sub new_success {
  return shift->new( success => 1 );
}

sub new_fail {
  return shift->new( success => 0 );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Auth::Kokolores::Response - kokolores response object

=head1 VERSION

version 1.01

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Markus Benning <ich@markusbenning.de>.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
