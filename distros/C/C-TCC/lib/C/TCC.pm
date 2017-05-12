# Copyright (C) 2008 Tsukasa Hamano <hamano@cpan.org>
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307  USA
#
# $Id: TCC.pm,v 1.8 2008-03-18 06:32:41 hamano Exp $

package C::TCC;

use 5.008008;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use C::TCC ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
TCC_OUTPUT_MEMORY
TCC_OUTPUT_EXE
TCC_OUTPUT_DLL
TCC_OUTPUT_OBJ
TCC_OUTPUT_PREPROCESS
TCC_OUTPUT_FORMAT_ELF
TCC_OUTPUT_FORMAT_BINARY
TCC_OUTPUT_FORMAT_COFF
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = ( @{ $EXPORT_TAGS{'all'} });

our $VERSION = '0.05';

use constant {
    TCC_OUTPUT_MEMORY     => 0,
    TCC_OUTPUT_EXE        => 1,
    TCC_OUTPUT_DLL        => 2,
    TCC_OUTPUT_OBJ        => 3,
    TCC_OUTPUT_PREPROCESS => 4,
    TCC_OUTPUT_FORMAT_ELF    => 0,
    TCC_OUTPUT_FORMAT_BINARY => 1,
    TCC_OUTPUT_FORMAT_COFF   => 2,
};

require XSLoader;
XSLoader::load('C::TCC', $VERSION);

# Preloaded methods go here.

sub new
{
    my $this = shift;
    my $class = ref($this) || $this;
    my $self = {};
    bless $self, $class;

    $self->{state} = tcc_new();
    return $self;
}

sub DESTROY
{
    my $self = shift;
    tcc_delete($self->{state});
}

#sub enable_debug
#{
#    my $self = shift;
#    tcc_enable_debug($self->{state});
#}

sub add_include_path
{
    my $self = shift;
    my $pathname = shift;
    tcc_add_include_path($self->{state}, $pathname);
}

sub add_sysinclude_path
{
    my $self = shift;
    my $pathname = shift;
    tcc_add_include_path($self->{state}, $pathname);
}

sub define_symbol
{
    my $self = shift;
    my $sym = shift;
    my $value = shift;
    tcc_define_symbol($self->{state}, $sym, $value);
}

sub undefine_symbol
{
    my $self = shift;
    my $sym = shift;
    tcc_undefine_symbol($self->{state}, $sym);
}

sub add_file
{
    my $self = shift;
    my $filename = shift;
    tcc_add_file($self->{state}, $filename);
}

sub compile_string
{
    my $self = shift;
    my $buf = shift;
    tcc_compile_string($self->{state}, $buf);
}

sub set_output_type
{
    my $self = shift;
    my $output_type = shift;
    tcc_set_output_type($self->{state}, $output_type);
}

#

sub output_file
{
    my $self = shift;
    my $filename = shift;
    tcc_output_file($self->{state}, $filename);
}

sub run
{
    my $self = shift;
    my @args = @_;
    tcc_run($self->{state}, \@args);
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

C::TCC - An interface to the TCC(Tiny C Compiler)

=head1 SYNOPSIS

  use C::TCC;
  my $tcc = C::TCC->new();
  $tcc->compile_string('int main(){printf("Hello World.\n"); return 0;}');
  $tcc->run();

=head1 DESCRIPTION

The perl module TCC provides an interface to the TCC(Tiny C Compiler)
See http://fabrice.bellard.free.fr/tcc/ for more information on TCC.

=head1 METHODS

=head2 new
Create a new TCC compilation context.

=head2 add_include_path
Add include path

=head2 add_sysinclude_path
Add in system include path

=head2 define_symbol
Define preprocessor symbol 'sym'. Can put optional value

=head2 undefine_symbol
Undefine preprocess symbol 'sym'

=head2 add_file
Add a file (either a C file, dll, an object, a library or an ld
script). Return -1 if error.

=head2 compile_string
Compile a string containing a C source. Return non zero if error.

=head2 set_output_type
set output type. MUST BE CALLED before any compilation

TCC_OUTPUT_MEMORY

TCC_OUTPUT_EXE

TCC_OUTPUT_DLL

TCC_OUTPUT_OBJ

TCC_OUTPUT_PREPROCESS

=head2 output_file
output an executable, library or object file. DO NOT call
relocate() method before.

=head2 run
link and run main() function and return its value. DO NOT call
relocate() before.


=head1 SEE ALSO

TCC(Tiny C Compiler) is created by Fabrice Bellard.

http://fabrice.bellard.free.fr/tcc/

=head1 AUTHOR

Tsukasa Hamano <hamano@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 Tsukasa Hamano <hamano@cpan.org>

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307  USA

=cut
