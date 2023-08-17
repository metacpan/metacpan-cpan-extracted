#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2023 -- leonerd@leonerd.org.uk

use v5.36;
use Object::Pad 0.800;

package App::perl::distrolint 0.02;
class App::perl::distrolint;

use List::Util qw( max );
use Module::Pluggable::Object;

use String::Tagged::Terminal;

=head1 NAME

C<App::perl::distrolint> - distribution-wide linting tools for Perl distributions

=head1 SYNOPSIS

   use App::perl::distrolint;

   exit App::perl::distrolint->new->run( @ARGV );

=head1 DESCRIPTION

This module implements an application for applying various code-linting tests
across the source code for an entire Perl distribution. The individual checks
performed are described more in the various C<App::perl::distrolint::Check::*>
modules.

At present in this very early version, many of these checks are very
opinionated, doing things specific to the way I personally lay out my code. I
fully imagine that at some point I'll get around to adding more flexibility
here, via some kind of configuration system, whereby other users can change or
disable various checks as they see fit to suit their own coding style. This
distribution currently exists largely to allow people to see the kinds of
things that are possible, and also acts as a demonstration of the use of
L<Text::Treesitter> and F<tree-sitter-perl> to be used as a static linting
tool for Perl source code.

=cut

my $finder = Module::Pluggable::Object->new(
   search_path => [qw( App::perl::distrolint::Check )],
   require     => 1,
);

my %COL = (
   red    => 1,
   green  => 2,
   yellow => 3,
);

my %FORMAT = (
   bullet => { bold => 1, fgindex => $COL{yellow} },
   pass   => { bold => 1, fgindex => $COL{green} },
   fail   => { bold => 1, fgindex => $COL{red} },
   diag   => { italic => 1 },
);

my $PASS = String::Tagged::Terminal->new_tagged( "PASS", $FORMAT{pass}->%* );
my $FAIL = String::Tagged::Terminal->new_tagged( "FAIL", $FORMAT{fail}->%* );

method run ( @argv )
{
   my @checks = $self->checks;

   my $namelen = max map { length $_->{name} } @checks;

   my $totalcount = 0;
   my $passcount  = 0;

   foreach my $check ( @checks ) {
      my $name = $check->{name};
      $name .= "." x ($namelen - length $name);

      String::Tagged::Terminal->new
         ->append( " " )
         ->append_tagged( "*", $FORMAT{bullet}->%* )
         ->append( sprintf " %s (%s)", $name, $check->{desc} )
         ->say_to_terminal;

      my $ok = $check->{obj}->run( $self );

      String::Tagged::Terminal->from_sprintf( "  -- %s",
         $ok ? $PASS : $FAIL
      )->say_to_terminal;

      $totalcount++;
      $passcount++ if $ok;
   }

   print  "\n";
   printf "%d of %d checks passed", $passcount, $totalcount;
   printf " (%d FAILed)", $totalcount - $passcount if $passcount < $totalcount;
   print  "\n";

   return 1 if $passcount < $totalcount;
   return 0;
}

method checks
{
   my @checks = map {
      my $pkg = $_;
      {
         obj  => $pkg->new,
         name => $pkg =~ s/^App::perl::distrolint::Check:://r,
         desc => $pkg->DESC,
         sort => $pkg->SORT,
      }
   } $finder->plugins;

   return sort { $a->{sort} <=> $b->{sort} } @checks;
}

method diag ( $format, @args )
{
   my $str = String::Tagged::Terminal->from_sprintf( $format, @args );

   # TODO: wish for $st->apply_tags()
   $str->apply_tag( 0, -1, $_, $FORMAT{diag}{$_} ) for keys $FORMAT{diag}->%*;

   foreach my $line ( $str->split( qr/\n/ ) ) {
      ( "    > " . $line )->say_to_terminal;
   }
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
