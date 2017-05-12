package Call::Immediate;

use 5.006001;
use strict;
use warnings;

our $VERSION = '0.01';

use Filter::Simple ();

sub import {
    my ($self, @subs) = @_;
    my $filter = sub {
        for my $sub (@subs) {
            s/^ (\s*) ($sub) \b /$1use Call::Immediate::Call $2/xm;
        }
    };
    my $caller = caller;
    no strict 'refs';
    no warnings 'redefine';
    *{"$caller\::import"} = Filter::Simple::gen_filter_import($caller, $filter);
    *{"$caller\::unimport"} = Filter::Simple::gen_filter_unimport($caller);
}

1;

=head1 NAME

Call::Immediate - Export subs that are called as soon as they are seen at compile time

=head1 SYNOPSIS

    package MyModule;

    sub class {
        # muck around with symbol tables and stuff
    }
    
    # still have to export manually
    use Exporter;
    use base 'Exporter';
    our @EXPORT = qw<class>;

    # Use this module to have them executed immediately
    # when they are seen.
    # ALWAYS use this module at the END of your module definition!
    use Call::Immediate qw<class>;

=head1 DESCRIPTION

This module installs a very simple source filter that causes the subs you
specify to be called as soon as they are seen, like macros (but ones that don't
substitute any text).  This allows you to create slightly more natural
constructs like:

    class Foo => sub { 
        ...
    };

As soon as this is seen in the user's file, your C<class> sub will be executed,
so that you can mess with the symbol table and affect compilation of the rest
of the file if you like.

This is implemented by scanning for the subs you specify in the left column
(permitting optional whitespace before it) and replacing it with a "use"
declaration.  Specifically, the call you see above would be turned into:

    use Call::Immediate::Call class Foo => sub {
        ...
    };

Where C<Call::Immedate::Call> is a module that simply does nothing on import.

=head1 AUTHOR

Luke Palmer <lrpalmer at gmail dot com>
