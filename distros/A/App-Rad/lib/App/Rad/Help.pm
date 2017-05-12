package App::Rad::Help;
use Attribute::Handlers;
use strict;
use warnings;

our $VERSION = '0.03';

sub load {
    my ($self, $c) = @_;
    $c->register('help', \&help, 'show syntax and available commands');
}

# shows specific help commands
# TODO: context specific help, 
# such as "myapp.pl help command"
sub help {
    my $c = shift;
    return usage() . "\n\n" . helpstr($c);
}

sub usage {
    return "Usage: $0 command [arguments]";
}

sub helpstr {
    my $c = shift;
    
    my $string = "Available Commands:\n";

    # get length of largest command name
    my $len = 0;
    foreach ( sort $c->commands() ) {
        $len = length($_) if (length($_) > $len);
    }

    # format help string
    foreach ( sort $c->commands() ) {
        $string .= sprintf "    %-*s\t%s\n", $len, $_, 
                           defined ($c->{'_commands'}->{$_}->{'help'})
                           ? $c->{'_commands'}->{$_}->{'help'}
                           : ''
                           ;
                ;
    }
    return $string;
}
    

{
my %help_attr = ();
sub UNIVERSAL::Help :ATTR(CODE) {
     my ($package, $symbol, $ref, $attr, $data, $phase, $filename, $linenum) = @_;

    if ($package eq 'main') {
        # If data is a single word, it is received as an array ref. Don't ask.
        $data = join(' ', @$data) if ref($data) eq 'ARRAY';
        $help_attr{ *{$symbol}{NAME} } = $data;
    }
}

sub register_help {
    my ($self, $c, $cmd, $helptext) = @_;

    if ((not defined $helptext) && (defined $help_attr{$cmd})) {
        $helptext = $help_attr{$cmd};
    }

    # we do $helptext // undef as it would issue a warning otherwise
    $c->{'_commands'}->{$cmd}->{'help'} = defined $helptext
                                        ? $helptext
                                        : undef
                                        ;
}

}
42;
__END__

=head1 NAME

App::Rad::Help - 'help' command extension for App::Rad

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

you can add inline help for your App::Rad commands via C<< $c->register() >> or C<< $c->register_commands() >>:

    use App::Rad;
    App::Rad->run();
    
    sub setup {
        my $c = shift;
        
        $c->register_commands( {
                foo => 'expand your foo!',
                bar => 'have a drink! arguments: --drink=DRINK',
            });
            
        $c->register('baz', \&baz, 'do your thing');
    }
    
you can also do it with the attribute 'Help' in your subs

    sub my_command :Help(this is my command) {
        ...
    }
    
    sub another_cmd
    :Help(yet another command)
    {
        ...
    }
    

=head1 DESCRIPTION

This is an internal module for App::Rad and should not be used separately (unless, perhaps, you want to use one of its methods to customize your own 'help' command). Please refer to L<< App::Rad >> for further documentation.


=head1 INTERNAL METHODS

=head2 load

Loads the module into App::Rad

=head2 help

Show help text

=head2 register_help

Associates help text with command

=head2 usage

Prints usage string. Default is "Usage: $0 command [arguments]", where $0 is your program's name.

=head2 helpstr

Prints a help string with all available commands and their help description.

=head1 DEPENDENCIES

=over 4

=item * Attribute::Handlers, which is core as of Perl 5.8.

=back


=head1 AUTHOR

Breno G. de Oliveira, C<< <garu at cpan.org> >>


=head1 ACKNOWLEDGEMENTS

The attribute handling was *much* easened because of the nice C<< Attribute::Handlers >> module. So many thanks to Damian Conway, Rafael Garcia-Suarez and Steffen Mueller.


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
