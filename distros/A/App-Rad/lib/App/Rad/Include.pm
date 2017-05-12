package App::Rad::Include;
use Carp qw/carp croak/;
use strict;
use warnings;

our $VERSION = '0.01';

sub load {
    my ($self, $c) = @_;
    $c->register('include', \&include, 'include one-liner as a command');
}

# translates one-liner into
# a complete, readable code
sub _get_oneliner_code {
    return _sanitize( _deparse($_[0]) );
}


#TODO: option to do it saving a backup file
# (behavior probably set via 'setup')
# inserts the string received
# (hopefully code) inside the
# user's program file as a 'sub'
sub _insert_code_in_file {
    my ($command_name, $code_text) = @_;

    my $sub =<<"EOSUB";
sub $command_name {
$code_text
}
EOSUB

    # tidy up the code, if Perl::Tidy is available
    eval "use Perl::Tidy ()";
    if (! $@) {
        my $new_code = '';
        Perl::Tidy::perltidy( argv => '', source => \$sub, destination => \$new_code );
        $sub = $new_code;
    }

#TODO: flock
#    eval {
#        use 'Fcntl qw(:flock)';
#    }
#    if ($@) {
#        carp 'Could not load file locking module';
#    }

    #TODO: I really should be using PPI
    #if the user has it installed...
    #or at least a decent parser
    open my $fh, '+<', $0
        or croak "error updating file $0: $!\n";

#    flock($fh, LOCK_EX) or carp "could not lock file $0: $!\n";

    my @file = <$fh>;
    _insert_code_into_array(\@file, $sub);

    # TODO: only change the file if
    # it's eval'd without errors
    seek ($fh, 0, 0) or croak "error seeking file $0: $!\n";
    print $fh @file or croak "error writing to file $0: $!\n";
    truncate($fh, tell($fh)) or croak "error truncating file $0: $!\n";

    close $fh;
}


sub _insert_code_into_array {
    my ($file_array_ref, $sub) = @_;
    my $changed = 0;

    $sub = "\n\n" . $sub . "\n\n";

    my $line_id = 0;
    while ( $file_array_ref->[$line_id] ) {

        # this is a very rudimentary parser. It assumes a simple
        # vanilla application as shown in the main example, and
        # tries to include the given subroutine just after the
        # App::Rad->run(); call.
        next unless $file_array_ref->[$line_id] =~ /App::Rad->run/;

        # now we add the sub (hopefully in the right place)
        splice (@{$file_array_ref}, $line_id + 1, 0, $sub);
        $changed = 1;
        last;
    }
    continue {
        $line_id++;
    }
    if ( not $changed ) {
        croak "error finding 'App::Rad->run' call. $0 does not seem a valid App::Rad application.\n";
    }
}


# deparses one-liner into a working subroutine code
sub _deparse {

    my $arg_ref = shift;

    # create array of perl command-line 
    # parameters passed to this one-liner
    my @perl_args = ();
    while ( $arg_ref->[0] =~ m/^-/o ) {
        push @perl_args, (shift @{$arg_ref});
    }

    #TODO: I don't know if "O" and
    # "B::Deparse" can actually run the same way as
    # a module as it does via -MO=Deparse.
    # and while I can't figure out how to use B::Deparse
    # to do exactly what it does via 'compile', I should
    # at least catch the stderr buffer from qx via 
    # IPC::Cmd's run(), but that's another TODO
    my $deparse = join ' ', @perl_args;
    my $code = $arg_ref->[0];
    my $body = qx{perl -MO=Deparse $deparse '$code'};
    return $body;
}


# tries to adjust a subroutine into
# App::Rad's API for commands
sub _sanitize {
    my $code = shift;

    # turns BEGIN variables into local() ones
    $code =~ s{(?:local\s*\(?\s*)?(\$\^I|\$/|\$\\)}
              {local ($1)}g;

    # and then we just strip any BEGIN blocks
    $code =~ s{BEGIN\s*\{\s*(.+)\s*\}\s*$}
              {$1}mg;

    my $codeprefix =<<'EOCODE';
my $c = shift;

EOCODE
    $code = $codeprefix . $code;

    return $code;
}


# includes a one-liner as a command.
# TODO: don't let the user include
# a control function!!!!
sub include {
    my $c = shift;

    my @args = @ARGV;

    if( @args < 3 ) {
        return "Sintax: $0 include [name] -perl_params 'code'.\n";
    }

    # figure out the name of
    # the command to insert.
    # Either the user chose it already
    # or we choose it for the user
    my $command_name = '';
    if ( $args[0] !~ m/^-/o ) {
        $command_name = shift @args;

        # don't let the user add a command
        # that already exists
        if ( $c->is_command($command_name) ) {
            return "Command '$command_name' already exists. Please remove it first with '$0 exclude $command_name";
        }
    }
    else {
        $command_name = $c->create_command_name();
    }
    $c->debug("including command '$command_name'...");

    my $code_text = _get_oneliner_code(\@args);

    _insert_code_in_file($command_name, $code_text);

    # turns code string into coderef so we
    # can register it (just in case the user
    # needs to run it right away)
    my $code_ref = sub { eval $code_text};
    $c->register($command_name, $code_ref);

    return; 
}

42;
__END__
=head1 NAME

App::Rad::Include - 'include' command extension for App::Rad

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

'include' is an opt-in command for you App::Rad programs (myapp.pl):

    use App::Rad qw(include);  # add the 'include' command
    App::Rad->run();
    
and now you can turn your one-liners (e.g:)

    [user@host]$ perl -i -pe 's/\r//' file.txt

into nice scalable commands, simply replacing 'perl' for 'yourapp include <NAME>'

    [user@host]$ myapp.pl include dos2unix -i -pe 's/\r//'
    
and there you go, a brand new 'dos2unix' command:

    [user@host]$ myapp.pl dos2unix file.txt


=head1 DESCRIPTION

This is an internal module for App::Rad and should not be used separately. Please refer to L<< App::Rad >> for further documentation.


=head1 INTERNAL METHODS

=head2 load

Loads the module into App::Rad

=head2 include

Translates perl one-liner into self-contained command (subroutine) and adds it to your App::Rad program.


=head1 DEPENDENCIES

=over 4

=item * O, which is core in Perl 5.8.

=item * B::Deparse, also core in 5.8.

=item * Perl::Tidy (optional)

=back


=head1 AUTHOR

Breno G. de Oliveira, C<< <garu at cpan.org> >>


=head1 ACKNOWLEDGEMENTS

The one-liner conversion and beautification was *much* easened because of the nice C<< O >> , C<< B::Deparse >> and C<< Perl::Tidy >> modules. So many thanks to Malcolm Beattie, Nicholas Clark, Stephen McCamant, Steve Hancock, and everyone that helped those projects.


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
