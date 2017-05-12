package CGI::Carp::Fatals;

use strict;
use warnings;
use CGI::Carp qw(fatalsToBrowser set_message);
use HTML::Perlinfo;
@CGI::Carp::Fatals::ISA = qw(Exporter);
@CGI::Carp::Fatals::EXPORT = (@CGI::Carp::EXPORT);
@CGI::Carp::Fatals::EXPORT_OK = qw(fatalsRemix set_message);
$CGI::Carp::Fatals::VERSION = '0.02';

sub fatalsRemix {

my($wm) = $ENV{SERVER_ADMIN} ? 
    qq[the webmaster (<a href="mailto:$ENV{SERVER_ADMIN}">$ENV{SERVER_ADMIN}</a>)] :
      "this site's webmaster";
  my ($outer_message) = <<END;
For help, please send mail to $wm, giving this error message 
and the time and date of the error.
END
  ;

my $info_option = shift || 'INFO_VARIABLES';
my $info = perlinfo($info_option);

set_message("$outer_message<p>$info</p>");

}

1;
__END__
=pod

=head1 NAME

CGI::Carp::Fatals - fatalsToBrowser on steroids

=head1 SYNOPSIS

	use CGI::Carp::Fatals;

	use CGI::Carp::Fatals qw(fatalsRemix);
	fatalsRemix();

	use CGI::Carp::Fatals qw(fatalsRemix);
	fatalsRemix('INFO_GENERAL');

	use CGI::Carp::Fatals qw(set_message);
	set_message("It's not a bug, it's a feature!");
	
=head1 DESCRIPTION

This module extends L<CGI::Carp> by adding perlinfo information (from L<HTML::Perlinfo>)
 to fatal errors handled by CGI::Carp's fatalsToBrowser. 

=head1 USAGE/FUNCTIONS

Using CGI::Carp::Fatals enables fatalsToBrowser from L<CGI::Carp>. This is a feature.

If you wish to enhance ("juice") those error messages, you can import a function 
called 'fatalsRemix'. It will append perlinfo data to the error reports.
 This function accepts the same options as the perlinfo function from L<HTML::Perlinfo>. 

By default, fatalsRemix uses the INFO_VARIABLES option which shows you all predefined variables 
from EGPCS (Environment, GET, POST, Cookie, Server). 
Please see the L<HTML::Perlinfo> docs for further options and details. 

	use CGI::Carp::Fatals qw(fatalsRemix);
        fatalsRemix(); # defaults to INFO_VARIABLES
	fatalsRemix('INFO_GENERAL'); # now includes INFO_GENERAL. There are many other options.
	
=head2 Changing the message further

If changing the option to fatalsRemix doesn't satisfy you, you can use the set_message routine that CGI::Carp::Fatals exports from CGI::Carp. Please refer to the documentation of L<CGI::Carp>.  

=head1 What else is included?

Whatever else that CGI::Carp exports (confess, croak, and carp).

=head1 BUGS

Please report any bugs or feature requests to C<bug-cgi-carp-fatals@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CGI-Carp-Fatals>.
I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 REQUIREMENTS

L<HTML::Perlinfo>

=head1 SEE ALSO

L<CGI::Carp>, 
L<HTML::Perlinfo>, 
L<CGI::Carp::DebugScreen>, 
L<CGI::HTMLError>, 
L<CGI::Carp::Throw>.

=head1 AUTHOR

Mike Accardo <mikeaccardo@yahoo.com>

=head1 COPYRIGHT

   Copyright (c) 2009, Mike Accardo. All Rights Reserved.
 This module is free software. It may be used, redistributed
and/or modified under the terms of the Perl Artistic License.

=cut
