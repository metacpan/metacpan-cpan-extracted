DBIx::Class::Factory
-------------------

Ruby has `factory_girl`, Python has `factory_boy`.

Now Perl has [`DBIx::Class::Factory`](https://metacpan.org/pod/DBIx::Class::Factory).

Create factory:

```perl
package My::UserFactory;
use base qw(DBIx::Class::Factory);

__PACKAGE__->resultset(My::Schema->resultset('User'));
__PACKAGE__->fields({
    name => __PACKAGE__->seq(sub {'User #' . shift}),
    status => 'new',
});

package My::SuperUserFactory;
use base qw(DBIx::Class::Factory);

__PACKAGE__->base_factory('My::UserFactory');
__PACKAGE__->field(superuser => 1);
```

Use factory:

```perl
my $user = My::UserFactory->create();
my @verified_users = @{ My::UserFactory->create_batch(3, {status => 'verified'}) };

my $superuser = My::SuperUserFactory->build();
$superuser->insert();
````
