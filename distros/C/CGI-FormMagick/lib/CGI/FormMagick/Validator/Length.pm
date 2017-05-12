#!/usr/bin/perl -w

#
# FormMagick (c) 2000-2001 Kirrily Robert <skud@cpan.org>
# Copyright (c) 2000-2002 Mitel Networks Corporation
# This software is distributed under the same licenses as Perl itself;
# see the file COPYING for details.

#
# $Id: Length.pm,v 1.6 2003/02/05 17:18:40 anoncvs_gtkglext Exp $
#

package    CGI::FormMagick::Validator;

=pod

=head1 NAME

CGI::FormMagick::Validator::Length - length-related validation routines

=head1 VALIDATION ROUTINES

=item minlength(n)

The data is at least C<n> characters long: C<length($data) E<gt>= $n>

=begin testing
BEGIN: {
    use CGI::FormMagick::Validator;
}

is( minlength(undef, "abc", 2), "OK" , "3 letter string is at least 2 chars long");
isnt( minlength(undef, "abc", -2), "OK" , "Negative minlength should fail");
isnt( minlength(undef, "abc", 0), "OK" , "Zero minlength should fail");
isnt( minlength(undef, "abc", "def"), "OK" , "Non-numeric minlength should fail");
isnt( minlength(undef, "", 1), "OK" , "Too short string should fail");

=end testing

=cut

sub minlength {
    my ($fm, $data, $minlength) = @_;
    if (number($fm, $minlength) ne "OK" or $minlength <= 0) {
        return "Minimum length has been specified meaninglessly as $minlength"; 
    }
    if ( length($data) >= $minlength ) {
        return "OK";
    } else {
        return "This field must be at least $minlength characters";
    }
}


=pod

=item maxlength(n)

The data is no more than  C<n> characters long: C<length($data) E<lt>= $n>

=for testing
is( maxlength(undef, "abc", 5), "OK" , "3 letter string is less than 5 chars long");
isnt( maxlength(undef, "abc", -2), "OK" , "Negative maxlength should fail");
isnt( maxlength(undef, "abc", 0), "OK" , "Zero maxlength should fail");
isnt( maxlength(undef, "abc", "def"), "OK" , "Non-numeric maxlength should fail");
is( maxlength(undef, "", 1), "OK" , "Zero length string is less than 1 char long");

=cut

sub maxlength {
    my ($fm, $data, $maxlength) = @_;
    if (number($fm, $maxlength) ne "OK" or $maxlength <= 0) {
        return "Maximum length has been specified meaninglessly as $maxlength"; 
    }
    if ( length($data) <= $maxlength ) {
        return "OK";
    } else {
        return "This field must be no more than $maxlength characters";
    }
}

=pod

=item exactlength(n)

The data is exactly  C<n> characters long: C<length($data) E== $n>

=for testing
is( exactlength(undef, "abc", 3), "OK" , "3 letter string is 3 chars long");
isnt( exactlength(undef, "abc", 5), "OK" , "3 letter string isn't 5 chars long");
isnt( exactlength(undef, "abc", -2), "OK" , "Negative length should fail");
is( exactlength(undef, "", 0), "OK" , "Empty string is zero length");
isnt( exactlength(undef, "abc", "def"), "OK" , "Non-numeric exactlength should fail");
isnt( exactlength(undef, "abc"), "OK", "undef exactlength should fail");

=cut

sub exactlength {
    my ($fm, $data, $exactlength) = @_;
    if (not defined $exactlength) {
        return "You must specify the length for the field."; 
    } elsif ( $exactlength =~ /\D/ ) {
        return "You must specify the exactlength of the field with an integer";
    } elsif ( length($data) == $exactlength ) {
        return "OK";
    } else {
        return "This field must be exactly $exactlength characters";
    }
}


=pod

=item lengthrange(n,m)

The data is between  C<n> and c<m> characters long: C<length($data) E<gt>= $n>
and C<length($data) E<lt>= $m>.

=for testing
ok( CGI::FormMagick::Validator->can('lengthrange'), "Lengthrange routine exists");
is( lengthrange(undef, "abc", 2,4), "OK" , "3 letter string is between 2 and 4 chars long");
is( lengthrange(undef, "abc", 3,3), "OK" , "3 letter string is between 3 and 3 chars long");
isnt( lengthrange(undef, "abc", 1,2), "OK" , "3 letter string is not between 1 and 2 chars long");
is( lengthrange(undef, "", 0,1), "OK" , "Empty string is zero length");
isnt( lengthrange(undef, "abc", -2,4), "OK" , "Negative length should fail");
isnt( lengthrange(undef, "abc", 5,3), "OK" , "Max length is less than min length");

=cut

sub lengthrange {
    my ($fm, $data, $minlength, $maxlength) = @_;
    if (not defined $minlength or not defined $maxlength) {
        return "You must specify the maximum and minimum length for the field."; 
    } elsif ( $maxlength =~ /\D/ or $minlength =~ /\D/ ) {
        return "You must specify the maximum and minimum lengths of the field with an integer";
    } elsif ( ( length($data) >= $minlength ) and (length($data) <= $maxlength) ) {
        return "OK";
    } else {
        return "This field must be between $minlength and $maxlength characters";
    }
}


=pod

=head1 SEE ALSO

The main perldoc for CGI::FormMagick

=head1 AUTHOR

Kirrily "Skud" Robert <skud@infotrope.net>

More information about FormMagick may be found at 
http://sourceforge.net/projects/formmagick/

=cut

return 1;
