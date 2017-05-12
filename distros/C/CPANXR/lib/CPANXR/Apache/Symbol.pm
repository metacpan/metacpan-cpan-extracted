package CPANXR::Apache::Symbol;
use CPANXR::Apache::Util;
use CPANXR::Database;
use CPANXR::Parser qw(:constants);
use File::Spec::Functions qw(catdir);
use Data::Page;
use strict;

our %Types = (
	      t1 => [CONN_PACKAGE, 'packages'],
	      t2 => [CONN_FUNCTION, 'function calls'],
	      t3 => [CONN_METHOD, 'method calls'],
	      t3 => [CONN_MACRO, 'macros'],
	      t4 => [CONN_INCLUDE, 'uses'],
	      t5 => [CONN_DECL, 'declarations'],
	      t6 => [CONN_ISA, 'inheritence'],
	      t7 => [CONN_REF, 'references'],
	      t8 => [CONN_LINK, 'includes'],
	      t9 => [CONN_FILE, 'files'],
	      );

sub find {
  my ($self, $r, $q) = @_;

  my $symbol_id = $q->param('symbol');
  my $pkg_id = $q->param('pkg');
  my $current = $q->param('p') || 1;

  unless($symbol_id =~ /^\d+$/) {
    $r->print("Missing argument <b>symbol</b>");
    return;
  }

  my $pkg = "";
  if($pkg_id) {
    unless($pkg_id =~ /^\d+$/) {
      $r->print("Malformed argument <b>pkg</b>");
    }
    $pkg = CPANXR::Database->select_symbol($pkg_id)->[0]->[0];
  }
  
  my $symbol = CPANXR::Database->select_symbol($symbol_id)->[0]->[0];

  $r->print("Looking for <b>$symbol</b>");
  if($pkg) {
    $r->print(" in package <b>$pkg</b>");
  }
  $r->print(" and found<br>\n");
  $r->print("<blockquote>\n");

  my %args;
  # Extract limit
  {   
    my @limit_types;
    while(my ($param, $value) = each %Types) {
      my $v = $q->param($param) ? 1 : 0;
      push @limit_types, $value->[0] if $v;
    }
    if(@limit_types) {
      $args{limit_types} = \@limit_types;
    } 
  }

  # Select files matching symbol
  my $files = CPANXR::Database->select_files(symbol_id => $symbol_id);
  @$files = map { [ $symbol_id, $symbol, "", "", $_->[2], $_->[0], undef, CONN_FILE, undef, $_->[1]] } @$files;
  # Select connections matching symbol
  my $result = CPANXR::Database->select_connections(symbol_id => $symbol_id, %args);
  unshift @$result, @$files;
  $result = $self->transform($result);

  my $table = CPANXR::Apache::Util::Table->new($r, 4, [qw(15% 55% 15% 15%)]);
  $table->begin;
  $table->header("<b>Type:</b>", "<b>File:</b>", "<b>Location:</b>", "<b>Show:</b>");

  my $page = Data::Page->new(scalar @$result, 10, $current);
  
  my ($pre_file, $pre_type) = ("","");
  for($page->splice($result)) {
    if($pre_file ne $_->[1] || ($pre_type ne $_->[0])) { 
      $pre_file = $_->[1]; 
    } else { 
      $_->[1] = ""; 
    }
    
    if($pre_type eq $_->[0]) { 
      $_->[0] = "";
    } else { 
      $pre_type = $_->[0];
    }
    
    $table->print(@$_);
  }

  $table->end;

  # Write navigation
  my $base = "find?symbol=$symbol_id&pkg=$pkg_id";
  my $base_type = "";
  $base_type .= "&$_=" . ($q->param($_) ? 1 : 0) for(keys %Types);
  $base_type =~ s/=0/=1/g unless($base =~ /=1/);

  CPANXR::Apache::Util->navigator($r, $page, $base . $base_type);

  # Limit search
  $r->print(qq{<br>
<form action="find" method="post">
<input type="hidden" name="symbol" value="$symbol_id">
<input type="hidden" name="pkg" value="$pkg_id">
<b>Show</b>:&nbsp;});
  
  for(sort { $Types{$a}->[1] cmp $Types{$b}->[1] } keys %Types) {
    my $checked = $q->param($_) ? "checked" : "";
    $r->print(qq{<input type="checkbox" name="$_" value="1" $checked>@{[lcfirst($Types{$_}->[1])]}&nbsp;});
  }

  $r->print(q{<input type="submit" value="Redefine search"></form>});

  $r->print("</blockquote>");
}

my @Types = ("uses",
	     "calls",
	     "calls",
	     "functions",
	     "macros",
	     "packages",
	     "inherits",
	     "references",
	     "includes",
	     "files",
	    );

sub transform {
  my ($self, $result) = @_;
  
  my $groups = {};
  
  foreach my $item (@$result) {
    my $type = $Types[$item->[7]];
    
    $groups->{$type} = {} unless(exists $groups->{$type});
    
    if(exists $groups->{$type}->{$item->[4]}) {
      push @{$groups->{$type}->{$item->[4]}->{lines}}, [$item->[2], $item->[0], $item->[6], $item->[8]];
    } else {
      $groups->{$type}->{$item->[4]} = { file_id => $item->[5],
					 lines => [[$item->[2], $item->[0], $item->[6], $item->[8]]], };
    }
  }

  my @result;

  foreach my $type (sort keys %$groups) {
    my $show_type = "<b>$type</b>";
    while(my ($file, $entries) = each %{$groups->{$type}}) {
      my $show_file = $file;
      if(@{$entries->{lines}}) {
	foreach my $line (@{$entries->{lines}}) {
	  my $show_line = "";
	  if($line->[0] ne "") {
	    $show_line = qq{<a href="show?id=$entries->{file_id}&hl=$line->[0]#l$line->[0]">at line $line->[0]</a>};
	  } else {
	    $show_line = "<i>n/a</i>";
	  }
	  my $func = "";
	  if($type eq 'functions') {
	    my $pkg_id = $line->[2] || $line->[3];
	    my $sym_id = $line->[1];
	    $func = qq{<a href="graph?sub=${sym_id}_${pkg_id}">Call graph</a>};
	  } elsif($type eq 'packages') {
	    $func = qq{<a href="graph?class=$line->[1]">IS-A graph</a>};
	  } elsif($type eq 'files') {
	    $func = qq{<a href="graph?file=$entries->{file_id}">File graph</a>};
	  }

	  push @result, [$show_type, $show_file, $show_line, $func];
	}
      }
    }
  }
  
  return \@result;
}

1;
