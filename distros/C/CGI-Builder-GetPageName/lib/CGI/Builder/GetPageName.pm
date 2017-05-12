package CGI::Builder::GetPageName;

use strict;
use vars qw/$VERSION/;

$VERSION = '0.03';

$Carp::Internal{+__PACKAGE__}++;
$Carp::Internal{__PACKAGE__.'::_'}++;

# Override
sub get_page_name {
    my $s = shift;
    my $p 
        =  $s->cgi->param($s->cgi_page_param)
        || do {
                my $path         = $ENV{PATH_INFO} || '/';
                my @path_entries = split( '/' , $path );
                join( '_' , @path_entries[1..$#path_entries] );
           }
         ;

    $s->page_name( $p ) if defined( $p ) && length( $p );

}


1;

=head1 NAME

CGI::Builder::GetPageName - GetPageName from path info.

=head1 DESCRIPTION

This extention allow you to set page name from $ENV{PATH_INFO} instead of
p(Qerystring). You can check SYNOPSYS out and you will know what this mean. :-) 

This class is extention of CGI::Builder, I love CGI::Builder.

=head1 SYNOPSYS

start.cgi

 #!/usr/bin/perl -w

 use strict;
 use Your::CGI::Builder;
 
 my $app = Your::CGI::Builder->new();
 $app->process();
 
 # you can set page name this way if you want but in this way
 # you do not need to use this extention :-p
 #$app->process( 'page_name' );
 
 __END__

Your CGI::Builder Package.

 package Your::CGI::Builder;
 
 use CGI::Builder qw/
    CGI::Builder::GetPageName
 /;
 
 sub PH_foo_bar {
    my $s = shift;
    $s->page_content( 'my URL is http://localhost/script.cgi/foo/bar/?foo=whatever !!!!' );
 }
 
 sub PH_hoge {
    my $s = shift;
    $s->page_content = 'my URL is http://localhost/script.cgi/hoge/ !!!' ;
 }

=head1 MORE FUN?

Use ScriptAlias !!! This allow you to hide .cgi extension. Very fun.


 ScriptAlias /secure /var/www/httpdoc/secure.cgi

 # You have this start script.
 http://localhost/secure.cgi 

 # You set script alias so , you can also access with this URL.
 http://localhost/secure
 
 # Then now...
 sub PH_foo_bar {
    my $s = shift;
    $s->page_content = 'my URL is http://localhost/secure/foo/bar/?foo=whatever !!!' ;
 }

=head1 OVERRIDE MODULES

=head2 get_page_name

I override this method but I guess you do not need to care.

=head1 SEE ALSO

CGI::Builder

=head1 CREDITS

Thanks to Domizio Demichelis for everything!

=head1 AUTHOR

Tomohiro Teranishi <tomohiro.teranishi+cpan@gmail.com>

=head1 COPYRIGHT

This program is distributed under the Artistic License

=cut
