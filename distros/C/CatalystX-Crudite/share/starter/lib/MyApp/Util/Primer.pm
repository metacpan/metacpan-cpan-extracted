package <% dist_module %>::Util::Primer;
use strict;
use warnings;
use <% dist_module %>::Util::Random qw(:all);
use Exporter qw(import);
our %EXPORT_TAGS = (
    util => [
        qw(
          prime_database
          )
    ],
);
our @EXPORT_OK = @{ $EXPORT_TAGS{all} = [ map { @$_ } values %EXPORT_TAGS ] };

sub prime_database {
    my $schema = shift;
    my %roles = (can_manage_users => 'Manage users');

    # see README for what those roles mean
    my %user_map = (
        admin => [
            qw(
              can_manage_users
              )
        ],
        norm => [qw()],
    );
    for my $role_name (keys %roles) {
        $roles{$role_name} =
          $schema->resultset('Role')
          ->create({ name => $role_name, display_name => $roles{$role_name} });
    }
    while (my ($user_name, $role_names) = each %user_map) {
        my $user = $schema->resultset('User')
          ->create({ name => $user_name, password => $user_name });
        for my $role_name (@$role_names) {
            $user->add_to_roles($roles{$role_name});
        }
    }
}
1;
