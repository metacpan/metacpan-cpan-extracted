package DBIx::Class::Service;

use strict;
use warnings;

use base qw(DBIx::Class);
use Class::Inspector;

=head1 NAME

DBIx::Class::Service - Aggregate DBIC processes between multiple tables.

=head1 VERSION

version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

Each service class example:

  package MySchema::Service::User;
  
  use strict;
  use warnings;
  
  use base qw(DBIx::Class::Service);
  
  sub add_user: Transaction {
    my ($class, $schema, $args) = @_;
    
    my $user_rs = $schema->resultset('User');
    
    my $user = $user_rs->create({
      user_seq => undef,
      user_id => $args->{user_id},
      password_digest => crypt($args->{password}, $args->{user_id}),
    });
    
    $user->create_related('profiles', {
      name => $args->{name},
      nickname => $args->{nickname},
    });
    
    return $user;
  }
  
  sub authenticate: DataSource {
    my ($class, $schema, $user_id, $password) = @_;
    return $schema->resultset('User')->find({ user_id => $user_id, password_digest => crypt($password, $user_id) });
  }
  
  1;

And your schema class:

  package MySchema::Schema;
  
  use strict;
  use warnings;
  
  use base 'DBIx::Class::Schema';
  
  __PACKAGE__->load_classes;
  __PACKAGE__->load_components(qw/ServiceManager/);
  __PACKAGE__->load_services({ 'MySchema::Service' => [qw/
    User
  /] });
  
  1;

Using:

  use MySchema::Schema;

  my $schema = MySchema::Schema->connect($dsn, $dbuser, $dbpass);
  ### note: please see arguments. do not need $schema
  $schema->service('User')->add_user($args);

=head1 METHODS

=head2 load_service_methods()

Load code attributes and return a pair of attribute and method name as hashref.

=cut

sub load_service_methods {
    my ($class) = shift;
    my $cache = $class->_attr_cache;

    return if (keys %$cache == 0);
    my $methods = {
        Transaction => [],
        DataSource => [],
    };

    for my $method (@{Class::Inspector->methods($class) || []}) {
        my $coderef = $class->can($method);

        next unless (exists $cache->{$coderef});
        my @attrs = @{$cache->{$coderef}};

        if (grep { $_ eq "Transaction" } @attrs) {
            push(@{$methods->{Transaction}}, $method);
        }
        elsif (grep { $_ eq "DataSource" } @attrs) {
            push(@{$methods->{DataSource}}, $method);
        }
    }

    return $methods;
}

=head1 SEE ALSO

=over 4

=item DBIx::Class::ServiceManager

=item DBIx::Class::ServiceProxy

=back

=head1 AUTHOR

Toru Yamaguchi, C<< <zigorou@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-dbix-class-service@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically be
notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2008 Toru Yamaguchi, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of DBIx::Class::Service
