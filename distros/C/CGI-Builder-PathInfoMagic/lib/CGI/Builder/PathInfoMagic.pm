package CGI::Builder::PathInfoMagic;

use strict;
use base qw/CGI::Builder/;
use vars qw/$VERSION/;
$VERSION = '0.03';

sub process {
    my $s  = shift;
    my $p  = __path_info_magic() || 'index' ;
    
    $s->SUPER::process( $p );
}

sub __path_info_magic{
    my $path = $ENV{PATH_INFO} || '/';
    my @path_entries = split( '/' , $path );
    return join( '_' , @path_entries[1..$#path_entries] );
}

1;

=head1 NAME

CGI::Builder::PathInfoMagic - Deprecated. Use CGI::Builder::GetPageName instead.

=head1 DESCRIPTION

This module is deprecated. please use CGI::Builder::GetPageName istead.  Thanks.

=head1 SEE ALSO

CGI::Builder::GetPageName

=head1 AUTHOR

Tomohiro Teranishi <tomohiro.teranishi+cpan@gmail.com>

=head1 COPYRIGHT

This program is distributed under the Artistic License

=cut
