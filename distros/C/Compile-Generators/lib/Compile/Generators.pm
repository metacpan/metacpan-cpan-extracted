package Compile::Generators;
use strict;
use 5.006001;
use warnings;
our $VERSION = '0.11';

use Module::Compile -base;

my $label = 'GENAAAA';

sub pmc_compile {
    my ($class, $input) = @_;
    my $output;
    while ($output = $class->compile($input)) {
        last if $output eq $input;
        $input = $output;
    }
    return $output;
}

sub compile {
    my ($class, $source) = @_;
    return $source unless $source =~
      /^(sub .*):generator (.*\n)((?s:.*?))(^\}.*\n)/m;
    my $start = "$1$2";
    my $end = $4;
    my ($static, $dynamic) = split /^\s*\n/m, $3, 2;
    if (not defined $dynamic) {
        $dynamic = $static;
        $static = '';
    }
    while ($dynamic =~ s/^(\s*yield\s*(.*))/#$1\n        \$__GEN_STATE__ = '$label'; return $2; ${label}:/m) {
        $label++;
    }
#     $dynamic =~ s/^/    /mg;
    
    my $code = <<"_";
${start}    my \$__GEN_STATE__ = undef;
${static}
return sub {
    goto \$__GEN_STATE__ if defined \$__GEN_STATE__;
${dynamic}
    \$__GEN_STATE__ = '$label';
    ${label}:
    return;
}
${end}
_
    $label++;
    $source =~ s/^sub .*:generator .*\n(?s:.*?)^\}.*\n/$code/m;
    return $source;
}

1;

__DATA__

=head1 NAME

Compile::Generators - Python-like generator subroutines for Perl

=head1 SYNOPSIS

    use Compile::Generators;

    sub gen_range :generator {
        my ($min, $max) = @_;
        my $num = $min;
        my $incr;

        while (not defined $max or $num < $max) {
            $incr = shift || 1;
            yield $num;
            $num += $incr;
        }
    }

    my $range = gen_range(50, 100);
    my $i = gen_range(1);

    while (my $num = $range->($i->())) {
        print "\$num => $num\n";
    }

When run, this prints:

    $num => 50
    $num => 51
    $num => 53
    $num => 56
    $num => 60
    $num => 65
    $num => 71
    $num => 78
    $num => 86
    $num => 95

=head1 DESCRIPTION

Compile::Generators lets you define subroutines that return their code
as a generator. You can then call the generator over and over until it
returns an empty list. The generator can yield (return) a value and then
when you call it again it resumes right after the yield.

=head1 USAGE

Any subroutine marked with the a C<:generator> attribute will have its
code wrapped into a closure and returned by the subroutine. Any yield
statements will be replace with code to return/resume at that point.

Any code before the first blank line in the sub will B<not> be a part of
the closure but will be executed when the sub is actually called. This
means that any variables that are defined before the blank line will be
I<closed> by the generator sub.

This module uses Module::Compile to compile the generators. Look inside
the C<.pmc> to see what is really happening.

Since this module uses C<goto> statements, you cannot C<yield> inside a
C<for> loop. Perl does not allow this. However you I<can> use C<while>
statements.

Currently a C<yield> statement needs to be a simple statement on it's own
line, since this gets parsed and replaced by a return/goto-label.

See the tests for examples.

=head1 AUTHOR

Ingy döt Net <ingy@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2006. Ingy döt Net. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
