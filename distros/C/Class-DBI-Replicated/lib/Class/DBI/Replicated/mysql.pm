package Class::DBI::Replicated::mysql;

use strict;
use warnings;
use base qw(Class::DBI::mysql Class::DBI::Replicated);

=head1 NAME

Class::DBI::Replicated::mysql

=head1 SYNOPSIS

=head1 METHODS

=head2 C<< repl_get_master >>

=head2 C<< repl_get_slave >>

=head2 C<< repl_compare >>

=cut

__PACKAGE__->set_sql(slave_status  => <<'', 'Slave_Repl');
SHOW SLAVE STATUS

__PACKAGE__->set_sql(master_status => <<'', 'Master_Repl');
SHOW MASTER STATUS

sub _extract {
  my ($status, $file, $pos) = @_;
  $status ||= {};
  my $txt = $status->{$file} ?
    "$status->{$file} $status->{$pos}" : "NULL";
  my $extracted = {
    file => $status->{$file} || "",
    pos  => $status->{$pos}  || 0,
    txt  => $txt,
  };
  return $extracted;
}

sub repl_get_master {
  my ($class) = @_;
  my $sth = $class->sql_master_status;
  $sth->execute;
  my $status = $sth->fetch_hash;
  $sth->finish;
  return _extract($status, qw(file position));
}

sub repl_get_slave {
  my ($class) = @_;
  my $sth = $class->sql_slave_status;
  $sth->execute;
  my $status = $sth->fetch_hash;
  $sth->finish;
  return _extract($status, qw(master_log_file read_master_log_pos));
}

sub repl_compare {
  my ($class, $test, $ref) = @_;
  return 1 if $test->{file} gt $ref->{file};
  return 0 if $test->{file} lt $ref->{file};
  return 1 if $test->{pos}  >= $ref->{pos};
  return 0;
}

__PACKAGE__->mk_markers(
  'create_table',
);

__PACKAGE__->mk_force_masters(
  'drop_table',
  'set_up_table',
);

=head1 AUTHOR

Hans Dieter Pearcey, C<< <hdp@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-class-dbi-replicated-mysql@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Class-DBI-Replicated>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2005 Hans Dieter Pearcey, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Class::DBI::Replicated::mysql
