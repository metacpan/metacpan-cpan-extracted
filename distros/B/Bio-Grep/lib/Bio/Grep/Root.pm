#############################################################################
#   $Author: markus $
#     $Date: 2009-11-12 17:13:23 +0100 (Thu, 12 Nov 2009) $
# $Revision: 1844 $
#############################################################################

package Bio::Grep::Root;

use strict;
use warnings;

use version; our $VERSION = qv('0.10.6');

use Bio::Root::Root;

use base 'Bio::Root::Root';

use File::Spec;
use File::Copy;
use Scalar::Util qw(reftype);

sub is_integer {
    my ( $self, $variable, $desc ) = @_;
    return $self->_check_variable(
        variable => $variable,
        desc     => $desc,
        regex    => 'int'
    );
}

sub is_word {
    my ( $self, $variable, $desc ) = @_;
    return $self->_check_variable(
        variable => $variable,
        desc     => $desc,
        regex    => 'word'
    );
}

sub is_path {
    my ( $self, $variable, $desc ) = @_;
    return $self->_check_variable(
        variable => $variable,
        desc     => $desc,
        regex    => 'path'
    );
}

sub is_sentence {
    my ( $self, $variable, $desc ) = @_;
    return $self->_check_variable(
        variable => $variable,
        desc     => $desc,
        regex    => 'sentence'
    );
}

sub is_arrayref_of_size {
    my ( $self, $a_ref, $size ) = @_;
    my $reftype = reftype $a_ref;
    if ( !defined $reftype || $reftype ne 'ARRAY' ) {
        $self->throw(
            -class => 'Bio::Root::BadParameter',
            -text  => 'Argument is not an array reference',
            -value => $reftype
        );
    }
    if ( scalar @{$a_ref} < $size ) {
        $self->throw(
            -class => 'Bio::Root::BadParameter',
            -text  => 'Size of argument is too small.',
            -value => scalar @{$a_ref} . " vs. $size"
        );
    }
    return 1;
}

###############################################################################
# Usage      : $self->_check_variable(%args)
# Purpose    : make perl -T happy: get only "secure" symbols for system()
# Returns    : the specified variable if it is ok
# Parameters : ( variable => $v, regex => 'int', desc => $desc )
# Throws     : Bio::Root::BadParameter if variable is not ok
# Comments   : if variable is undef, then return value is undef
# See also   : http://gunther.web66.com/FAQS/taintmode.html

sub _check_variable {
    my ( $self, %args ) = @_;

    if ( !%args || !defined $args{regex} ) {
        $self->throw(
            -class => 'Bio::Root::BadParameter',
            -text  => 'Missing arguments: require hash with keys "regex"'
                . '"variable" and optional "desc"',
        );
    }
    return if !defined $args{variable};

    if ( !defined $args{desc} ) {
        $args{desc} = 'Variable';
    }
    my $value;

    my %regexes = (
        'int'      => qr{ ( \A \d+ \z ) }xms,
        'word'     => qr{ ( \A [\w.\-]+ \z ) }xms,
        'path'     => qr{ ( \A [\w.\-/\\: ]+ \z ) }xms,
        'sentence' => qr{  \A ([\w.\-/|:(),;]+)  }xms,
    );

    if ( defined $regexes{ $args{regex} } ) {
        ($value) = $args{variable} =~ $regexes{ $args{regex} };
    }
    else {
        $self->throw(
            -class => 'Bio::Root::BadParameter',
            -text  => 'Unknown regex.',
            -value => $args{regex}
        );
    }

    if ( !defined $value ) {
        $self->throw(
            -class => 'Bio::Root::BadParameter',
            -text  => $args{desc} . ' looks not valid.',
            -value => $args{variable}
        );
    }
    return $value;
}

sub _cannot_print {
    my ( $self, $filename ) = @_;
    $self->throw(
        -class => 'Bio::Root::IOException',
        -text  => 'Cannot write to file',
        -value => $filename
    );
    return;
}

1;    # Magic true value required at end of module
__END__

=head1 NAME

Bio::Grep::Root - Superclass for all Bio::Grep* packages

=head1 DESCRIPTION

This superclass adds some useful methods to all Bio::Grep packages.

=head1 METHODS

See L<Bio::Root::Root> for inherited methods.

=head2 PACKAGE METHODS

=over

=item C<is_integer($var_to_check, 'Description')>

Returns the variable, but it is now not tainted anymore. Throws an exception
if the specified variable is not an integer. If a second argument is passed,
it will be used in the exception text.

=item C<is_word($var_to_check, 'Description')>

Returns the variable, but it is now not tainted anymore. Throws an exception
if the specified variable is not a word. If a second argument is passed,
it will be used in the exception text.

=item C<is_path($var_to_check, 'Description')>

Returns the variable, but it is now not tainted anymore. Throws an exception
if the specified variable is not a valid path (It is word but accepts also
'/'). If a second argument is passed, it will be used in the exception text.

=item C<is_sentence($var_to_check, 'Description')>

Returns the variable, but it is now not tainted anymore. Throws an exception
if the specified variable is not a valid sentence (It is word but accepts also
'/:,;|'). If a second argument is passed, it will be used in the exception text.

WARNING: make sure that command line arguments are quoted ( my $command = "...
 '$sentence' ") 

=item C<is_arrayref_of_size($a_ref, $size)>

Checks if $a_ref is an array reference and the array is of size $size or
larger.

=back

=head1 DIAGNOSTICS

=over

=item C< ... looks not valid.>

Some variable does not match the specified regular expression.
C<Bio::Root::BadParameter>.

=item C<Argument is not an array reference.>

Method is_arrayref_of_size() is used to check arguments. You probably called
a method with wrong arguments.

=item C<Missing arguments: require hash with keys "regex" ... >

You called the internal method _check_variable() without a valid hashref.
Don't use this method. C<Bio::Root::BadParameter>.

=item C<Size of argument is too small.>

Method is_arrayref_of_size() is used to check arguments. You probably called
a method with missing arguments.

=item C<Unknown regex.>

You called the internal method _check_variable() with an invalid regex.  Don't
use this method. C<Bio::Root::BadParameter>.

=back

=head1 AUTHOR

Markus Riester, E<lt>mriester@gmx.deE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2007-2009 by M. Riester. 

Based on Weigel::Search v0.13, Copyright (C) 2005-2006 by Max Planck 
Institute for Developmental Biology, Tuebingen.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.


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
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut

# vim: ft=perl sw=4 ts=4 expandtab
