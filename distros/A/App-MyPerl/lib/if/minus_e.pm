package if::minus_e;

use strict;
use warnings FATAL => 'all';

sub import {
    return unless $0 eq '-e';
    shift;
    my ($target, @args) = @_;
    require Module::Runtime;
    my $import = Module::Runtime::use_module($target)->can('import');
    goto &$import if $import;
}

1;

=head1 NAME

if::minus_e - only load and import modules for one-liners

=head1 SYNOPSIS

This:

  $ perl -Mif::minus_e=Some::Module myscript.pl

is equivalent to just:

  $ perl myscript.pl

However, this:

  $ perl -Mif::minus_e=Some::Module -e '...'

is equivalent to:

  $ perl -MSome::Module -e '...'

or, similarly:

  $ perl -e 'use Some::Module; ...'

And this:

  $ perl -Mif::minus_e=Some::Module,foo,bar -e '...'

is equivalent to:

  $ perl -MSome::Module=foo,bar -e '...'

or, again:

  $ perl -e 'use Some::Module qw(foo bar); ...'

=head1 AUTHOR and COPYRIGHT

See L<App::MyPerl>

=cut
