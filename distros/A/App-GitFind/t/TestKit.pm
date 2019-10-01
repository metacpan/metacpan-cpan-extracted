# Test kit for App::GitFind
package # hide from PAUSE
    TestKit;

# Modules we use and re-export
use 5.010;
use strict;
use warnings;
use Carp qw(croak);
use List::AutoNumbered;
use Test2::V0;

sub true () { !!1 }
sub false () { !!0 }

# Modules we do not re-export
use parent 'Exporter';

require feature;
use Import::Into;

# === Setup ===

use vars::i '@EXPORT' => qw(make_assertion true false);
use vars::i '%EXPORT_TAGS' => { all => [@EXPORT] };

sub import {
    my $target = caller;
    __PACKAGE__->export_to_level(1, @_);

    feature->import::into($target, ':5.10');
    Carp->import::into($target, qw(carp croak confess cluck));
    $_->import::into($target) foreach qw(strict warnings
        List::AutoNumbered Test2::V0);
}

# === Helpers for use in test files ===

# Make an assertion that test files can use, and that will appear as if
# at the line from which it is called.  Usage:
#   make_assertion 'name', 'code to run' [, {captures}];
# The 'code to run' is a string and can refer to variables @_, $caller
# $filename, and $line.  $_[-1] is always the string "line <#>".
#
# References to outer variables must be given the full package, and `my`
# variables from the caller of `make_assertion` are not visible since this
# is a different lexical scope.

sub make_assertion {
    my ($target, $called_by_filename, $called_at_line) = caller;
    my ($name, $codestr, $captures) = @_;
    $captures = {} unless $captures;

    # Escape the codestr
    $codestr =~ s/\\/\\\\/g;
    $codestr =~ s/'/\\'/g;

    my $function_body = <<EOT;
    sub {
        use strict;
        use warnings;
        my (undef, \$filename, \$line) = caller;
        push \@_, "line \$line";
        eval "\\n#line \$line \$filename\\n" .
            '$codestr' . "\\n";
    }
EOT

    # Install the function
    no strict 'refs';
    *{"$target\::$name"} = eval($function_body);
} #make_assertion()

1;
