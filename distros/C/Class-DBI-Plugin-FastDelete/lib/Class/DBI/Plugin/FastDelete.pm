package Class::DBI::Plugin::FastDelete;

use strict;
use warnings;
use vars qw($VERSION @EXPORT);
require Exporter;

@EXPORT = qw(fast_delete);
$VERSION = 0.01;

use SQL::Abstract;

sub import {
    my $pkg = caller(0);
    $pkg->mk_classdata('_fast_delete');
    goto &Exporter::import;
}

sub fast_delete {
    my $class = shift;
    my $where = (ref $_[0]) ? $_[0] : { @_ };
    unless ( $class->_fast_delete ){
        $class->_fast_delete(SQL::Abstract->new);
    }

    my ($stmt, @bind) = $class->_fast_delete->delete($class->table,$where);
    my $sth;
    eval { $sth = $class->db_Main->prepare($stmt) };
    if ($@) {
        return $class->_db_error(
            msg => "Can't delete $class: $@",
            err => $@,
            method => 'delete_fast',
        );
    }

    eval { $sth->execute(@bind) };
    if ($@) {
        return $class->_db_error(
            msg => "Can't delete $class: $@",
            err => $@,
            method => 'delete_fast',
        );
    }

    return 1;
}

1;
__END__

=head1 NAME

Class::DBI::Plugin::FastDelete - Add to Class::DBI for more fast delete method.

=head1 VERSION

This documentation refers to Class::DBI::Plugin::FastDelete version 0.01

=head1 SYNOPSIS

  package Your::CD;
  use base 'Class::DBI';
  use Class::DBI::Plugin::FastDelete;
  
  ............
  
  Your::CD->fast_delete( artist => 'Green Day' );

=head1 DESCRIPTION

This Plugin provide to Class::DBI for more fast delete method.
fast_delete method can't use trigger.
Instead its fast!

=head1 EXPORT

=head2 fast_delete

fast_delete method provide more fast delete method.

=head1 DEPENDENCIES

L<SQL::Abstract>

L<Class::DBI>

=head1 SEE ALSO

L<SQL::Abstract>

L<Class::DBI>

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.
Please report problems to Atsushi Kobayashi (E<lt>nekokak@cpan.orgE<gt>)
Patches are welcome.

=head1 AUTHOR

Atsushi Kobayashi, E<lt>nekokak@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Atsushi Kobayashi (E<lt>nekokak@cpan.orgE<gt>). All rights reserved.

This library is free software; you can redistribute it and/or modify it
 under the same terms as Perl itself. See L<perlartistic>.

=cut
