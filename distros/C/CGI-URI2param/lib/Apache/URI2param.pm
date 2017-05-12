#-----------------------------------------------------------------
# Apache::URI2param - PerlInitHandler to use with CGI::URI2param
#-----------------------------------------------------------------
# Copyright Thomas Klausner / ZSI 2002,2006
# You may use and distribute this module according to the same terms
# that Perl is distributed under.
#
# Thomas Klausner domm@zsi.at http://domm.zsi.at
#
#-----------------------------------------------------------------

package Apache::URI2param;

use strict;
use Carp;
use Apache::Request 0.33 ();
use CGI::URI2param qw(uri2param);

$Apache::URI2param::VERSION = '1.01';

sub handler {
    my $r=Apache::Request->instance(shift);
    my @configs = $r->dir_config->get('URI2param_regex');
    my %regexs;
    my %used_keys;

    foreach (@configs) {
        /(\w+)\s+(.*)/;
        next if $used_keys{$1};
        $regexs{$1}=$2;
        $used_keys{$1}++;
    }

    uri2param($r,\%regexs);

    return $Apache::Constants::OK;
}

1;

__END__

=head1 NAME

Apache::URI2param - PerlInitHandler to use with CGI::URI2param

=head1 SYNOPSIS

in your httpd.conf

  <Location /somewhere>
     PerlInitHandler Apache::URI2param

     PerlAddVar URI2param_regex "sort sort_(\w+)"
     PerlAddVar URI2param_regex "style style_(fancy|plain)"
     PerlAddVar URI2param_regex "id news(\d+)"
  </Location>

  <Location /somewhere/else>
     PerlAddVar URI2param_regex "id article(\d+)"
  </Location>

=head1 DESCRIPTION

Apache::URI2param is a small PerlInitHandler to wrap around
L<CGI::URI2param> so you don't have to call CGI::URI2param::uri2param
from your mod_perl scripts/apps.

As an added bonus, it uses PerlAddVar to set the regexes, so you can 
let Apache figure out what regexes to apply to what URIs via the Apache
Configuration File.

You should start your own handlers with:
  sub handler {
    my $r=Apache::Request->instance(shift);
    ...

i.e., use the new feature of Apache::request, C<instance> to use a
singelton Apache Request object.

=head2 CONFIGURATION

After installing Apache::URI2param as a PerlInitHandler, you can pass
regexes that should be applied to the URI via PerlAddVar. The format
is:

  PerlAddVar URI2param_regex "PARAM REGEX"

where PARAM is the name of the parameter to be set, and REGEX is a regular
expression containing capturing parenthenses.

You should use PerlAddVar instead of PerlSetVar, because Apache will then
figure out for you what regexes to apply for an given URI.

If you look at the example given in L<SYNOPSIS>, if you'd request the URI
C</somewhere/else/style_fancy/article123.html> you would get the following
parameters:

    print $r->param('style') # fancy
    print $r->param('id')    # 123
    print $r->param('sort')  # undef

As you can see here, you can use the "style" regex defined for C</somewhere>,
but the "id" definition in C</somewhere/else> overrides the one in
C</somewhere>.

=head2 handler()

This routine gets called as a PerlInitHandler very early in the Apache
Request Cycle. Thus you can access the generated params in nearly all
other phases.

C<handler> basically just generates a hash of param names and regexes and
passes the hash to L<CGI::URI2param::uri2param> for processing there.

=head1 INSTALLATION

Apache::URI2param gets installed along with CGI::URI2param

=head1 REQUIRES

Apache::Request (0.33)

=head1 SEE ALSO

L<CGI::URI2param>

=head1 AUTHOR

Thomas Klausner, domm@zsi.at, http://domm.zsi.at

Thanks Darren Chamberlain <dlc@users.sourceforge.net> for the idea
to write a mod_perl handler for CGI::URI2param

=head1 COPYRIGHT & LICENSE

Copyright 2002, 2006 Thomas Klausner, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

