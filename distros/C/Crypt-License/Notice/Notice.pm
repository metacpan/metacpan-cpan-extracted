#!/usr/bin/perl
#
#use diagnostics;
package Crypt::License::Notice;

use vars qw($VERSION);

$VERSION = do { my @r = (q$Revision: 1.00 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

use strict;

######## DEFAULTS

my $sendmail_command	= '/usr/lib/sendmail -t -oi';
my $tmp_dir		= '/tmp';
my $intervals		= '5d,30d,60d';
my $TO			= 'license@bizsystems.com';
my %multx = (
	'w'	=> 604800,
	'd'	=> 86400,
	'h'	=> 3600,
	'm'	=> 60,
	's'	=> 1,
);

##################

sub check($$\{}) {
  my($self,$p) = @_;
  return () unless 
	exists $p->{expires} && $p->{expires} && 
	$p->{expires} !~ /[^\d]/ && $p->{expires} > 0 &&
	exists $p->{path} && $p->{path} && (-r $p->{path});
  $sendmail_command	= $p->{ACTION} if exists $p->{ACTION};
  $tmp_dir		= $p->{TMPDIR} if exists $p->{TMPDIR};
  $intervals		= $p->{INTERVALS} if exists $p->{INTERVALS};
  $TO			= $p->{TO} if exists $p->{TO};
  
  return () unless (-d $tmp_dir) && (-w $tmp_dir);

  @_ = split(',',$intervals);
  foreach(0..$#_) {
    my $multx = 's';
    $multx = chop $_[$_] if $_[$_] =~ /[wdhms]$/;
    die "illegal character in interval $_[$_], " . __PACKAGE__ 
	if $_[$_] =~ /[^\d]/;
    $_[$_] *= $multx{$multx};
  }
  my $expiring;
  my @intervals = sort {$b <=> $a;} @_;
  foreach(@intervals) {
    last if $_ < $p->{expires};
    $expiring = $_;
  }
  if ( $expiring ) {
    my $user = (getpwuid( (stat($p->{path}))[4] ))[0];
    my $nf = "$tmp_dir/$user.bln";		# notice file
    my $ctime = ( -e $nf ) ? (stat($nf))[10] : 0;
    my $now = time;
    if ( $ctime + $expiring < $now ) {
      open(LIC,$p->{path}) or return ();	# sorry, missing license
      my $slurp = '';
      while(<LIC>) {
	next unless $slurp || $_ =~ /:\s*:/;
	$slurp .= $_;
      }
      close LIC;
# now send the message
      open ( MAIL, "|$sendmail_command" ) or return ();
      select MAIL;
      $| = 1;
      select STDOUT;
      print MAIL <<EOMxx12345;
From: $user
To: $TO
Subject: LICENSE EXPIRATION

$slurp
EOMxx12345
      close MAIL;

      open(N,">$nf.tmp") or return ();		# should not get here
      select N;
      $| = 1;
      select STDOUT;
      print N "$p->{expires}\n";
      close N;
      rename "$nf.tmp", $nf;
    }
  }
  return @intervals;
}
1;

__END__

=head1 NAME

  Crypt::License::Notice -- perl extension for License

=head1 SYNOPSIS

  require Crypt::License::Notice;

  Crypt::License::Notice->check($input_hash)

=head1 DESCRIPTION

=over 4

=item Crypt::License::Notice->check($input_data_ptr)
	
  $input_hash_ptr = {	# optional parameters
	'ACTION'	=> 'default /usr/lib/sendmail -t -oi',
	'TMPDIR'	=> 'default /tmp',
	'INTERVALS'	=> 'default 5d,30d,60d',
	'TO'		=> 'default license@bizsysetms.com',
  # mandatory parameters
	'path'		=> 'path to LICENSE',
	'expires'	=> 'seconds until expiration',
  };

The B<check> routine will send a notice message at the requested or default
intervals IF the temporary directory exists and is writeable AND if the
B<expires> parameter exists and is positive AND the LICENSE file exists and is
readable. Substitutes can be made for the default values for ACTION, TMPDIR,
TO, and INTERVALS. Valid suffixes for INTERVALS are w=weeks,
d=days, h=hours, m=minutes, s=seconds (default if no suffix).

B<check> returns an empty array on any error or if B<expires> does not exist. It returns an
array of the INTERVALS values in in seconds, highest to lowest, if a check
is performed.

Note that the b<Notice.pm> hash can be combined with the hash used for the
B<License.pm> module and that they share common variables B<path> and
B<expires>. All other B<License.pm> hash keys are lower while B<Notice.pm>
hash keys are upper case.

=back

=head1 COPYRIGHT

=head1 COPYRIGHT and LICENSE

  Copyright 2002 Michael Robinton, BizSystems.

This module is free software; you can redistribute it and/or modify it
under the terms of either:

  a) the GNU General Public License as published by the Free Software
  Foundation; either version 1, or (at your option) any later version,

  or

  b) the "Artistic License" which comes with this module.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either
the GNU General Public License or the Artistic License for more details.

You should have received a copy of the Artistic License with this
module, in the file ARTISTIC.  If not, I'll be glad to provide one.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

=head1 AUTHOR

Michael Robinton, BizSystems <michael@bizsystems.com>

=cut

1;
