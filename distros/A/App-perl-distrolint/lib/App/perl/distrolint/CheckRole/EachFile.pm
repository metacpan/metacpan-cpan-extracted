#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2023 -- leonerd@leonerd.org.uk

use v5.36;
use Object::Pad 0.800;

role App::perl::distrolint::CheckRole::EachFile 0.01;

use File::Find ();
use File::Basename qw( basename );

use List::Util 1.29 qw( any );

=head1 NAME

C<App::perl::distrolint::CheckRole::EachFile> - role for checks that iterate over files

=head1 DESCRIPTION

This role provides a number of helper trampoline methods for implementing
check classes whose logic should iterate over various types of file found in
the distribution source.

=cut

=head1 METHODS

The following are trampoline methods. The first argument should either be a
code reference or a method name as a plain string. The remaining arguments
will be passed to the invoked code, along with the name of each selected file.

=cut

my @SKIP_TOP = qw(
   blib
   _build
);

method _run_foreach ( $opts, $method, @args )
{
   my $ok = 1;

   File::Find::find({
      no_chdir => 1,
      preprocess => sub {
         return sort { $a cmp $b } @_;
      },
      wanted => sub {
         my $path = $_;

         return if $path eq ".";
         $path =~ s{^\./}{};

         my $basename = basename $path;

         # skip hidden
         $File::Find::prune = 1, return if $basename =~ m{^\..};

         # skip toplevels
         $File::Find::prune = 1, return if any { $_ eq $path } @SKIP_TOP;

         -f $path or return;

         return if $opts->{if_basename} and $basename !~ $opts->{if_basename};

         $ok &= $self->$method( $path, @args );
      },
   }, "." );

   return $ok;
}

=head2 run_for_each_file

   $check->run_for_each_file( $method, @args );

Invokes the code once for every file found in the distribution.

=cut

method run_for_each_file ( $method, @args )
{
   $self->_run_foreach( {}, $method, @args );
}

my %BASENAMES = (
   perl => qr/\.PL$|\.pl$|\.pm$|\.t$/,
   xs   => qr/\.xs$/,
   c    => qr/\.c$|\.h$/,
);
my $SOURCE_BASENAMES = do {
   my $re = join "|",
      @BASENAMES{qw( perl xs c )},
      qr/^typemap$/;
   qr/$re/;
};

=head2 run_for_each_perl_file

   $check->run_for_each_perl_file( $method, @args );

Invokes the code once for every perl source file found. These will be files
whose extension is F<.PL>, F<.pl>, F<.pm> or F<.t>.

=cut

method run_for_each_perl_file ( $method, @args )
{
   # TODO: Also check executables in bin/ that start with a perl shebang
   $self->_run_foreach( { if_basename => $BASENAMES{perl} }, $method, @args );
}

=head2 run_for_each_test_file

   $check->run_for_each_test_file( $method, @args );

Invokes the code once for every test source file found. These will be files
whose extension is F<.t>.

=cut

method run_for_each_test_file ( $method, @args )
{
   $self->_run_foreach( { if_basename => qr/\.t$/ }, $method, @args );
}

=head2 run_for_each_source_file

   $check->run_for_each_source_file( $method, @args );

Invokes the code once for every source file found. These will be all the Perl
source files, plus files whose extension is F<.c>, F<.h>, or F<.xs>, or files
named F<typemap>.

=cut

method run_for_each_source_file ( $method, @args )
{
   $self->_run_foreach( { if_basename => $SOURCE_BASENAMES }, $method, @args );
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
