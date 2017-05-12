# $Id: Exceptions.pm,v 1.12 2003/11/18 19:45:45 rkh Exp $
# @@banner@@

=head1 NAME

Bio::Prospect::Exceptions -- Set of Prospect specific exceptions.

S<$Id: Exceptions.pm,v 1.12 2003/11/18 19:45:45 rkh Exp $>

=head1 SYNOPSIS

=head1 DESCRIPTION

B<Bio::Prospect::Exceptions> is a set of exceptions specifically for
the Prospect perl package.  There excpetions are derived from
CBT::Exception

=head1 SEE ALSO

B<CBT::Exception>

=cut

use Error qw(:try);
use strict;
use warnings;


# include this directory so that we can use CBT::Execption
BEGIN {
  (my $thisDir = __FILE__) =~ s#Exceptions.pm$##;
  unshift(@INC,$thisDir);
}

package Bio::Prospect::Exception;
use base 'CBT::Exception';
use vars qw( $VERSION );
$VERSION = sprintf( "%d.%02d", q$Revision: 1.12 $ =~ /(\d+)\.(\d+)/ );


package Bio::Prospect::SequenceTooLarge;
use base 'Bio::Prospect::Exception';

package Bio::Prospect::BadUsage;
use base 'Bio::Prospect::Exception';

package Bio::Prospect::RuntimeError;
use base 'Bio::Prospect::Exception';

1;
