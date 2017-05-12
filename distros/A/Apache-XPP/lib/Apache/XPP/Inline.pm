# Apache::XPP::Inline
# -------------
# $Revision: 1.1 $
# $Date: 2002/01/16 22:06:46 $
# -----------------------------------------------------------------------------
=head1 NAME

Apache::XPP::Inline - Use XPP as an inline source filter

=cut

package Apache::XPP::Inline;

=head1 SYNOPSIS

 use Apache::XPP::Inline;
 
 XPML CODE <?= "GOES" ?> HERE

=head1 REQUIRES

 Apache::XPP
 Filter::Util::Call

=cut

use Carp;
use strict;
use vars qw( $AUTOLOAD $debug $debuglines );

BEGIN {
    $Apache::XPP::Inline::REVISION	= (qw$Revision: 1.1 $)[-1];
    $Apache::XPP::Inline::VERSION	= '2.02';
}

=head1 EXPORTS

Nothing

=head1 DESCRIPTION

The Apache::XPP::Inline module allows access to XPP parsing in an inline fashion.
After a C<use Apache::XPP::Inline;> statement, the remaining source code will be
interpreted as XPML, and parsed appropriately.

=cut

use Filter::Util::Call;

sub import {
	my $class	= shift;
	filter_add( sub {
		my $caller	= caller;
		my $status;
		my $data	= '';
		my $code	= '';
		
		while ($status = filter_read(1024)) {
			if ($status <= 0) {
				$_	= $code;
				return $status;
			}
			
			$data	.= $_;
			if ($status < 1024) {
				$data	=~ s/'/\\'/g;
				$data	=~ s/\n/' . "\\n" . '/g;
				
				$code	= join( "\n",
								"use Apache::XPP;",
								"my \$code = '${data}';",
								"my \$xpml = Apache::XPP->new( { source => \$code } );",
								"\$xpml->run();\n"
							);
			}
			
			$_		= $code;
		}
		
		return length($_);
	})
}

1;

__END__

=head1 REVISION HISTORY

$Log: Inline.pm,v $

=head1 SEE ALSO

perl(1).

=head1 KNOWN BUGS

None

=head1 COPYRIGHT

Copyright (c) 2002, Gregory Williams. All Rights Reserved. This module is free
software. It may be used, redistributed and/or modified under the terms
of the GNU Lesser General Public License as published by the Free Software
Foundation.

You should have received a copy of the GNU Lesser General Public License
along with this library; if not, write to the Free Software Foundation, Inc.,
59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

=head1 AUTHORS

 Gregory Williams <greg@evilfunhouse.com>

=cut

