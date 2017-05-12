#!/usr/bin/env perl
use strict;

=head1 NAME

cgiConsole.pl

=head1 DESCRIPTION


=head1 SYNOPSIS

http://your.server.xxx/cgi/manage/cgiSBS-info.pl

=head1 ARGUMENTS

=over 4

=item config=sbsconfigfile.xml

the file

=back

=head1 OPTIONS

=over 4

=item help=1

=back

=head1 COPYRIGHT

Copyright (C) 2004-2005  Geneva Bioinformatics www.genebio.com

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
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

=head1 AUTHORS

Alexandre Masselot, www.genebio.com

=cut

BEGIN{
  push @INC, '.';
}
BEGIN{
  eval{
    require DefEnv;
    DefEnv::read('env.def');
  };
}

use CGI;
use CGI::Carp qw(fatalsToBrowser warningsToBrowser);
use Pod::Usage;
use BatchSystem::SBS;

my $query=new CGI;

my $outputformat=$query->param('outputformat')||'text';
if($outputformat=~/^(text|json)$/){
  print $query->header(-type=>'text/plain');
}elsif($outputformat=~/^(xml)$/){
  print $query->header(-type=>'xml');
}elsif($outputformat=~/^(html)$/){
  print $query->header(-type=>'text/html');
}

my $configfile=$query->param('config');
unless ($configfile){
  require Phenyx::Config::GlobalParam;
  Phenyx::Config::GlobalParam::readParam();
  $configfile=Phenyx::Config::GlobalParam::get('phenyx.batch.configfile');
}
print STDERR "configfile=[$configfile]\n";
die "no configfile could be detected ([config] argument for example)" unless $configfile;

my $sbs=BatchSystem::SBS->new;
$sbs->readConfig(file=>$configfile);
$sbs->scheduler->__joblist_pump();
$sbs->scheduler->resourcesStatus_init();
$sbs->scheduler->queuesStatus_init();

my @request=$query->param('request');
unless (@request){
  print $sbs->scheduler;
  exit(0);
}


my @schedRequest;
my @batchRequest;
foreach (@request){
  foreach (split /,/){
    if(/scheduler\.(.*)/){
      push @schedRequest, $1;
      next;
    }
    if (/batchsystem\.(.*)/){
      push @batchRequest, $1;
      next;
    }
    die "unknown request [$_]";
  }
}
my %htot;
if(@schedRequest){
  my $h=$sbs->scheduler->dataRequest(request=>join(',', @schedRequest));
  $htot{scheduler}=$h;
}
if(@batchRequest){
  my $h=$sbs->dataRequest(request=>join(',', @batchRequest));
  $htot{batchsystem}=$h;
}
if(lc($outputformat) eq 'json'){
  require JSON;
  print JSON::objToJson(\%htot,{pretty => 1, indent => 2});
}
