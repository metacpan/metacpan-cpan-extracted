
# Base class for right-to-left languages (Arabesque and Hebraic script)
package Apache::MP3::L10N::RightToLeft;
use Apache::MP3::L10N;
$VERSION = '20020610';
@ISA = qw(Apache::MP3::L10N);

# Directionality hacks
sub left      { 'right' }
sub right     { 'left'  }
sub direction { 'rtl'   }
1;

