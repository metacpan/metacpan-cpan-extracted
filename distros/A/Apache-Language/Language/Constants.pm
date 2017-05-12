package Apache::Language::Constants;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;

@ISA = qw(Exporter);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(   L_OK
                L_DECLINED
                L_ERROR
                L_MAX     
                L_TRACE     
                L_DEBUG    
                L_VERBOSE   
                L_QUIET
                warning  
);
$VERSION = '0.01';

use constant L_ERROR        => 0;
use constant L_OK           => 1;
use constant L_DECLINED     => 2;
use constant L_NOT_FOUND    => 3;


#debug constants
use constant    L_MAX       => 4;
use constant    L_TRACE     => 3;
use constant    L_DEBUG     => 2;
use constant    L_VERBOSE   => 1;
use constant    L_QUIET     => -1;   

sub warning {
    my ($message, $level) = @_;
    my $r = Apache->request;
    my ($caller,$filename,$line) = caller;
   #This one should be working...
    #my $debug = ${$caller::DEBUG};
    my $debug = eval "\$" . $caller . "::DEBUG"; #"
    
    return if L_QUIET == $debug;
    if (not defined $level or $debug >= $level){
    	my $err_msg="[$caller ($line)] $message";
        $r ? $r->warn($err_msg) : warn($err_msg);
        }
	return;
    }
# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

Apache::Language::Constants - Apache::Language constants for use by LanguageHandlers

=head1 SYNOPSIS

  use Apache::Language::Constants;

=head1 DESCRIPTION

These are constants LanguageHandlers can use to return status information to
Apache::Language.  The constants and their respective signification are as follow:

=over

=item L_OK

Return with this value whenever something correctly ends

=item L_ERROR

Return with this value whenever something bad has happened.  By bad, I mean something
that will prevent you to complete the required task and that some form of error
should be generated in the logs.

=item L_DECLINED

return with this value in the B<initialize> routine to indicate you are not interested
in being called to answer queries for that package.  How you decide this is up to 
you.

=back

Remember to return B<undef> when a search retrieves nothing and all will be ok.

=head1 SEE ALSO

perl(1), L<Apache>(3), L<Apache::Language>(3).

=head1 SUPPORT

Please send any questions or comments to the Apache modperl 
mailing list <modperl@apache.org> or to me at <gozer@ectoplasm.dyndns.com>

=head1 AUTHOR

Philippe M. Chiasson <gozer@ectoplasm.dyndns.com>

=head1 COPYRIGHT

Copyright (c) 1999 Philippe M. Chiasson. All rights reserved. This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself. 

=cut
