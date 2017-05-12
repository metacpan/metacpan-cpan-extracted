package Class::DBI::Replicated::Pg::Slony1;

use warnings;
use strict;
use base qw(Class::DBI::Pg Class::DBI::Replicated);
use Params::Validate qw(:types);

=head1 NAME

Class::DBI::Replicated::Pg::Slony1 - Pg replication using Slony1

=head1 SYNOPSIS

  package My::DBI;
  use base 'Class::DBI::Replicated::Pg::Slony1';
  My::DBI->replication(...);

=head1 OPTIONS

Additional options for C<< replication >>.

=head3 C<< slony1_schema >>

=head3 C<< slony1_origin >>

=head1 HOOKS

=head2 C<< replication_args >>

=head2 C<< replication_setup >>

See L<Class::DBI::Replicated>.  Allow and set up slony1
options.

=cut

sub replication_args {
  return (
    slony1_schema => { type => SCALAR },
    slony1_origin => { type => SCALAR },
  );
}

sub replication_setup {
  my ($class, $arg) = @_;
  $class->mk_class_accessors(
    '__slony1_schema',
    '__slony1_origin',
    '__slony1_slave_node'
  );
  $class->__slony1_schema($arg->{slony1_schema});
  $class->__slony1_origin($arg->{slony1_origin});
  my %origin;
  my @slaves = @{ $arg->{slaves} };
  while (my ($name, $slave_arg) = splice @slaves, 0, 2) {
    $origin{"Slave_$name"} = $slave_arg->{node};
  }
  $class->__slony1_slave_node(\%origin);
}

# add 1 because of how slony1 works; that is, we care about
# the next event generated, not the last one
__PACKAGE__->set_sql(master_status => <<'', 'Master_Repl');
SELECT st_last_event + 1
FROM %s.sl_status
WHERE st_origin = ?
LIMIT 1

__PACKAGE__->set_sql(slave_status  => <<'', 'Master_Repl');
SELECT st_last_received
FROM %s.sl_status
WHERE st_received = ?
LIMIT 1

=head1 METHODS

=head2 C<< repl_get_master >>

=cut

sub repl_get_master {
  my ($class) = @_;
  $class->repl_pos(
    $class->sql_master_status(
      $class->__slony1_schema
    )->select_val(
      1
    ),
  );
}
  
=head2 C<< repl_get_slave >>

=cut

sub repl_get_slave {
  my ($class) = @_;
  my $sth = $class->sql_slave_status(
    $class->__slony1_schema
  );
  return $sth->select_val(
    $class->__slony1_slave_node->{$class->__slave_db}
  );
}

=head2 C<< repl_compare >>

=cut

sub repl_compare {
  my ($class, $test, $ref) = @_;
  return $test >= $ref;
}

=head1 AUTHOR

Hans Dieter Pearcey, C<< <hdp@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-class-dbi-replicated-pg-slony1@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Class-DBI-Replicated>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2005 Hans Dieter Pearcey, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Class::DBI::Replicated::Pg::Slony1
