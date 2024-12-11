use v5.36;

package TestCheck;

use Exporter 'import';
our @EXPORT = qw( diags_from_treesitter );

package App {
   sub format_file ( $, $file, $line = undef ) {
      return $file unless defined $line;
      sprintf "%s line %d", $file, $line;
   }
   sub format_literal ( $, $str )      { "'$str'" }
}

sub diags_from_treesitter ( $check, $code )
{
   my $tree = $check->parse_perl_string( $code );

   # override check class's ->parse_perl_file method
   my $checkclass = ref $check;
   no strict 'refs';
   local *{"${checkclass}::parse_perl_file"} = sub { return $tree; };

   my @diags;

   no warnings 'once';
   local *App::diag = sub ( $, @args ) { push @diags, join "", @args; };

   $check->check_file( "lib/FILE.pm" );

   return @diags;
}

0x55AA;
