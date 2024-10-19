#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2021-2023 -- leonerd@leonerd.org.uk

use v5.26;
use warnings;
use utf8;

use Object::Pad 0.807;

package App::sdview::Output::Plain 0.20;
class App::sdview::Output::Plain :strict(params);

inherit App::sdview::Output::Formatted;

use constant format => "plain";

=head1 NAME

C<App::sdview::Output::Plain> - generate plain-text output from L<App::sdview>

=head1 SYNOPSIS

   $ sdview README.pod -o plain > README.txt

=head1 DESCRIPTION

This output module allows L<App::sdview> to generate output text without any
special formatting, other than indentation and spacing applied in plain text
characters. The generated output should be similar to the formatted output
rendered for terminal use, except with none of the embedded terminal control
codes used to apply formatting.

=cut

method setup_output ()
{
   STDOUT->binmode( ":encoding(UTF-8)" );
}

method width ()
{
   return 80;
}

method say ( @s )
{
   say map { "$_" } @s;  # stringify to remove the String::Tagged formatting
}

# Ugh this is all backwards; the ::Terminal plugin really wants to be written
# to use this instead
method generate ( @p )
{
   open my $outh, ">:encoding(UTF-8)", \( my $outbuf = "" );
   {
      my $oldh = select;
      select $outh;

      $self->output( @p );

      select $oldh;
   }
   close $outh;

   return Encode::decode( "UTF-8", $outbuf );
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
