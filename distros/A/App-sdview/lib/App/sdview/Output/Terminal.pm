#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2021-2024 -- leonerd@leonerd.org.uk

use v5.26;
use warnings;
use utf8;

use Object::Pad 0.807;

package App::sdview::Output::Terminal 0.20;
class App::sdview::Output::Terminal :strict(params);

inherit App::sdview::Output::Formatted;

use constant format => "terminal";

use Scalar::Util qw( blessed );
use String::Tagged::Terminal 0.08; # for OSC 8 hyperlink support
use Term::Size;

=head1 NAME

C<App::sdview::Output::Terminal> - generate terminal formatted output from L<App::sdview>

=head1 SYNOPSIS

   $ sdview README.pod -o terminal

(though this is likely the default output mode)

=head1 DESCRIPTION

This output module generates formatted output with embedded terminal control
codes, allowing colours and formatting information to be displayed on a
terminal.

By default, if the process standard output stream appears to be a TTY device,
the output is piped via F<less -R> to act as a simple iteractive pager.

=cut

=head1 OPTIONS

=over 4

=item -O nopager

Disables use of F<less> as an output pager, causing output to be printed to
the terminal directly.

=item -O width=NN

Overrides the detected width of the terminal.

=back

=cut

field $pager :param = !!1;

# TODO: Is this the neatest way to do this?
ADJUST :params ( :$nopager = undef ) {
   $pager = !!0 if $nopager;
}

field $width :param :reader = scalar Term::Size::chars;

method setup_output ()
{
   if( $pager and -T STDOUT ) {
      open my $outh, "|-", "less", "-R";
      $outh->binmode( ":encoding(UTF-8)" );
      select $outh;
   }
   else {
      STDOUT->binmode( ":encoding(UTF-8)" );
   }
}

method say ( @s )
{
   say map {
      blessed $_ ? String::Tagged::Terminal->new_from_formatting($_)->build_terminal : "$_"
   } @s;
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
