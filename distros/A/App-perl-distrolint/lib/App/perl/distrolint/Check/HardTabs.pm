#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2023 -- leonerd@leonerd.org.uk

use v5.36;
use Object::Pad 0.807;

class App::perl::distrolint::Check::HardTabs 0.07;

apply App::perl::distrolint::CheckRole::EachFile;

use constant DESC => "check that no source code file contains HT characters";
use constant SORT => 8;

use File::Slurper qw( read_lines );

=head1 NAME

C<App::perl::distrolint::Check::HardTabs> - check that no source file contains HT characters

=head1 DESCRIPTION

This checks that no source code file contains horizontal tab (HT) characters.

It operates on all the files considered to be "source", except that it will
ignore any F<.c> file if a corresponding F<.xs> file is also present, as
F<xsubpp> is known to generate tab characters in its output, and this would
leads to many false positives.

=cut

method run ( $app )
{
   return $self->run_for_each_source_file( check_file => );
}

method check_file ( $file )
{
   # Skip any .c file that appears to be generated from a .xs file
   return 1 if $file =~ m/\.c$/ and -f $file =~ s/\.c$/.xs/r;

   my @lines = read_lines $file;

   foreach my $i ( 0 .. $#lines ) {
      next unless $lines[$i] =~ m/\t/;

      App->diag( App->format_file( $file, $i+1 ), " contains a \\t character" );
      return 0;
   }

   return 1;
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
