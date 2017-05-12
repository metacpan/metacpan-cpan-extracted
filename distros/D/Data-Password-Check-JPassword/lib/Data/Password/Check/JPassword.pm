package Data::Password::Check::JPassword;

use 5.008008;
use strict;
use warnings;

require Exporter;
use POSIX qw( floor log );

our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [ qw(
    password_check	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
    security is_weak is_strong is_medium advice
    password_security
    password_strong
    password_medium
    password_weak
    password_advice
);

our $VERSION = '0.02';


###########################################################
sub security
{
    my( $package, $password ) = @_;
    return $password if ref $password;
    $password =~ s/^(\s+)|(\s+$)//g;
    my $c = {number=>1, uppercase=>1, lowercase=>1, punctuation=>1, special=>1};
    while( $password =~ /(.)/g ) {
        my $char = ord $1;
        if( $char > 127 ) {
            $c->{special}++;
        }
        if( $char > 47 && $char < 58 ) { 
            $c->{number} ++; 
        }
        elsif( $char > 64 && $char < 91 ) { 
            $c->{uppercase} ++; 
        }
        elsif( $char > 96 && $char < 123 ) { 
            $c->{lowercase} ++; 
        }
        else { 
            $c->{punctuation} += 2;
        }
    }

    my $level = $c->{number} * $c->{uppercase} * $c->{lowercase} * 
                $c->{punctuation} * $c->{special};
    # $c->{level} = floor( log( $level*$level ) + 0.5 );
    # jPassword uses Math.round()... why bother?
    $c->{level} = log( $level*$level );
    $c->{password} = $password;
    return $c
}

###########################################################
# Return true if this is a strong password
sub is_strong
{
    my( $package, $password ) = @_;
    my $c = $package->security( $password );
    return $c->level >= 10;
}

###########################################################
# Return true if this is a medium-strength password
sub is_medium
{
    my( $package, $password ) = @_;
    my $c = $package->security( $password );
    return $c->level >= 5;
}

###########################################################
# Return true if this is a weak password
sub is_weak
{
    my( $package, $password ) = @_;
    my $c = $package->security( $password );
    return $c->level < 5;
}

###########################################################
sub advice
{
    my( $package, $password ) = @_;
    my $c = password_security( $password );
    return if password_strong( $c );
    foreach my $k ( qw( lowercase uppercase number punctuation special ) ) {
        return $k if $c->{$k} < 2;
    }
}





###########################################################
sub password_security
{
    return __PACKAGE__->security( @_ );
}    

###########################################################
sub password_strong
{
    return __PACKAGE__->is_strong( @_ );
}

###########################################################
# Return true if this is a strong password
sub password_medium
{
    return __PACKAGE__->is_medium( @_ );
}

###########################################################
# Return true if this is a weak password
sub password_weak
{
    my( $password ) = @_;
    return __PACKAGE__->is_weak( @_ );
}

###########################################################
# Return advice for a password
sub password_advice
{
    my( $password ) = @_;
    return __PACKAGE__->is_advice( @_ );
}



1;

__END__

=head1 NAME

Data::Password::Check::JPassword - Check a password's strength

=head1 SYNOPSIS

    use Data::Password::Check::JPassword;

    # as part of some UI validation
    sub password_validation
    {
        my( $input ) = @_;
        my $password = $input->value;
        my $c = password_security( $password );
        return 1 if password_strong( $c );
        
        my $error = $input->error_widget;
        my $advice = password_advice( $c );
        $error->text( "Your password is week.  " . 
                         $i18n->get( "password-$advice" );
        $error->show;
        return 0;
    }

    # OO inteface:
    my $JQ = "Data::Password::Check::JPassword";
    my $C = $JQ->security( $password );
    if( $JQ->is_strong( $C ) {
        # ...
    }
    elsif( $JQ->is_medium( $C ) {
        # ...
    }
        


=head1 DESCRIPTION

This module implements the jPassword strength algorythim in pure Perl.  The
algorythim is pretty simple:

=over 4

=item *

Leading and trailing spaces are stripped way;

=item *

Each character is placed in one of 5 categories: uppercase (A-Z), lowercase
(a-z), numbers (0-9), punctuation (anything else in the ASCII table) and
special (anything not in the ASCII table.  Yes, this means all accents are
considered special);

=item * 

Each category starts at one and is incremented for each character in that
category.  The exception being punctuation, which counts double;

=item * 

All the category counds are multiplied together;

=item *

The finale security score is the natural logarythm of result of the previous
step.

=back

In jPassword, a score under 5 is weak, over 10 is strong and between the two
is medium.



=head1 FUNCTIONS

=head2 password_security

    my $C = password_security( $password );

Analyses the strength of a password and returns a hash ref describing the
analysis.  This hash ref contains the following keys:

=over 4

=item uppercase

Number of uppercase letters (A-Z, U+0041-U+005A) plus one.

=item lowercase

Number of lowercase letters (a-z, U+0061-U+007A) plus one.

=item number

Number of digits (0-9, U+0030-U+0039) plus one.

=item punctuation

Double the number of characters in the range U+0000-U+007F that don't fall into the
above categories plus one.

=item special

Number of other characters (U+0080 and up) plus one.

=item level

Rough estimate of the security level of the password.  This is a natural log
of the square of the multiplication of the previous 5 keys.

=item password

The password, after being trimmed.

=back



=head2 password_strong

    if( password_string( $password ) ) {
    }

Returns true if the security of C<$password> is ten (10) or greater. 
Returns false otherwise.  You may also pass in the hashref returned by
L</password_security>.

=head2 password_medium

    if( password_medium( $password ) ) {
    }

Returns true if the security of C<$password> is five (5) or greater. 
Returns false otherwise.  You may also pass in the hashref returned by
L</password_security>.


=head2 password_weak

    if( password_weak( $password ) ) {
    }

Returns true if the security of C<$password> is below 5. 
Returns false otherwise.  You may also pass in the hashref returned by
L</password_security>.


=head2 password_advice

    my $need = password_advice( $password );

Returns one category that needs to be impoved.  This could then be used to
give advice to the user on how to improve his password.

Simply, it looks for the first category that is not in the password.


=head1 METHODS

Data::Password::Check::JPassword also provides class methods with for an
object-oriented interface.

=head2 security

    my $c = Data::Password::Check::JPassword->security( $password );

See L</password_security>.

=head2 is_strong

    if( Data::Password::Check::JPassword->is_strong( $password ) ) {
    }

See L</password_strong>.

=head2 is_medium

    if( Data::Password::Check::JPassword->is_medium( $password ) ) {
    }

See L</password_medium>.

=head2 is_weak

    if( Data::Password::Check::JPassword->is_weak( $password ) ) {
    }

See L</password_weak>.

=head2 advice

    my $category = Data::Password::Check::JPassword->advice( $password );

See L</password_advice>.


=head1 SEE ALSO

L<jPassword plugin|http://searchcode.com/codesearch/view/2972736>,
L<Data::Password::Simple>,
L<Data::Password::Entropy>,
L<Data::Password::BasicCheck>

=head1 AUTHOR

Philip Gwyn, E<lt>fil@localdomainE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Philip Gwyn

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
