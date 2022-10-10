#!/usr/bin/env perl
use strict;
use warnings;
use 5.006;
use ExtUtils::MakeMaker::CPANfile;

WriteMakefile(
    NAME       => 'App::vcardtidy',
    ABSTRACT   => 'tidy up VCARD files',
    AUTHOR     => 'Mark Lawrence <nomad@null.net>',
    VERSION    => '1.0.2',
    LICENSE    => 'gpl_3',
    EXE_FILES  => ['bin/vcardtidy'],
    test       => { RECURSIVE_TEST_FILES => 1, },
    META_MERGE => {
        'meta-spec' => { version => 2 },

        #        no_index    => {
        #            package => [
        #                qw(
        #                  )
        #            ],
        #        },
        resources => {
            bugtracker =>
              { web => 'https//github.com/mlawren/vcardtidy/issues', },
            homepage   => 'https//github.com/mlawren/vcardtidy',
            repository => {
                type => 'git',
                url  => 'ssh://git@github.com/mlawren/vcardtidy.git',
                web  => 'https//github.com/mlawren/vcardtidy',
            }
        },
    },
);

# Create the test script
sub create_t_scripts {
    use Path::Tiny;

    my $perl = -x $^X           ? $^X : "/usr/bin/env $^X";
    my $sep  = $^O eq 'MSWin32' ? ';' : ':';

    my $root = path('.')->absolute;

    my $bin   = $root->child('bin');
    my $lib   = $root->child('lib');
    my $share = $root->child('share');
    my $t     = $root->child('t');
    mkdir($t);

    my @scripts = @_ ? @_ : $bin->children;

    foreach my $script (@scripts) {
        my $t_script = $t->child( $script->basename );

        $t_script->spew_utf8(<<"EOF");
#!$perl

### Test script specific setup ###
BEGIN {
    \$ENV{PATH} = "$t" .'$sep'.\$ENV{PATH};
    \$ENV{SHARE_DIR} //= "$share";
}
use lib "$lib";
my \$ret = do "$script";
die \$@ if \$@;
\$ret;
EOF
        $t_script->chmod('a+x');
    }
}

create_t_scripts();
