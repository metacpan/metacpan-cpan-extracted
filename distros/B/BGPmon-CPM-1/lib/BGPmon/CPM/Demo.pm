package BGPmon::CPM::Demo;

use 5.010001;
use strict;
use warnings;
use Storable;
use Data::Dumper;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use BGPmon::CPM::Demo ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw( getAvailableLists 
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '1.03';

sub initLists
{
  my @cert_array = (
         {'prefix' => '152.91.0.0/16', more_sp => 'YES', less_sp => 'NO', reason => 'CERT main prefix block'},
         {'prefix' => '152.91.11.1/32', more_sp => 'NO', less_sp => 'NO', reason => 'DNS: cert.gov.au'},
         {'prefix' => '203.2.208.4/32', more_sp => 'NO', less_sp => 'NO', reason => 'DNS: cert.gov.au'},
         {'prefix' => '202.65.12.72/32', more_sp => 'NO', less_sp => 'NO', reason => 'DNS: gov.au'},
         {'prefix' => '193.0.14.129/32', more_sp => 'NO', less_sp => 'NO', reason => 'DNS: ROOT'}
	 );
  saveList('CERT', \@cert_array);
  
  my @NAB_array = (
         {'prefix' => '164.53.0.0/16', more_sp => 'YES', less_sp => 'NO', reason => 'NAB main prefix block'},
         {'prefix' => '202.65.12.72/32', more_sp => 'NO', less_sp => 'NO', reason => 'DNS: com.au'},
         {'prefix' => '202.139.83.3/32', more_sp => 'NO', less_sp => 'YES', reason => 'DNS: nab.com.au'},
         {'prefix' => '203.57.241.223/32', more_sp => 'NO', less_sp => 'YES', reason => 'DNS: nab.com.au'},
         {'prefix' => '203.57.240.223/32', more_sp => 'NO', less_sp => 'YES', reason => 'DNS: nab.com.au'}
	 );
  saveList('NAB', \@NAB_array);

  my @rio_trinto_array = (
         {'prefix' => '192.31.80.30/32', more_sp => 'NO', less_sp => 'NO', reason => 'DNS: com.'},
         {'prefix' => '204.74.99.100/32', more_sp => 'NO', less_sp => 'NO', reason => 'DNS: www.riotinto.com'},
         {'prefix' => '199.7.68.248/32', more_sp => 'NO', less_sp => 'NO', reason => 'DNS: riotinto.com'},
         {'prefix' => '204.74.114.248/32', more_sp => 'NO', less_sp => 'NO', reason => 'DNS: riotinto.com'}
	 );
  saveList('RioTinto', \@rio_trinto_array);

}  

sub createNewList
{
  my $list = shift;
  my @list_prefixes = ();  
  
  saveList($list, \@list_prefixes);
}

sub deleteList
{
  my $list = shift;
  my $dir = "/tmp/";
  $list = $dir.$list.".list";
  
  unlink($list);
}

sub exportList
{
  my $list = shift;
  my $dir = "/tmp/";
  $list = $dir.$list.".list";
  
  my $data = retrieve($list);
  if (!defined($data))
  {
    return undef;
  }
  my @arr;
  foreach my $val (@$data)
  {
     #print Dumper($val);
     if ($val ne undef)
     {
       push ( @arr, "$val->{'prefix'}, $val->{'more_sp'}, $val->{'less_sp'}, $val->{'reason'}");
     }  
  }
  return @arr;
}

sub getAvailableLists
{
  my @lists = ();
  my $d = "/tmp";
  opendir(DIR, $d);
  foreach my $file (readdir(DIR))
  {
    if ($file =~ /\.list$/)
    {
      ($file, undef) = split (/\./, $file);
      push (@lists, $file);
    }
  }
  closedir(DIR);

  return @lists;
}

sub getListData
{
  my $list = shift;
  my $dir = "/tmp/";
  $list = $dir.$list.".list";
  
  unless (-e $list) 
  {
    return undef;
  } 

  my $data = retrieve($list);
  if (!defined($data))
  {
    return undef;
  }
  else
  {
    return $data;	   
  }  
}

sub addNewDomain
{
  my $list = shift;
  my $domain = shift;

  my $list_prefixes = getListData($list);
  my @domain_prefixes = getDomainPrefixes($domain);
  push (@$list_prefixes, @domain_prefixes);
  
  saveList($list, $list_prefixes);
}


sub saveList
{
  my $list = shift;
  my $prefix_add = shift;
  #print Dumper($prefix_add);
  
  my $dir = "/tmp/";
  $list = $dir.$list.".list";
  
  store $prefix_add, $list; 
}

sub getDomainPrefixes
{
  my $domain = shift;

  # ANZ prefixes,    otherwise return some testing prefixes
  if ($domain eq 'www.anz.com')
  {
    my @anz_array = (
         {'prefix' => '128.8.10.90/32', more_sp => 'NO', less_sp => 'NO', reason => 'DNS: ROOT'},
         {'prefix' => '202.2.57.67/32', more_sp => 'NO', less_sp => 'YES', reason => 'DNS: anz.com'},
         {'prefix' => '202.2.57.59/32', more_sp => 'NO', less_sp => 'YES', reason => 'DNS: anz.com'},
         {'prefix' => '202.2.59.40/32', more_sp => 'NO', less_sp => 'YES', reason => 'DNS: www.anz.com'},
         {'prefix' => '202.2.56.40/32', more_sp => 'NO', less_sp => 'YES', reason => 'DNS: www.anz.com'}
	 );
    return @anz_array;
  }

  my @test_array = (
         {'prefix' => '128.8.10.90/32', more_sp => 'NO', less_sp => 'NO', reason => 'DNS: ROOT'},
         {'prefix' => '112.0.44.2/32', more_sp => 'NO', less_sp => 'YES', reason => 'DNS: www.example.com'},
         {'prefix' => '123.2.0.13/32', more_sp => 'NO', less_sp => 'YES', reason => 'DNS: example.com'},
         {'prefix' => '134.0.5.52/32', more_sp => 'NO', less_sp => 'YES', reason => 'DNS: example.com'}
	 );

  return @test_array;	   
}

sub getConvertStockTicker
{
  my $ticker = shift;
  if ($ticker eq 'ANZ')
  {
    return ('Australia New Zealand Bank', 'www.anz.com');
  }
 
  return ('Test Company Name', 'www.example.com'); 
}

sub getCompanies
{
  my $company = shift;
  if ($company eq 'Australia New Zealand Bank')
  {
    my @companies = ("Australia New Zealand Bank in New Zealand","Australia New Zealand Bank in Australia");
    return @companies;
  }
  
  my @test_companies = ("Example Company in New Zealand","Example Company in Australia", "Example Company in USA");
  return @test_companies;
}

sub addNewCompany
{
  my $list = shift;
  my $company = shift;

  my $list_prefixes = getListData($list);
  my @company_prefixes = getCompanyPrefixes($company);
  push (@$list_prefixes, @company_prefixes);
  
  saveList($list, $list_prefixes);
}

sub getCompanyPrefixes
{
  my $company = shift;
  if ($company eq 'Australia New Zealand Bank in New Zealand')
  {
    my @test_array = (
         {'prefix' => '202.2.56.0/24', more_sp => 'YES', less_sp => 'NO', reason => 'ANZ main prefix in New Zealand'}
	 );
    return @test_array;	   
  }
  if ($company eq 'Australia New Zealand Bank in Australia')
  {
    my @test_array = (
         {'prefix' => '202.2.59.0/24', more_sp => 'YES', less_sp => 'NO', reason => 'ANZ main prefix in Australia'}
	 );
    return @test_array;	   
  }
  if ($company eq 'Example Company in New Zealand')
  {
    my @test_array = (
         {'prefix' => '203.24.1.0/24', more_sp => 'YES', less_sp => 'NO', reason => 'Test company prefix in New Zealand'}
	 );
    return @test_array;	   
  }
  if ($company eq 'Example Company in Australia')
  {
    my @test_array = (
         {'prefix' => '188.25.1.0/24', more_sp => 'YES', less_sp => 'NO', reason => 'Test company prefix in Australia'}
	 );
    return @test_array;	   
  }
  if ($company eq 'Example Company in USA')
  {
    my @test_array = (
         {'prefix' => '200.25.15.0/24', more_sp => 'YES', less_sp => 'NO', reason => 'Test company prefix in USA'}
	 );
    return @test_array;	   
  }
  
  my @test_array = (
         {'prefix' => '129.82.9.0/24', more_sp => 'YES', less_sp => 'NO', reason => 'Test company prefix'}
	 );
  return @test_array;	   
}


sub deletePrefix
{
  my $list = shift;
  my $prefix = shift;

  my $data = getListData($list);
  #print Dumper($data);
  my $index = 0;
  foreach my $val (@$data)
  {
    if ($val->{'prefix'} eq $prefix)
    {
      splice @$data, $index, 1;
      #undef $val;
    }
    $index++;
  }
  #print Dumper($data);

  saveList($list, $data);
}

# Preloaded methods go here.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

BGPmon::CPM::Demo - Perl extension for blah blah blah

=head1 SYNOPSIS

  use BGPmon::CPM::Demo;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for BGPmon::CPM::Demo, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head2 EXPORT

None by default.



=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

A. U. Thor, E<lt>bgpmoner@E<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by A. U. Thor

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
