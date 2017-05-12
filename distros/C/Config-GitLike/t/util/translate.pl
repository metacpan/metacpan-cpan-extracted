#!/usr/bin/env perl
use strict;
use warnings;
use 5.0100;

# script to translate some bits of the git configuration test suite into a perl
# test suite

my $prepend = 1;

while (<>) {
    if ($prepend) {
        # header test stuff
        say "use File::Copy;";
        say "use Test::More tests => 75;";
        $prepend = 0;
    }
    # translate lines like:
    # test_expect_success 'mixed case' 'cmp .git/config expect'
    # leaves more complicated test_expect_success lines alone
    elsif (/test_expect_success ('[^']+') 'cmp ([^\s]+) ([^\s]+)'/) {
        my $config = $2 eq '.git/config'? 'gitconfig' : $2;
        say "is(slurp(\$${config}), \$${3}, ${1});";
    }
    # translate cat'ing text into the 'expect' file into uninterpolated
    # heredocs in the $expect var
    elsif (/cat (>+) ?(expect|\.git\/config) << ?\\?EOF/) {
        given ($2) {
            when ('expect') {
                say "\$expect = <<'EOF'";
            }
            when ('.git/config') {
                say "open FH, '$1', \$config_filename or die \"Could not open \${config_filename}: \$!\";";
                say "print FH <<'EOF'"; 
            }
        }
    }
    # add semicolon after heredocs
    elsif (/^EOF$/) { print; say ';'; }
    # echoing into expect puts that string into $expect
    elsif (/^echo (?:'([a-zA-Z0-9. ]+)'|([^\s]+)) > expect/) {
        say "\$expect = '$1';";
    }
    # translate some git config commands into Config::GitLike code
    elsif (s/^git config//) {
        if (/--unset ([a-zA-Z0-9.]+)(?: ["']?([a-zA-Z0-9 \$]+)["']?)?$/) {
            # filter can be empty
            my($key,$filter) = ($1, $2);

            say "\$config->set(key => $key, filter => '$filter', filename => \$config_filename);"
        } elsif (/([a-zA-Z0-9.]+) ["']?([a-zA-Z0-9 ]+)["']?(?: ["']?([a-zA-Z0-9 \$]+)["']?)?$/) {
            # filter can be empty
            my($key,$val,$filter) = ($1, $2, $3);

            print "\$config->set(key => '$key', value => '$val', ";
            print "filter => '$filter', " if $filter;
            say "filename => \$config_filename);";
        }
    }
    # translate cp commands into copy()s
    elsif (/^cp .git\/([^\s]+) .git\/([^\s]+)/) {
        say "copy(File::Spec->catfile(\$config_dirname, '$1'),";
        say "     File::Spec->catfile(\$config_dirname, '$2'))";
        say " or die \"File cannot be copied: \$!\";";
    }
    # translate rm into unlink
    elsif (/^rm .git\/(.+)$/) {
        say "unlink File::Spec->catfile(\$config_dirname, '$1');";
    }
    # translate test description into a diag
    elsif (/^test_description=('.+')$/) {
        say "diag($1);"
    }
    # this really means "load this other config file that is not
    # $config_filename" and then compare it to $expect
    elsif (/^GIT_CONFIG=([^ ]+) git config ([^ ]+)(?:(?: > (output))?| ([^ ]+))/) {

        my($conffile, $cmd) = ($1, $2);
        say "my \$$conffile = TestConfig->new(confname => '$conffile');";
        if ($3 eq 'output') {
            # like git config -l (though the output won't be exactly the same
            # in cases where there's more than one var in the file since
            # dump is sorted and -l isn't)
            say "my \$$3 = \$$conffile->dump;";
        } else {
            say "\$${conffile}->set(key => '$cmd', value => '$3', file => File::Spec->catfile(\$config_dirname, ${conffile}));";
        }
    }
    # stuff that can just be canned
    elsif (/^(?:#!\/bin\/sh|#|# Copyright|\. \.\/test-lib.sh|test -f .git\/config && rm \.git\/config|test_done)/) { }
    # print any unknown stuff for manual frobbing
    else { print; }
}

