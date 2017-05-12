#-----------------------------------------------------------------
# CGI::URI2param - convert parts of an URL to param values
#-----------------------------------------------------------------
# Copyright Thomas Klausner / ZSI 2001,2002,2006
# You may use and distribute this module according to the same terms
# that Perl is distributed under.
#
# Thomas Klausner domm@cpan.org http://domm.plix.at
#
#-----------------------------------------------------------------

package CGI::URI2param;

use strict;
use Carp;
use Exporter;
use vars qw(@ISA @EXPORT_OK);

@ISA = qw(Exporter);

@EXPORT_OK   = qw(uri2param);

$CGI::URI2param::VERSION = '1.01';

sub uri2param {
    my ($req,$regexs,$options)=@_;

    # options not implemented, possible options are:
    # -> don't safe in $q->param but return parsed stuff as hash/array
    # -> use URI instead of PATH_INFO

    # check if $req seems to be a valid request object
    croak "CGI::URI2param: not a valid request object" unless $req->can('param');

    # check environment and set stuff
    my $uri;
    if ($ENV{MOD_PERL}) {
        $uri=$req->uri;
    } else {
        $uri=$req->url . $req->path_info;
    }

    # apply regexes
    eval {
        while(my($key,$regex)=each(%$regexs)) {
            if ($uri=~m/$regex/) {
                $req->param($key,$+);
            }
        }
   };

   croak $@ if ($@);
   
   return 1;
}

1;

__END__

=head1 NAME

CGI::URI2param - convert parts of an URL to param values

=head1 SYNOPSIS

  use CGI::URI2param qw(uri2param);

  uri2param($req,\%regexes);

=head1 DESCRIPTION

CGI::URI2param takes a request object (as supplied by CGI.pm or
Apache::Request) and a hashref of keywords mapped to
regular expressions. It applies all of the regexes to the current URI
and adds everything that matched to the 'param' list of the request
object.

Why?

With CGI::URI2param you can instead of:

C<http://somehost.org/db?id=1234&style=fancy>

present a nicerlooking URL like this:

C<http://somehost.org/db/style_fancy/id1234.html>

To achieve this, simply do:

 CGI::URI2param::uri2param($r,{
                                style => 'style_(\w+)',
                                id    => 'id(\d+)\.html'
                               });

Now you can access the values like this:

 my $id=$r->param('id');
 my $style=$r->param('style');

If you are using mod_perl, please take a look at L<Apache::URI2param>.
It provides an Apache PerlInitHandler to make running CGI::URI2param
easier for you. Apache::URI2param is distributed along with
CGI::URI2param.

=head2 uri2param($req,\%regexs)

C<$req> has to be some sort of request object that supports the method
C<param>, e.g. the object returned by CGI->new() or by
Apache::Request->new().

C<\%regexs> is hash containing the names of the parameters as the
keys, and corresponding regular expressions, that will be applied to
the URL, as the values.

   %regexs=(
            id    => 'id(\d+)\.html',
            style => 'st_(fancy|plain)',
            order => 'by_(\w+)',
           );

You should add some capturing parentheses to the regular
expression. If you don't do, all the buzz would be rather useless.

uri2param won't get exported into your namespace by default, so you
have to either import it explicitly

 use CGI::URI2param qw(uri2param);

or call it with it's full name, like so

 CGI::URI2param::uri2param($r,$regex);

=head2 What's the difference to mod_rewrite ?

Basically noting, but you can use CGI::URI2param if you cannot use
mod_rewrite (e.g. your not running Apache or are on some ISP that
doesn't allow it). If you B<can> use mod_rewrite you maybe should
consider using it instead, because it is much more powerfull and
possibly faster. See mod_rewrite in the Apache Docs
(http://www.apache.org)

=head1 INSTALLATION

 perl Build.PL
 ./Build
 ./Build test
 sudo ./Build install

=head1 BUGS

None so far.

Please report any bugs or feature requests to
C<bug-cgi-uri2param@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically
be notified of progress on your bug as I make changes.

=head1 TODO

Implement options (e.g. do specify what part of the URL should be
matched)

=head1 REQUIRES

A module that supplies some sort of request object is needed, e.g.:
Apache::Request, CGI

=head1 SEE ALSO

L<Apache::URI2param>

=head1 AUTHOR

Thomas Klausner, domm@cpan.org, http://domm.plix.at

Thanks Darren Chamberlain <dlc@users.sourceforge.net> for the idea
to write a mod_perl handler for CGI::URI2param

=head1 COPYRIGHT & LICENSE

Copyright 2001, 2002, 2006 Thomas Klausner, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

