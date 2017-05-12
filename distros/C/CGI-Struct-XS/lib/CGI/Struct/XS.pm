use warnings;
use strict;

package CGI::Struct::XS;

use XSLoader;
use Exporter qw(import);
use Storable qw(dclone);

our $VERSION = 1.04;
our @EXPORT = qw(build_cgi_struct);

XSLoader::load(__PACKAGE__, $VERSION);

1;

__END__

=head1 NAME

CGI::Struct::XS - Build structures from CGI data. Fast.

=head1 DESCRIPTION

This module is XS implementation of L<CGI::Struct>.
It's fully compatible with L<CGI::Struct>, except for error messages.
C<CGI::Struct::XS> is 3-15 (5-25 with dclone disabled) times faster than original module.

=head1 SYNOPSIS

  use CGI;
  use CGI::Struct::XS;
  my $cgi = CGI->new;
  my %params = $cgi->Vars;
  my $struct = build_cgi_struct \%params;
  ...

Or
 
  use Plack::Request;
  use CGI::Struct::XS;

  my $app_or_middleware = sub {
      my $env = shift; # PSGI env
      my $req = Plack::Request->new($env);
      my $errs = [];
      my $struct = build_cgi_struct $req->parameters, $errs, { dclone => 0 };
      ...
  }

=head1 FUNCTIONS

=head2 build_cgi_struct

  $struct = build_cgi_struct \%params;
  
  $struct = build_cgi_struct \%params, \@errs;
   
  $struct = build_cgi_struct \%params, \@errs, \%conf;

The only exported function is C<build_cgi_struct>.
It has three arguments:

=over

=item C<\%params>

HashRef with input values. Typicaly this is CGI or Plack params hashref

=item C<\@errs>

ArrayRef to store error messages. 
If it's not defined all parsing errors will be sielently discarded.

=item C<\%conf>

HashRef with parsing optiosn

=back

Following options are supported:

=over

=item C<nodot>

Treat dot as ordinary character, not hash delimeter

=item C<nullsplit>

Split input values by C<\\0> characeter, usefull for old CGI libraries

=item C<dclone>

Store deep clone of value, instead of original value. 
This opion increase memory consumsion and slows parsing.
It's recomended to disable dclone, because in most cases CGI params are used as read-only variables.

=back

=head1 SEE ALSO

L<CGI::Struct>
