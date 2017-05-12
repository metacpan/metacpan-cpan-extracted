package App::Services::DB::Exec::Role;
{
  $App::Services::DB::Exec::Role::VERSION = '0.002';
}  #-- Log service interface

use Moo::Role;

has db_exec_svc => (
 is => 'ro',
 isa => sub { ref($_[0]) eq 'App::Services::DB::Exec::Service' },
 handles => ['App::Services::DB::Exec::Service'],
 required => 1,
);

no Moo::Role;

1;

__END__

=pod

=head1 NAME

App::Services::DB::Exec::Role

=head1 VERSION

version 0.002

=head1 AUTHOR

Sean Blanton <sean@blanton.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Sean Blanton.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
