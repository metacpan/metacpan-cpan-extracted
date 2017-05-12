package App::Rad::Exclude;
use Carp qw/carp croak/;
use strict;
use warnings;

our $VERSION = '0.01';

sub load {
    my ($self, $c) = @_;
    $c->register('exclude', \&exclude, 'completely erase command from your program');
}

# removes given sub from the
# main program
sub _remove_code_from_file {
    my $sub = shift;

    #TODO: I really should be using PPI
    #if the user has it installed...
    open my $fh, '+<', $0
        or croak "error updating file $0: $!\n";

#    flock($fh, LOCK_EX) or carp "could not lock file $0: $!\n";

    my @file = <$fh>;
    my $ret = _remove_code_from_array(\@file, $sub);

    # TODO: only change the file if it's eval'd without errors
    seek ($fh, 0, 0) or croak "error seeking file $0: $!\n";
    print $fh @file or croak "error writing to file $0: $!\n";
    truncate($fh, tell($fh)) or croak "error truncating file $0: $!\n";

    close $fh;

    return $ret;
}

sub _remove_code_from_array {
    my $file_array_ref = shift;
    my $sub = shift;

    my $index = 0;
    my $open_braces = 0;
    my $close_braces = 0;
    my $sub_start = 0;
    while ( $file_array_ref->[$index] ) {
        if ($file_array_ref->[$index] =~ m/\s*sub\s+$sub(\s+|\s*\{)/) {
            $sub_start = $index;
        }
        if ($sub_start) {
            # in order to see where the sub ends, we'll
            # try to count the number of '{' against
            # the number of '}' available

            #TODO:I should use an actual LR parser or
            #something. This would be greatly enhanced
            #and much less error-prone, specially for
            #nested symbols in the same line.
            $open_braces++ while $file_array_ref->[$index] =~ m/\{/g;
            $close_braces++ while $file_array_ref->[$index] =~ m/\}/g;
            if ( $open_braces > 0 ) {
                if ( $close_braces > $open_braces ) {
                    croak "Error removing $sub: could not parse $0 correctly.";
                }
                elsif ( $open_braces == $close_braces ) {
                    # remove lines from array
                    splice (@{$file_array_ref}, $sub_start, ($index + 1 - $sub_start));
                    last;
                }
            }
        }
    }
    continue {
        $index++;
    }

    if ($sub_start == 0) {
        return "Error finding '$sub' command. Built-in?";
    }
    else {
        return "Command '$sub' successfuly removed.";
    }
}

sub exclude {
    my $c = shift;
    if ( $c->argv->[0] ) {
        if ( $c->is_command( $c->argv->[0] ) ) {
            return _remove_code_from_file($c->argv->[0]);
        }
        else {
            return $c->argv->[0] . ' is not an available command';
        }
    }
    else {
        return "Sintax: $0 exclude command_name"
    }
}

42;
__END__
=head1 NAME

App::Rad::Exclude - 'exclude' command extension for App::Rad

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

'exclude' is an opt-in command for you App::Rad programs (myapp.pl):

    use App::Rad qw(exclude);  # add the 'exclude' command
    App::Rad->run();
    
    sub mycmd {
        print "hello, world\n";
    }
    
and now you can permanently remove a command from your application

    [user@host]$ myapp.pl exclude mycmd
    
Note that this B<*will*> edit the program's source code and try to remove the command (subroutine) automatically, so use it with extreme caution.

=head1 DESCRIPTION

This is an internal module for App::Rad and should not be used separately. Please refer to L<< App::Rad >> for further documentation.


=head1 INTERNAL METHODS

=head2 load

Loads the module into App::Rad

=head2 exclude

Removes given command (subroutine) from your App::Rad program.


=head1 DEPENDENCIES

=over 4

=item * Carp, which is core in Perl 5.8.

=back


=head1 AUTHOR

Breno G. de Oliveira, C<< <garu at cpan.org> >>


=head1 LICENSE AND COPYRIGHT

Copyright 2008 Breno G. de Oliveira C<< <garu at cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See L<perlartistic>.



=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
