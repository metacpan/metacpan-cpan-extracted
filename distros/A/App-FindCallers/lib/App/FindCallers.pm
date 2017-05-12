package App::FindCallers;
# ABSTRACT: Find the callers of a given function in a directory tree

our $VERSION = '0.04';

use 5.010;
use strict;
use warnings;

use File::Find;
use PPI;

sub report {
    my ($filename, $f, $nestlevel) = @_;
    my $indent = "  " x $nestlevel;
    my $message = "Called from";
    if ($nestlevel) {
        $message = "Defined in"
    }
    my $location = $filename . ":" . $f->line_number;

    printf "%s%s %s() in %s\n", $indent, $message, $f->name, $location;
}

sub find_in_file {
    my ($function, $filename, $cb) = @_;
    $cb ||= \&report;
    my $document = PPI::Document->new($filename);
    unless ($document) {
        say "Failed to parse $filename " . PPI::Document->errstr;
        return;
    }
    $document->index_locations;
    my $references = $document->find(sub {
        $_[1]->isa('PPI::Token::Word') and $_[1]->content eq $function
    });
    return unless $references;
    for my $f (@$references) {
        my $nestlevel = 0;
        while ($f = $f->parent) {
            # XXX this makes skip the declaration of said sub,
            # but also makes it not detect recursive calls
            if ($f->isa('PPI::Statement::Sub') and $f->name ne $function) {
                $cb->($filename, $f, $nestlevel);
                $nestlevel++;
            }
        };
    }
}

sub main {
    my ($funcname, $directory, $cb) = @_;
    $directory ||= '.';
    find({ wanted => sub {
        if (/\.p[lm]$/) {
            find_in_file $funcname, $_;
        }
    }, follow => 1, no_chdir => 1 }, $directory);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::FindCallers – find callers of a given function in a directory tree

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

    find_callers.pl <name> [<directory>]

This app will search the directory (optionally specified as a second
argument; will default to the current directory) for references to the
supplied function name. It won't actually bother checking if C<name> is
indeed a name of a sub, so you can probably use it for anything else too.

Example usage:
    
    $ find_callers.pl dupa t/testfiles/simple/               
    Called from foo() in t/testfiles/simple/test.pl:3
    Called from baz() in t/testfiles/simple/test.pl:9
      Defined in bar() in t/testfiles/simple/test.pl:8
        Defined in nested() in t/testfiles/simple/test.pl:7

=head1 AUTHOR

Tadeusz „tadzik” Sośnierz <tadeusz@sosnierz.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Tadeusz Sośnierz,
and is MIT licensed.

=cut
