package CGI::Untaint::Winfilename;
use strict;

BEGIN {
	use Exporter ();
	use vars qw ($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
	$VERSION     = 0.1;
	@ISA         = qw (Exporter);
	#Give a hoot don't pollute, do not export more than needed by default
	@EXPORT      = qw ();
	@EXPORT_OK   = qw ();
	%EXPORT_TAGS = ();
}
use base 'CGI::Untaint::object';

########################################### main pod documentation begin ##

=head1 NAME

CGI::Untaint::Winfilename - CGI::Untaint::Winfilename - untaint Windows filename values from CGI programs

=head1 SYNOPSIS

  use CGI::Untaint::Winfilename;
  my $handler = CGI::Untaint->new( $q->Vars() );
  my $filename = $handler->extract( -as_winfilename => 'some_feature' );



=head1 DESCRIPTION
This input handler verifies that it has a a valid (Windows) filename. It provides the regex and a subroutine for a handler.
Extensive test cases are provided.

=head1 INSTALLATION

perl Build.PL
./Build
./Build test
./Build install



=head1 BUGS

While it is valid to end a UNIX filename with \# ! and % I haven't got those incorporated into the regular expression.
Test cases exist but are currently commented out.

Please report any fixes and other bugs to L<http://rt.cpan.org/>.

=head1 SUPPORT

Bug reports welcome, see above.


=head1 AUTHOR

	Dana Hudes
	CPAN ID: DHUDES
	dhudes@hudes.org
	http://www.hudes.org


=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

perl(1). CGI::Untaint, CGI::Untaint::Filenames, Test::CGI::Untaint

=cut

############################################# main pod documentation end ##




sub _untaint_re { 
=head1 Rules
Two groups of characters: those valid anywhere and those valid only at the end of the string.

=cut
# qr/^[\w\+\[\]\^#\/_]*[\$\%!]$/ ;
qr  /^(([a-zA-Z]:)?\\?[\w\+_\040\(\)\{\}\[\]\/\-\^,\.;&%@\$!\\~\#]+)$/;
}





1; #this line is important and will help the module return a true value
__END__

