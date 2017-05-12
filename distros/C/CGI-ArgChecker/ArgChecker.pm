######################################################################
#
# Copyright 1999 Web Juice, LLC. All Rights Reserved.
#
# CGI/ArgChecker.pm
#
# An extensible CGI parameter validation module (allowing commonly used
# checks on parameters to be called more concisely and consistently).
#
# $Header: /usr/local/repository/advoco/CGI-ArgChecker/ArgChecker.pm,v 1.3 1999/08/12 00:07:22 dlowe Exp $
# $Log: ArgChecker.pm,v $
# Revision 1.3  1999/08/12 00:07:22  dlowe
# Documentation update
#
# Revision 1.2  1999/08/12 00:04:14  dlowe
# Changed the argcheck() method to always return a hashref containing values,
# even if some values failed in error checking.
#
# Revision 1.1.1.1  1999/07/09 01:24:54  dlowe
# CGI::ArgChecker
#
#
######################################################################
package CGI::ArgChecker;

use strict;
use vars qw($VERSION);

use String::Checker;

$VERSION = '0.02';

######################################################################
## NAME:          new
##
## DESCRIPTION:   Constructor for CGI::ArgChecker
##
## USAGE:         $checker = new CGI::ArgChecker;
##
## RETURN VALUES: undef if there's an error, otherwise a blessed hash ref.
##
## BUGS:          Hopefully none.
######################################################################
sub new
{
    my($class) = shift;

    ## We don't want this called as an instance method.
    if (ref($class))
    {
        return(undef);
    }

    my($self) = { };
    $self->{'errhandler'} = sub { };
    bless($self, $class);

    return $self;
}
### end new ##########################################################



######################################################################
## NAME:          register_check
##
## DESCRIPTION:   Register a new parameter checking routine
##
## USAGE:         $checker->register_check($name, \&sub);
##
## RETURN VALUES: None.
##
## BUGS:          Hopefully none.
######################################################################
sub register_check
{
    my($self) = shift;
    if (! ref($self))
    {
        return;
    }

    my($check)   = shift;
    my($coderef) = shift;
    String::Checker::register_check($check, $coderef);
}
### end register_check ###############################################



######################################################################
## NAME:          error_handler
##
## DESCRIPTION:   Register an error handling routine
##
## USAGE:         $checker->error_handler(\&errhandler);
##
## RETURN VALUES: None.
##
## BUGS:          Hopefully none.
######################################################################
sub error_handler
{
    my($self) = shift;
    if (! ref($self))
    {
        return(undef);
    }

    $self->{'errhandler'} = shift;
}
### end error_handler ################################################



######################################################################
## NAME:          argcheck
##
## DESCRIPTION:   Check that all CGI parameters match the programmer's
##                expectations.
##
## USAGE:         $href = $checker->argcheck($CGI_query_object,
##                                   'param_name' => [ 'expectation', ... ],
##                                    ... );
##
## RETURN VALUES: Returns a hash reference containing param_name =>
##                param_value pairs.  If there's an internal error,
##                returns undef.
##
## BUGS:          Hopefully none.
######################################################################
sub argcheck
{
    my($self) = shift;
    if (! ref($self))
    {
        return(undef);
    }

    my($query)        = shift;
    my(%expectations) = @_;
    my($error_flag)   = 0;
    my(%return);

    foreach my $parameter (keys(%expectations))
    {
        my($value)  = $query->param($parameter);
        my($ret) = String::Checker::checkstring($value,
                                                $expectations{$parameter});
        if (! defined($ret))
        {
            return(undef);
        }
        foreach my $error_name (@{$ret})
        {
            $error_flag = 1;
            $self->{'errhandler'}->($parameter, $error_name);
        }

        $return{$parameter} = $value;
    }
    if ($error_flag)
    {
        $return{'ERROR'} = 1;
    }
    else
    {
        $return{'ERROR'} = 0;
    }
    return(\%return);
}
### end argcheck #####################################################

1;
__END__

=head1 NAME

CGI::ArgChecker - An extensible CGI parameter validation module (allowing
commonly used checks on parameters to be called more concisely and
consistently).

=head1 SYNOPSIS

 use CGI::ArgChecker;

 $checker = new CGI::Argchecker;
 $checker->register_check($name, \&sub);
 $checker->error_handler(\&errhandler);
 $checker->argcheck($CGI_query_object,
                    'param_name' => [ 'expectation', ... ],
                    ... );

=head1 DESCRIPTION

Note: Since this is really a simple wrapper around String::Checker(3), most
of the interesting reading is in that document (i.e. the definition of an
'expectation').  The documentation that follows assumes you are pretty
familiar with String::Checker(3), and focuses on the additional functionality
provided by this module.

=head2 CGI Parameter Checking

The argcheck() method takes a CGI object (can be any of the CGI modules which
have a param method for fetching a parameter...) followed by a list of
parameter_name/expectation_list_reference pairs.  The parameter name is
the name of a CGI variable to examine.  The expectation list is
precisely the same as the String::Checker(3) expectation list.

Each parameter will be retrieved from the CGI object using the param() method,
checked against all the expectations, and then the result of all checks will
be stored for returning.  If I<all> parameters pass I<all> expectations, a
reference to a hash will be returned, containing parameter_name/parameter_value
pairs.  If I<any> expectation fails, the hash will still be returned.  To
check whether any errors occurred, check the 'ERROR' hash value (a boolean
flag value).  For I<every> expectation which fails, in addition, an error
handling routine (described below) will be called.

=head2 Error Handling

Using the error_handler() method, you can register a chunk of code which will
be called for every expectation which fails.  This subroutine will be called
with two arguments: the name of the parameter which failed, and the name of
the expectation which failed.  The return value of the error handling code
is ignored.

=head1 BUGS

Hopefully none.

=head1 AUTHOR

J. David Lowe, dlowe@webjuice.com

=head1 SEE ALSO

perl(1), String::Checker(3)

=cut
