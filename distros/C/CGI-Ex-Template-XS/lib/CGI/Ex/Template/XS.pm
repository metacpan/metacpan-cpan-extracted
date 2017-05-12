package CGI::Ex::Template::XS;

=head1 NAME

CGI::Ex::Template::XS - DEPRECATED - you should now use Template::Alloy::XS

=cut

use strict;
use warnings;
use base qw(Template::Alloy::XS);

use Template::Alloy::XS 1.002;
use CGI::Ex::Template 2.14;

our $VERSION = '0.06';

1;

__END__


=head1 SYNOPSIS

    use CGI::Ex::Template::XS;

    my $obj = CGI::Ex::Template::XS->new;

    # see the Template::Alloy::XS and Template::Alloy documentation

=head1 DESCRIPTION

This module was the precursor to Template::Alloy::XS.  CGI::Ex::Template::XS
is now deprecated in favor of using Template::Alloy::XS.  No further work
will be done on the CGI::Ex::Template::XS line - all work will go into the
Template::Alloy line.

All code should work as before.

=head1 AUTHOR

Paul Seamons <perl at seamons dot com>

=head1 LICENSE

This module may be distributed under the same terms as Perl itself.

=cut
