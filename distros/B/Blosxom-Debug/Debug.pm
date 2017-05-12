# Blosxom debug module and source filter
# Author(s): Gavin Carr <gavin@openfusion.com.au>
# Version: 0.001000

package Blosxom::Debug;

use strict;
use Filter::Simple;

use vars qw($VERSION);

$VERSION = 0.001000;

# Source filter magic - uncomment calls to debug()
FILTER_ONLY 
    code => sub { s/^(\s*)#\s*(debug\()/$1$2/mg };

my %debug_level = ();
sub import {
    my $self = shift;
    my %arg = @_;
    my $package = caller;
    $debug_level{$package} = $arg{debug_level} || 0;
    {
        # Export local debug() into plugin's namespace (unless one already exists)
        no strict 'refs';
        *{"${package}::debug"} = \&debug unless defined &{"${package}::debug"};
    }
}

# Debug logger - warn @msg iff $level <= calling package's $debug_level
sub debug {
    my ($level, @msg) = @_;

    my $msg = join(' ', @msg);
    $msg .= "\n" unless substr($msg, -1) eq "\n";

    my $package = caller;
#   warn "[debug] level $level, package $package, debug_level $debug_level{$package}\n";
    warn "$package debug $level: $msg" if $level <= $debug_level{$package};
}

1;

__END__

=head1 NAME

Blosxom::Debug - a blosxom helper module and source filter to provide a 
standardised debug() logging helper to blosxom plugins


=head1 SYNOPSIS

    # 'use' this module in your plugin
    use Blosxom::Debug debug_level => 1;
    # (for distribution, you would normally have this statement commented out)

    # In your code, add commented out debug(level, message) lines
    # debug(1, 'This is a level 1 message, visible if debug_level >= 1');
    # debug(2, 'This is a level 2 message, visible if debug_level >= 2');
    # Blosxom::Debug automatically uncomments them itself if it is enabled

    # If you want to hide such a statement from Blosxom::Debug altogether,
    # comment out with more than one hash e.g.
    ## debug(1, 'This message won't show up in your webserver log!');


=head1 DESCRIPTION

Blosxom::Debug is a perl module to provide simple standardised debug logging 
facilities to blosxom plugins. It exports a debug() function of the form:

    debug($level, $message);

which logs $message to your webserver log if $level is greater than or equal
to the debug_level specified in your 'use' statement.

So the following statement:

    debug(1, 'This is a level 1 message, visible only if debug_level >= 1');

will show up in your webserver log if you do a:

    use Blosxom::Debug debug_level => 1;

but not if you do:

    use Blosxom::Debug debug_level => 0;

In the latter case, however, all your debug statements are still all
executed, it is just that the output is suppressed because the debug_level
is too low. There is therefore a small runtime overhead incurred, which you
would probably prefer to avoid unless you're debugging.

For this reason, Blosxom::Debug is also a perl source filter which actively
uncomments debug statements if enabled. This allows you to distribute plugins
including:

    # use Blosxom::Debug debug_level => 1

    # and then later on in your plugin ...
    # debug(1, "This is a level 1 message");

with both the use statement and all your debug statements commented out, and
therefore incurring no runtime overhead in production.

When you run into a problem you need to debug, you then simply uncomment
just the 'use' statement, which activates all (single-hash) commented debug
statements at runtime i.e.

    use Blosxom::Debug debug_level => 1

    # and this debug statement will now be invoked, even though commented
    # debug(1, "This is a level 1 message");

Note that your debug statements therefore must be valid perl, since they
actually are executed as normal.

To actually hide debug statements from Blosxom::Debug, you must comment them
out with more than one hash e.g.

    ## debug(1, "This message is hidden, no matter what the debug_level");


=head1 BUGS AND LIMITATIONS

Commented-out debug() lines must currently occur at the beginning of a line
i.e. you can't do things like:

    $foo = 1;    # debug(1, "setting \$foo");


=head1 SEE ALSO

Blosxom: http://blosxom.sourceforge.net/


=head1 AUTHOR

Gavin Carr <gavin@openfusion.com.au>, http://www.openfusion.net/


=head1 LICENSE

Copyright 2007, Gavin Carr.

This library is free software; you can redistribute it and/or modify it 
under the same terms as Perl itself.

=cut

# vim:ft=perl
