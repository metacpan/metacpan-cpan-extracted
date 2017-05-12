#!/usr/bin/perl

use ExtUtils::MakeMaker;

my $separator = "\n" . ( '=' x 79 ) . "\n";

########################################################################

print "\nReading test connection definitions from test.cfg file...\n"; 

if ( -f 'test.cfg' ) {
  open( CNXNS, 'test.cfg' ) or die $!;
  @dsns = <CNXNS>;
  chomp @dsns;
  close( CNXNS ) or die $!;
  print "  Found " . scalar(@dsns) . " lines.\n\n";
} else {
  print "  No test.cfg file found.\n\n";
}

########################################################################

print "Loading DBI to query for available drivers and suggested DSNs...\n"; 

require DBI;

my %common_cases = (
  'AnyData' => 'dbi:AnyData:',
  'mysql'   => 'dbi:mysql:test',
  'Pg'      => 'dbi:Pg:dbname=test',
  'SQLite'  => 'dbi:SQLite:dbname=test_data/test.sqlite',
  'Solid'   => 'dbi:Solid:',
  'Sprite'  => 'dbi:Sprite:test_data',
  'XBase'   => 'dbi:XBase:test_data',
);
my @exclude_patterns = (
  'dbi:ExampleP', # Insufficient capabilities
  'dbi:File',     # Insufficient capabilities
  'AnyData:($|(?!test_data))', # for file-based DBDs, don't show other directories
  'f_dir\\=(?!test_data)', # for file-based DBDs, don't show other directories
);

my @suggestions;
foreach my $driver ( DBI->available_drivers ) {
  eval {
    DBI->install_driver($driver);
    my @data_sources;
    eval {
      @data_sources = DBI->data_sources($driver);
    };
    push @data_sources, split(' ', $common_cases{$driver} || '');
    if (@data_sources) {
      foreach my $source ( @data_sources ) {
	push @suggestions, ($source =~ /:/ ? $source : "dbi:$driver:$source");
      } 
    } else { 
      push @suggestions, "dbi:$driver";
    }
  };
} 

@suggestions = map { s{^(dbi:)(\w+)(.*?)(test_data)(.*)}{$1$2$3$4/\L$2\E$5}i; $_ } @suggestions;
@suggestions = grep { my $s = $_; ! grep { $s =~ /$_/i } @exclude_patterns } @suggestions;

my %byname = map { $_ => 1 } @suggestions;
@suggestions = sort { lc($a) cmp lc($b) } keys %byname;

if ( my $count = scalar @suggestions ) {
  print "  Found $count suggestions.\n";
} else {
  print "  No suggestions found.\n";
}

########################################################################

my $needs_save;
while (1) {

  print $separator;

  if ( scalar @dsns ) {
    print "\nThe current configuration in test.cfg is listed below:\n";
    foreach ( 1 .. scalar @dsns ) {
      print "  $_: $dsns[ $_ - 1 ]\n";
    }
  } else {
    print "\nYou do not currently have any configurations in test.cfg\n";
  }
  
  my @available = grep { my $s = $_; ! grep { $_ eq $s } @dsns } @suggestions;
  my %additions;
  if ( scalar @available ) {
    print "\nAvailable suggestions:\n";
    my $a = 'a';
    foreach my $dsn ( @available ) {
      print "  $a: $dsn\n";
      $additions{ $a } = $dsn;
      ++ $a;
    }
  }
  
  my $prompt = "Enter " . join( ', ', 
	'a new driver string', 
	( @dsns ? 'a number to edit' : () ), 
	( @available ? 'a letter to add' : () ), 
	'or q to quit'
      );
  
  my $next = prompt("\n$prompt:\n>");

  if ( $next !~ /\S/ or $next =~ /^\s*q(uit)?\s*$/ ) {
    last;
    
  } elsif ( $next =~ /^\s*([a-z])\s*$/ ) {
    my $line = $1;
    unless ( exists $additions{ $line } ) {
      print "Can't add '$line', no such suggestion.\n";
      next;
    }
    push @dsns, $additions{ $line };
    $needs_save ++;
    
  } elsif ( $next =~ /^\s*(\d+)\s*$/ ) {
    my $line = $1;
    unless ( $line >= 0 and $line <= scalar @dsns ) {
      print "Can't edit '$line', no such definition.\n";
      next;
    }
    print "Current value for $line: $dsns[ $line -1 ]\n";
    my $edit = prompt("Enter a new value or press return to delete: \n>");
    if ( $edit =~ /^\s*(\S.*?)\s*$/ ) {
      $dsns[ $line -1 ] = $1;
    } else {
      splice @dsns, $line -1, 1;
    }
    $needs_save ++;
  } else {
    push @dsns, $next;
    $needs_save ++;
  }
}

print $separator;

if ( $needs_save ) {
  print "\nWriting " . scalar(@dsns) . " connections to test.cfg file...\n"; 
  
  open( CNXNS, '>test.cfg' ) or die $!;
  print CNXNS map "$_\n", @dsns;
  close( CNXNS ) or die $!;
}

print "\nDone.\n\n";

1;
