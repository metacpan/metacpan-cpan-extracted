package DBIx::DisconnectAll;

use strict;
use warnings;
use parent 'Exporter';
use DBI;

our $VERSION = '0.03';

our @EXPORT = qw/dbi_disconnect_all/;

sub dbi_disconnect_all {
    my %dr = DBI->installed_drivers();
    keys %dr;
    for my $dr ( values %dr ) {
        if ( $dr->{ChildHandles} 
          && ref($dr->{ChildHandles}) 
          && ref($dr->{ChildHandles}) eq 'ARRAY'
        ) {
            $_->disconnect for grep { UNIVERSAL::isa($_, 'DBI::db') } @{$dr->{ChildHandles}};
        }
    }
}

1;

__END__

=head1 NAME

DBIx::DisconnectAll - disconnect all databases

=head1 SYNOPSIS

  use DBIx::DisconnectAll;

  dbi_disconnect_all();

=head1 DESCRIPTION

DBIx::DisconnectAll is utility module to disconnect all connected databases

DBI has DBI->disconnect_all methods, but some DBD modules does not support it, 
so DBI->disconnect_all is undocumented yet and unusable.

DBIx::DisconnectAll realizes disconnect_all from DBI's public API.

=head1 AUTHOR

Masahiro Nagano E<lt>kazeburo AAJKLFJEF@ gmail.comE<gt>

Tokuhiro Matsuno

=head1 SEE ALSO

L<DBI>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
