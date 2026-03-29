use FindBin;
BEGIN { unshift @INC, "$FindBin::Bin/../lib" }

use v5.42;
use Moo;
use MooX::Options;
use Cwd;
use Mojo::Pg;

use feature 'say';
use feature 'signatures';
use Daje::Workflow::Activities::Authorities::Standard::AdminRole;
use Daje::Workflow::Activities::Authorities::Standard::PowerUserRole;
use Daje::Workflow::Activities::Authorities::Standard::UserRole;

use Daje::Workflow::Errors::Error;
use Daje::Workflow::Database::Model;
use namespace::clean -except => [qw/_options_data _options_config/];

sub create_admin_role() {

    my $pg = Mojo::Pg->new()->dsn(
        "dbi:Pg:dbname=sentinel;host=192.168.1.124;port=5432;user=sentinel;password=PV58nova64"
    );

    try {
        my $model = Daje::Workflow::Database::Model->new(db => $pg->db);
        $model->workflow_pkey(5);
        my $context->{context}->{payload}->{tools_projects_fkey} = 5;
        $context->{context}->{workflow}->{workflow_fkey} = 5;
        $context->{context}->{companies_fkey} = 1;
        $context->{context}->{users_fkey} = 4;

        my $role = Daje::Workflow::Activities::Authorities::Standard::AdminRole->new(
            db      => $pg->db,
            context => $context,
            model   => $model,
            error   => Daje::Workflow::Errors::Error->new(),
        );
        $role->create_admin();

        my $power_role = Daje::Workflow::Activities::Authorities::Standard::PowerUserRole->new(
            db      => $pg->db,
            context => $context,
            model   => $model,
            error   => Daje::Workflow::Errors::Error->new(),
        );

        $power_role->create_power_role();

        my $normal_role = Daje::Workflow::Activities::Authorities::Standard::UserRole->new(
            db      => $pg->db,
            context => $context,
            model   => $model,
            error   => Daje::Workflow::Errors::Error->new(),
        );

        $normal_role->create_normal_role();

    } catch ($e) {
        say $e;
    };

}

create_admin_role();


