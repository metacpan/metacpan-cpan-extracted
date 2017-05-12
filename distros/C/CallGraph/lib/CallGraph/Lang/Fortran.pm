package CallGraph::Lang::Fortran;

$VERSION = '0.55';

use strict;
use warnings;

use base 'CallGraph';

=head1 NAME

CallGraph::Lang::Fortran - Fortran 77 parser for creating call graphs

=head1 SYNOPSIS

    use CallGraph::Lang::Fortran;
    my $graph = CallGraph::Lang::Fortran->new(files => [glob('*.f')]);
    print $graph->dump;

=head1 DESCRIPTION

This module is a subclass of L<CallGraph> which implements parsing Fortran 77 
code for building the call graph.

=head1 METHODS

This module inherits all the methods from L<CallGraph>. It defines only one
additional method:

=over

=item $graph->parse($fh)

Parse the program using the given filehandle $fh. Note that you don't really
have to call this method directly, because it's called automatically whenever
you specify a file via the add_files or add_lines method, or via the
files or lines options to the constructor.

This is the one function you have to override if you want to implement your
own subclass of L<CallGraph> for parsing another language.

=cut

sub parse {
    my ($self, $fh) = @_;

    my @lines = map uc, <$fh>;   # slurp file and normalize case
    s/\t/        / for (@lines); # get rid of tabs

    # build function list
    my @func_list = ("dummy");
    for (@lines) {
        if(/^      .*?FUNCTION\s*(\w+)/) {
            push @func_list, $1;
        }
    }
    my $re_func = join(' *\(|', @func_list);
    $re_func = qr/($re_func *\()/;

    # build call table
    my ($sub);
    my $state = 0;
    for (@lines) {
        next if /^[C*]/;
        if ($state == 0) { # not in a block
            if(/^       *(SUBROUTINE|.*FUNCTION|PROGRAM)\s*(\w+)/) {
                my ($type, $name) = ($1, $2); 
                $sub = $self->new_sub(name => $name, type => 'internal');
                if ($type eq 'PROGRAM') {
                    $self->root($sub);
                }
                $state = 1, next;
            }
        } elsif ($state == 1) {   # inside a block
            if (/^\s+END\s*$/) {  # end of block
                $state = 0;
                next;
            }
            if (/CALL (\w+)/i) {  # subroutine call
                $self->add_call($sub->name, $1);
            }
            while (/$re_func/g) { # look for function calls
                my $func = $1;
                $func =~ s/ *\($//;
                $self->add_call($sub->name, $func);
            }
        }
    }
}


1;

=back

=head1 BUGS

The parser is simplistic, so it might not handle every edge case (such as funny
use of whitespace and continuation lines) properly.

=head1 VERSION

0.55

=head1 SEE ALSO

L<CallGraph::Node>, L<CallGraph::Dumper>, L<CallGraph>

=head1 AUTHOR

Ivan Tubert E<lt>itub@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (c) 2004 Ivan Tubert. All rights reserved. This program is free
software; you can redistribute it and/or modify it under the same terms as
Perl itself.

=cut



