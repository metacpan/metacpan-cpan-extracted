package App::Services::DB::DB_Conn::Role;
{
  $App::Services::DB::DB_Conn::Role::VERSION = '0.002';
}  #-- Log service interface

use Moo::Role;

has db_conn_svc => (
 is => 'rw',
 isa => sub { ref eq 'App::Services::Service::DB_Conn' },
 handles => ['dbh'],
 required => 1,
);

no Moo::Role;

1;

__END__

=pod

=head1 NAME

App::Services::DB::DB_Conn::Role

=head1 VERSION

version 0.002

=head1 AUTHOR

Sean Blanton <sean@blanton.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Sean Blanton.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
