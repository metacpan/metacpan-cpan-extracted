package DB::Pluggable::Plugin::DataPrinter;
use strict;
use warnings;
use 5.010;
use Role::Basic;
use Data::Printer; # to make it a requirement
with qw(DB::Pluggable::Role::Initializer);
our $VERSION = '1.112001';

sub initialize {
    no warnings 'once';
    $DB::alias{p} = 's/^/use Data::Printer; /; eval $cmd';
}
1;

=pod

=for test_synopsis 1;
__END__

=head1 NAME

DB::Pluggable::Plugin::DataPrinter - Debugger plugin to use Data::Printer

=head1 SYNOPSIS

    $ cat ~/.perldb

    use DB::Pluggable;
    DB::Pluggable->run_with_config(\<<EOINI)
    [DataPrinter]
    EOINI

    $ perl -d foo.pl

    Loading DB routines from perl5db.pl version 1.28
    Editor support available.

    Enter h or `h h' for help, or `man perldebug' for more help.

    DB<1> c  (or s, or n, or whatever)
    ...
    DB<2> p %foo

=head1 DESCRIPTION

This debugger plugin exposes L<Data::Printer>'s C<p> command to the
debugger. Use the C<~/.dataprinter> file to control the output - see
L<Data::Printer> for details.

=head1 METHODS

=head2 initialize

Defines a debugger alias for the C<p> command.
