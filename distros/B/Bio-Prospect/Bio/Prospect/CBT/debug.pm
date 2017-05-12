# pm -- a perl package template
# $Id: debug.pm,v 1.1 2003/04/30 21:11:21 rkh Exp $
# @@banner@@

package CBT::debug;
our $VERSION = '$Revision: 1.1 $ ';
our $level = $ENV{DEBUG} || 0;
our $trace_uses = exists $ENV{PERL_TRACE_USES} ? $ENV{PERL_TRACE_USES} : $level;
CBT::debug::identify_file() if ($CBT::debug::trace_uses);

use warnings;
use strict;


use Exporter;
our @EXPORT = qw( advise );
our @EXPORT_OK = (@EXPORT, qw( advise ));
our %EXPORT_TAGS = qw( );

#use Getopt::Long;
#our %options = ( debuglevel => $ENV{DEBUG} );
#our @options = ( 'debug|d+' => sub { $options{debuglevel}++ },
#				 'debuglevel=i' => \$options{debuglevel} );
#my $p = new Getopt::Long::Parser;
#$p->configure( qw(gnu_getopt pass_through) );
#$p->getoptions( @options );
#use Data::Dumper;
#print Dumper(\%options), "\n";

use Carp;

sub identify_file
  {
  my ($p,$f,$l) = caller();
  my $v = eval "return \$${p}::VERSION" || 'N/A';
  print(STDERR "# use $p (f:$f, v:$v)\n");
  }

sub advise
  {
  my $level = shift;
  my $pkg = (caller())[0];
  carp( "$pkg ($level):", @_ ) if eval { $pkg::DEBUG >= $level }
  }

sub RCSVersion
  {
  my $rcsstring = shift;
  return $1 if $rcsstring =~ m/\$\bRevision: (\d.+)\$/;
  return $1 if $rcsstring =~ m/\$\bId: .+,v (\d.+)\$/;
  return $1 if $rcsstring =~ m/^[\d.]+$/;
  return undef;
  }

1;

=head1 NAME

pm -- a perl package template

S<$Id: debug.pm,v 1.1 2003/04/30 21:11:21 rkh Exp $>

=head1 SYNOPSIS

C<pm [options]>

=head1 DESCRIPTION

B<program> does nothing particularly useful.

=head1 INSTALLATION

Put this file in your perl lib directory (usually /usr/local/perl5/lib) or
one of the directories in B<$PERL5LIB>.

@@banner@@

=cut
