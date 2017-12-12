package App::PerlShell::LexPersist;

########################################################
# AUTHOR = Michael Vincent
# www.VinsWorld.com
########################################################

use strict;
use warnings;

use Lexical::Persistence 1.01 ();

our @ISA = qw( Lexical::Persistence );

our $PACKAGE = undef;

sub new {
    my $class = shift;

    my $package = 'App::PerlShell';
    my %params;
    if ( @_ == 1 ) {
        ($package) = @_;
    } else {
        my %cfg = @_;
        for ( keys(%cfg) ) {
            if (/^-?package$/i) {
                $package = $cfg{$_};
                delete $cfg{$_};
            } else {
                $params{$_} = $cfg{$_};
            }
        }
    }

    my $self = $class->SUPER::new(@_);

    $self->{package} = $package;
    # following line avoids ugly error if first command in shell is
    # $var = ... without the "my"
    $PACKAGE = $package;

    return $self;
}

sub get_package {
    $_[0]->{package};
}

sub set_package {
    $_[0]->{package} = $_[1];
}

sub prepare {
    my $self    = shift;
    my $code    = shift;
    my $package = $self->get_package;

    # Put the package handling tight around the code to execute
    $code = <<"END_PERL";
package $package;
    
$code

BEGIN {
	\$App::PerlShell::LexPersist::PACKAGE = __PACKAGE__;
}
END_PERL

    # Hand off to the parent version
    return $self->SUPER::prepare( $code, @_ );
}

# Modifications to the package are tracked at compile-time
sub compile {
    my $self = shift;
    my $sub  = $self->SUPER::compile(@_);

    # Save the package state
    $self->set_package($PACKAGE);

    return $sub;
}

1;

__END__

########################################################
# Start POD
########################################################

=head1 NAME

App::PerlShell::LexPersist - Perl Shell Lexical Environment

=head1 SYNOPSIS

 use App::PerlShell;
 my $shell = App::PerlShell->new(
     -lex => 1;
 );
 $shell->run;

=head1 DESCRIPTION

B<App::PerlShell::LexPersist> provides an extension to B<App::PerlShell> to 
allow using "my" variables with persistent state across each command line.  
It uses B<Lexical::Persistence> to accomplish this.

=head1 METHODS

Several methods and accessors are provided and some override the 
B<Lexical::Persistence> ones.  These are called as-needed from the 
B<App::PerlShell> C<run> method.

=over 4

=item B<new>

=item B<get_package>

=item B<set_package>

=item B<prepare>

=item B<compile>

=back

=head1 ACKNOWLEDGEMENTS

This module is lifted from B<Perl::Shell>.

=head1 SEE ALSO

L<App::PerlShell>

=head1 LICENSE

This software is released under the same terms as Perl itself.
If you don't know what that means visit L<http://perl.com/>.

=head1 AUTHOR

Copyright (c) 2016 Michael Vincent

L<http://www.VinsWorld.com>

All rights reserved

=cut
