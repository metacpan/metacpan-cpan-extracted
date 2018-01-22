use warnings;
use strict;

use 5.008001;
BEGIN { unshift @INC, '.' unless $INC[-1] eq '.'; }
use inc::Module::Install 1.00;

use Getopt::Long();

my $getopt = Getopt::Long::Parser->new(
    config => [qw/gnu_getopt bundling_override no_ignore_case pass_through/]
);
my $args = {
    skip_author_deps => undef,
};
$getopt->getoptions($args, 'skip_author_deps');
if (@ARGV) {
    warn "\nIgnoring unrecognized option(s): @ARGV\n\n";
}

use FindBin;
use lib "$FindBin::Bin/lib";

perl_version '5.008001';
name           'DBIx-Class-Schema-Loader';
all_from       'lib/DBIx/Class/Schema/Loader.pm';

# temporary, needs to be thrown out
test_requires 'DBIx::Class::IntrospectableM2M' => 0;

# core, but specific versions not available on older perls
test_requires 'File::Temp'      => '0.16';
test_requires 'File::Path'      => '2.07';

test_requires 'DBD::SQLite'     => '1.29';
test_requires 'Test::Exception' => '0.31';
test_requires 'Test::More'      => '0.94';
test_requires 'Test::Warn'      => '0.21';
test_requires 'Test::Deep'      => '0.107';
test_requires 'Test::Differences' => '0.60';

requires 'Carp::Clan'                  => 0;
requires 'Class::Accessor::Grouped'    => '0.10008';
requires 'Class::C3::Componentised'    => '1.0008';
requires 'Class::Inspector'            => '1.27';
requires 'Class::Unload'               => '0.07';
requires 'curry'                       => '1.000000',
requires 'Data::Dump'                  => '1.06';
requires 'DBIx::Class'                 => '0.08127';
requires 'Hash::Merge'                 => '0.12';
requires 'Lingua::EN::Inflect::Number' => '1.1';
requires 'Lingua::EN::Tagger'          => '0.23';
requires 'Lingua::EN::Inflect::Phrase' => '0.15';
requires 'List::Util'                  => '1.33';
requires 'MRO::Compat'                 => '0.09';
requires 'namespace::clean'            => '0.23';
requires 'Scope::Guard'                => '0.20';
requires 'String::ToIdentifier::EN'    => '0.05';
requires 'String::CamelCase'           => '0.02';
requires 'Sub::Util'                   => '1.40';
requires 'Try::Tiny'                   => 0;

# core, but specific versions not available on older perls
requires 'Digest::MD5'                 => '2.36';
requires 'Exporter'                    => '5.63';

print <<"EOF";
******************* DBIx::Class::Schema::Loader WARNING ***********************
The default attributes for belongs_to relationships for foreign keys with no
rules has been changed for most databases, and is soon changing for the rest,
as ON DELETE/UPDATE and DEFERRABLE clauses for foreign keys are now being
introspected.

THIS MAY AFFECT YOUR DDL DIFFS WHEN DEPLOYING

YOUR GENERATED CODE WILL ALMOST CERTAINLY CHANGE

Read more about the changes in "relationship_attrs" in:

perldoc DBIx::Class::Schema::Loader::Base

https://metacpan.org/module/DBIx::Class::Schema::Loader::Base#relationship_attrs

See also the "Changes" file for the last few revisions.
*******************************************************************************
EOF

if ($Module::Install::AUTHOR && ! $args->{skip_author_deps}) {
    my @missing_plugins;
    for my $plugin (qw(ReadmeFromPod AuthorTests)) {
        eval "require Module::Install::$plugin" and next;
        push @missing_plugins, "Module::Install::$plugin";
        chomp(my $err = $@);
        $missing_plugins[-1] .= " ($err)"
            unless $err =~ m{^Can't locate Module/Install/$plugin.pm in \@INC};
    }
    die "\nYou need to install the following modules to run this Makefile.PL in author mode:\n\n", join("\n", @missing_plugins), "\n\n"
        if @missing_plugins;

    warn "\n*** AUTHOR MODE: some optional dependencies converted to hard requires.\n\n";

    require DBIx::Class::Schema::Loader::Optional::Dependencies;

    test_requires %{DBIx::Class::Schema::Loader::Optional::Dependencies
        ->modreq_list_for([
            grep { !/rdbms/ }
            keys %{ DBIx::Class::Schema::Loader::Optional::Dependencies
                ->req_group_list
            }
        ])};

    DBIx::Class::Schema::Loader::Optional::Dependencies->_gen_pod(undef, 'lib');

    author_tests( 'xt' );
    readme_from( 'lib/DBIx/Class/Schema/Loader.pm' );
    realclean_files( qw[README MANIFEST lib/DBIx/Class/Schema/Loader/Optional/Dependencies.pod] );
    postamble <<EOP;
create_distdir: author_stop_distdir_creation
author_stop_distdir_creation:
\t\$(NOECHO) \$(ECHO) Creation of dist with author mode deps not allowed
\t\$(NOECHO) \$(ECHO) Please re-run Makefile.PL with --skip_author_deps
\t\$(NOECHO) \$(FALSE)
EOP

}

tests_recursive;

install_script 'script/dbicdump';

resources 'IRC'         => 'irc://irc.perl.org/#dbix-class';
resources 'license'     => 'http://dev.perl.org/licenses/';
resources 'repository'  => 'https://github.com/dbsrgits/dbix-class-schema-loader';
resources 'MailingList' => 'http://lists.scsys.co.uk/cgi-bin/mailman/listinfo/dbix-class';

auto_install;
WriteAll;

# vim:et sts=4 sw=4 tw=0:
