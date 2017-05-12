use strict;
use warnings;

#    Copyright 2012 Grant Street Group, All Rights Reserved.
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU Affero General Public License as
#    published by the Free Software Foundation, either version 3 of the
#    License, or (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU Affero General Public License for more details.
#
#    You should have received a copy of the GNU Affero General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.

use Test::More tests => 18;
use App::Gitc::Reversible;

# set up what we'll need for the tests
my @english;
my @deutsch;
my $die_after_english = 0;
my $die_after_deutsch = 0;
my $sleep = 0;
my $code = sub {
    push @english, 'hello';
    to_undo { pop @english };
    die "english\n" if $die_after_english;

    push @deutsch, 'guten tag';
    to_undo { pop @deutsch };
    die "deutsch\n" if $die_after_deutsch;

    # give someone a chance to interrupt us
    sleep $sleep;
};

# what happens if nothing dies
reversibly { $code->() };
is $@, "", 'no failures: exception';
is_deeply \@english, ['hello'],     'no failures: english';
is_deeply \@deutsch, ['guten tag'], 'no failures: deutsch';

# what about dying after the english
@english = @deutsch = ();
$die_after_english = 1;
eval { reversibly { $code->() } };
is $@, "\nThe exception that caused rollback was: english\n",
    'english failure: exception';
is_deeply \@english, [], 'english failure: english';
is_deeply \@deutsch, [], 'english failure: deutsch';

# what about dying after the german
@english = @deutsch = ();
$die_after_english = 0;
$die_after_deutsch = 1;
eval { reversibly { $code->() } };
is $@, "\nThe exception that caused rollback was: deutsch\n",
    'deutsch failure: exception';
is_deeply \@english, [], 'deutsch failure: english';
is_deeply \@deutsch, [], 'deutsch failure: deutsch';

# what if the process is interrupted?
for my $signal (qw( INT TERM )) {
    @english = @deutsch = ();
    $die_after_english = $die_after_deutsch = 0;
    $sleep = 5;  # give 5 seconds to be interrupted
    my $parent = $$;
    local $SIG{CHLD} = 'IGNORE';  # do zombies matter in this case?
    if ( my $pid = fork ) {
        eval { reversibly { $code->() } };
    }
    else {
        sleep 1;  # let the parent perform some reversible tasks
        kill $signal, $parent;
        exit;
    }
    is $@, "\nThe exception that caused rollback was: SIG$signal\n", "interruption: SIG$signal exception";
    is_deeply \@english, [], 'interruption: english';
    is_deeply \@deutsch, [], 'interruption: deutsch';
}


# what about nested, reversible computations
@english = @deutsch = ();
reversibly {
    push @english, 'hello';
    to_undo { pop @english };

    # don't rollback the outer transaction when the inner one fails
    eval {
        reversibly {
            push @deutsch, 'guten tag';
            to_undo { pop @deutsch };
            die "inner transaction failed\n";
        };
    };
};
is $@, "", 'nested: exception';
is_deeply \@english, ['hello'], 'nested: english';
is_deeply \@deutsch, [], 'nested: deutsch';
