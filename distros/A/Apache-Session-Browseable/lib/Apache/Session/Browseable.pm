package Apache::Session::Browseable;

our $VERSION = '1.2.5';

print STDERR "Use a sub module of Apache::Session::Browseable such as Apache::Session::Browseable::File";

1;
__END__

=head1 NAME

Apache::Session::Browseable - Add index and search methods to Apache::Session

=head1 SYNOPSIS

  use Apache::Session::Browseable::MySQL;

  my $args = {
       DataSource => 'dbi:mysql:sessions',
       UserName   => $db_user,
       Password   => $db_pass,
       LockDataSource => 'dbi:mysql:sessions',
       LockUserName   => $db_user,
       LockPassword   => $db_pass,

       # Choose your browseable fileds
       Index          => 'uid mail',
  };
  
  # Use it like Apache::Session
  my %session;
  tie %session, 'Apache::Session::Browseable::MySQL', $id, $args;
  $session{uid} = 'me';
  $session{mail} = 'me@me.com';
  $session{unindexedField} = 'zz';
  untie %session;
  
  # Apache::Session::Browseable add some global class methods
  #
  # 1) search on a field (indexed or not)
  # a. get full sessions
  my $hash = Apache::Session::Browseable::MySQL->searchOn( $args, 'uid', 'me' );
  foreach my $id (keys %$hash) {
    print $id . ":" . $hash->{$id}->{mail} . "\n";
  }
  # b. get only some fields
  my $hash = Apache::Session::Browseable::MySQL->searchOn( $args, 'uid', 'me', 'mail', 'uid' );
  foreach my $id (keys %$hash) {
    print $id . ":" . $hash->{$id}->{mail} . "\n";
    print "       " . $hash->{$id}->{uid} . "\n";
  }
  # c. search with a pattern
  my $hash = Apache::Session::Browseable::MySQL->searchOnExpr( $args, 'uid', 'm*' );
  ...

  # 2) Parse all sessions
  # a. get all sessions
  my $hash = Apache::Session::Browseable::MySQL->get_key_from_all_sessions($args);

  # b. get some fields from all sessions
  my $hash = Apache::Session::Browseable::MySQL->get_key_from_all_sessions($args, ['uid','mail'])

  # c. execute something with datas from each session :
  #    Example : get uid and mail if mail domain is
  my $hash = Apache::Session::Browseable::MySQL->get_key_from_all_sessions(
              $args,
              sub {
                 my ( $session, $id ) = @_;
                 if ( $session->{mail} =~ /mydomain.com$/ ) {
                     return { $session->{uid}, $session->{mail} };
                 }
              }
  );
  foreach my $id (keys %$hash) {
    print $id . ":" . $hash->{$id}->{uid} . "=>" . $hash->{$id}->{mail} . "\n";
  }

=head1 DESCRIPTION

Apache::Session::browseable provides some class methods to manipulate all
sessions and add the capability to index some fields to make research faster.

=head1 SEE ALSO

L<Apache::Session>

=head1 AUTHOR

Xavier Guimard, E<lt>x.guimard@free.frE<gt>

=head1 COPYRIGHT AND LICENSE

=encoding utf8

Copyright (C) 2009-2017 by Xavier Guimard
              2013-2017 by Clément Oudot

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
