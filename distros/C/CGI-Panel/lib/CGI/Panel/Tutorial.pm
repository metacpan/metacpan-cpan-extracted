package CGI::Panel::Tutorial;
use strict;
use base qw(CGI::Panel);
use CGI;
use CGI::Carp qw/fatalsToBrowser/;
use Apache::Session::File;

BEGIN {
	use Exporter ();
	use vars qw ($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
	$VERSION     = 0.97;
	@ISA         = qw (Exporter);
	@EXPORT      = qw ();
	@EXPORT_OK   = qw ();
	%EXPORT_TAGS = ();
}

########################################### main pod documentation begin ##

=head1 NAME

CGI::Panel::Tutorial - Tutorial for CGI::Panel-based applications

=head1 SYNOPSIS

    use CGI::Panel::Tutorial::SimpleShop;
    my $simple_shop = obtain CGI::Panel::Tutorial::SimpleShop;
    $simple_shop->cycle;

=head1 DESCRIPTION

Not ready yet.

=head1 USAGE

=head1 BUGS

=head1 SUPPORT

=head1 AUTHOR

	Robert J. Symes
	CPAN ID: RSYMES
	rob@robsymes.com

=head1 COPYRIGHT

Copyright (c) 2002 Robert J. Symes. All rights reserved.
This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SEE ALSO

perl(1).


1; #this line is important and will help the module return a true value
__END__

