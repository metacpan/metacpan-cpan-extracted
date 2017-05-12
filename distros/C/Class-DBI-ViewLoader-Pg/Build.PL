use strict;
use warnings;

use Module::Build;

=head1 NAME

Build.PL - Build script for Class::DBI::ViewLoader

=head1 SYNOPSIS

    perl Build.PL --dsn=dsn
		  --user=username
		  --pass=password

    ./Build
    ./Build test
    ./Build install

=cut

my $build = new Module::Build (
    module_name => 'Class::DBI::ViewLoader::Pg',
    dist_author => 'Matt Lawrence <mattlaw@cpan.org>',
    license => 'perl',

    requires => {
        'Class::DBI::ViewLoader' => '0.02',
        'Class::DBI::Pg' => 0,
        'DBD::Pg' => '1.31',

        # DBI is required for build, but also by Class::DBI::ViewLoader
        'DBI' => '1.43',
    },
    build_requires => {
        'Test::More' => 0,
    },

    create_makefile_pl => 'passthrough',
    create_readme => 1,

    get_options => {
        dsn  => { type => '=s' },
        user => { type => '=s' },
        pass => { type => '=s' },
    },
);

$build->create_build_script;

__END__

=head1 TESTING

When provided with a dsn (and optional username and password), the unit tests of
this module create three tables and two views and then attempt to load the
views into L<Class::DBI>.

The tables that are created and dropped are: actor, film and role. The views are
film_roles and actor_roles. Automatically generated primary key sequences for
the three tables will also be created and dropped.

If the dsn option is not specifed, all view-loading tests are skipped and only
pod and API-compatability tests are performed.

Please do not use a live/production/important database to test this module!

=head1 SEE ALSO

L<Class::DBI::ViewLoader>, L<Module::Build>, L<Class::DBI>, L<DBI>

=head1 AUTHOR

Matt Lawrence E<lt>mattlaw@cpan.orgE<gt>

