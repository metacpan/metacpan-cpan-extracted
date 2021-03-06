
#############################################################################
## $Id: Conf.pm 3666 2006-03-11 20:34:10Z spadkins $
#############################################################################

package App::Conf;
$VERSION = (q$Revision: 3666 $ =~ /(\d[\d\.]*)/)[0];  # VERSION numbers generated by svn

use App;
use App::Reference;
@ISA = ( "App::Reference" );

use strict;

#############################################################################
# dump()
#############################################################################

=head2 dump()

    * Signature: $perl = $conf->dump();
    * Param:     void
    * Return:    $perl      text
    * Throws:    App::Exception
    * Since:     0.01

    Sample Usage: 

    $conf = $context->conf();
    print $conf->dump(), "\n";

=cut

use Data::Dumper;

sub dump {
    my ($self) = @_;
    my %copy = %$self;
    delete $copy{context};   # don't dump the reference to the context itself
    my $d = Data::Dumper->new([ \%copy ], [ "conf" ]);
    $d->Indent(1);
    return $d->Dump();
}

1;

