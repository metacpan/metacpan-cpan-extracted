package App::PerlShell::Plugin::TextTable;

########################################################
# AUTHOR = Michael Vincent
# www.VinsWorld.com
########################################################

use strict;
use warnings;
use Pod::Usage;
use Pod::Find qw( pod_where );

eval "use Text::Table";
if ($@) {
    print "Text::Table required.\n";
    return 1;
}
eval "use Array::Transpose";
if ($@) {
    print "Array::Transpose required.\n";
    return 1;
}

use Exporter;

our @EXPORT = qw(
  TextTable
  texttable
  rows
  cols
);

our @ISA = qw ( Text::Table Exporter );

sub TextTable {
    pod2usage(
        -verbose => 2,
        -exitval => "NOEXIT",
        -input   => pod_where( {-inc => 1}, __PACKAGE__ )
    );
}

########################################################

sub texttable {
    my $table = Text::Table->new(@_);
    return bless $table, __PACKAGE__;
}

sub rows {
    my ( $self, @arg ) = @_;
    return $self->load(@arg);
}

sub cols {
    my ( $self, @arg ) = @_;
    return $self->load( transpose( \@arg ) );
}

1;

__END__

=head1 NAME

TextTable - Create Text::Table

=head1 SYNOPSIS

 use App::PerlShell::Plugin::TextTable;

=head1 DESCRIPTION

This module implements table creation with B<Text::Table>.

=head1 COMMANDS

=head2 TextTable - provide help

Provides help.

=head1 METHODS

=head2 texttable - create table object

 [$table =] texttable [OPTIONS];

Create B<Text::Table> object.  See B<Text::Table> for B<OPTIONS>.  

=head2 cols - load table by columns

 $table->cols([array],[...]);

Load table by columns.  Array references provided will make up the columns 
of the B<Text::Table> table.

=head2 rows - load table by rows

 $table->rows([array],[...]);

Load table by rows.  Array references provided will make up the rows 
of the B<Text::Table> table.

=head1 EXAMPLES

=head2 Simple Usage

  use App::PerlShell::Plugin::TextTable;
  @a1 = qw (1 1);
  @a2 = qw (2 2);

  $table = texttable("One", "Two");
  $table->cols(\@a1,\@a2);
  print $table;

=head2 Perl Packet Crafter
  [...]
  use PPC::Plugin::Trace;
  $t = trace 'www.google.com';

  use App::PerlShell::Plugin::TextTable;
  $table = texttable("Sent\nTTL", "IP Addr", "Time", "Recv\nTTL");
  $table->cols(
      [ map { [$_->layers]->[1]->ttl } $t->sent ],
      [ map { [$_->layers]->[1]->src } $t->recv ],
      [ $t->time ],
      [ map { [$_->layers]->[1]->ttl } $t->recv ]
  );
  print $table;

=head1 SEE ALSO

L<Text::Table> L<Array::Transpose>

=head1 LICENSE

This software is released under the same terms as Perl itself.
If you don't know what that means visit L<http://perl.com/>.

=head1 AUTHOR

Copyright (c) 2013, 2016 Michael Vincent

L<http://www.VinsWorld.com>

All rights reserved

=cut
