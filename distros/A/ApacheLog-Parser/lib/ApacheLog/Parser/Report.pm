package ApacheLog::Parser::Report;
$VERSION = v0.0.1;

use warnings;
use strict;
use Carp;
use YAML;

=head1 NAME

ApacheLog::Parser::Report - configurable report extraction

=head1 SYNOPSIS

  my $rep = ApacheLog::Parser::Report->new(conf => \%config);
  $rep->load_config($config_filename); # maybe
  my $func = $rep->get_func;
  while(...) {
    $func->($array_ref);
  }
  $rep->write_report($filename);

=cut

=head2 new

  my $rep = ApacheLog::Parser::Report->new(conf => \%config);

=cut

sub new {
  my $package = shift;
  my $class = ref($package) || $package;
  my $self = {@_};
  bless($self, $class);
  if(ref($package)) {
    @$self{qw(conf config_hash)} = @$package{qw(conf config_hash)};
  }
  else {
    $self->_setup_config;
  }
  return($self);
} # end subroutine new definition
########################################################################

=head2 _setup_config

  $self->_setup_config;

=cut

my $namify = sub {my $t = $_[0]; $t =~ s/ /_/g; lc($t);};
sub _setup_config {
  my $self = shift;

  my $config = $self->{conf} or die "no config";
  my @conf = @$config;
  my $c = $self->{config_hash} = {};
  foreach my $item (@conf) {
    my $name = $item->{name} ||= $namify->($item->{title}) or
      die "no name/title in ", join(", ", %$item);
    $item->{opts} = {
      map({$_ => 1} split(/ /, ($item->{options}||'')))
    };
    $c->{$name} and croak("duplicate name '$name'");
    $c->{$name} = $item;
  }
} # end subroutine _setup_config definition
########################################################################

=head2 load_config

  $rep->load_config($config_filename); # maybe

=cut

sub load_config {
  my $self = shift;
  die "nope";
} # end subroutine load_config definition
########################################################################

=head2 get_func

  my $func = $rep->get_func;

=cut

sub get_func {
  my $self = shift;

  my @conf = @{$self->{conf}};

  my $s = $self->{store} = {};
  my @preface;
  my @codes;
  foreach my $item (@conf) {
    my $name = $item->{name};
    $s->{$name} = {};
    unless($item->{where}) {
      #warn "$name is a stub\n";
      next;
    }
    #warn "gen code for $name ($item->{title})\n";
    my ($code, $pre) = $self->_code_for($item);
    push(@codes, $code);
    push(@preface, $pre) if($pre);
    if(0) {
      warn "#"x72, "\n";
      warn "for $name\n$code", ($pre ? "\n\n$pre\n" : '');
    }
  }
  $ENV{DBG} and warn join("\n", @preface), join("\n", @codes);
  $self->_compile(join("\n", @preface), join("\n", @codes));
} # end subroutine get_func definition
########################################################################
sub _compile {
  my $s = $_[0]->{store};
  my $func = eval("$_[1];
  use ApacheLog::Parser qw(:fields);
  sub {
    my \$v = shift;
    my \$p;
    my \@ans;
    $_[2]
    no ApacheLog::Parser;
  }
  ");
  $@ and croak("cannot compile $_[1]/\n$_[2]\n  -- $@");
  return($func);
}
sub _code_for {
  my $self = shift;
  my ($item) = @_;

  my $name = $item->{name};
  $ENV{DBG} and warn "building rules for $name\n";
  # need to work-out the pre-reqs
  my $preface;
  my $callcode;
  if(my $code = $item->{code}) {
    $callcode = '$_' . $name . '_code';
    $preface = join("\n",
      'my ' . $callcode . ' = sub {',
      $code,
      '};'
    );
  }
  # then the total number of captures?
  # bind everything to ^$ ?
  # switch some to eq?
  my $has_matches = sub {
    my ($string) = @_;
    defined($string) or die "no string";
    return($string =~ m/(?<!\\)\((?!\?)/ ? 1 : 0);
  };
  my $before;
  my @code;
  my @conds;
  my $some_matches = 0;
  foreach my $cond (@{$item->{where}}) {
    my @subs;
    foreach my $thing (sort(keys(%$cond))) {
      my $re = $cond->{$thing};
      if($thing eq 'params') {
        $before =
          '$p ||= {map({my @g = split(/=/, $_, 2); ($#g?@g:())}' .
          ' split(/&/, $v->[params]))};';
        foreach my $p (split(/ & /, $re)) {
          my ($name, $want) = split(/=/, $p, 2);
          push(@subs, ["(\$p->{$name}||'')", $want]);
        }
      }
      else {
        # the \$v->[$thing] =~ m#$re# bit
        push(@subs, ["\$v->[$thing]", $re]);
      }
    }
    # and-together all of the subconditions
    my $had_match = 0;
    my @pref = ('(@ans = ', 'push(@ans, ');
    my @built;
    foreach my $subc (@subs) {
      my $start;
      if($has_matches->($subc->[1])) {
        $start = $pref[$had_match];
        $some_matches = 1;
        $had_match = 1;
      }
      else {
        $start = '(';
      }
      push(@built, $start . $subc->[0] . ' =~ m#^' . $subc->[1] . '$#)');
    }
    # single subcondition
    push(@conds, $#built ? join(' and ',map({"($_)"} @built)) : @built);
  }
  #warn "$name ", $some_matches ? 'yes' : 'no', "\n\n";
  # or-together all of the where's
  my $code = ($before ? "$before\n" : '') .
    'if(' . (
    $#conds ?
      "\n  " . join(" or\n", map({"  ($_)"} @conds)) . "\n" :
      $conds[0]
    ) .
    ") {\n  " .
    # must clear-out the answer slot if there were never any match vars
    ($callcode ?
      ($some_matches ? '' : '@ans = ();') . $callcode . '->(@ans)' :
      "(\$s->{$name}{" . ($some_matches ? '$ans[0]' : q('') ) .
      '}||=0)++'
    ) . ';return' .
    "\n}";
  return($code, $preface);
}

=head2 aggregate

  $rep->aggregate($data);

=cut

sub aggregate {
  my $self = shift;
  my ($data) = @_;

  $data or croak('usage: aggregate(\%data)');

  my $s = $self->{store} ||= {};
  my $t = $self->{totals} ||= {};

  my @conf = @{$self->{conf}};

  my %data = %$data;

  foreach my $item (@conf) {
    my $name = $item->{name};
    $s->{$name} ||= {};
    my $got = $data{$name} or next;
    foreach my $k (keys(%$got)) {
      ($s->{$name}{$k}||=0) += $got->{$k};
      # and the totals
      unless($item->{opts}{no_total}) {
        ($t->{$name}||=0)+= $got->{$k};
      }
      if(my $dest = $item->{sum_into}) {
        $dest = $namify->($dest);
        ($t->{$dest}||=0)+= $got->{$k};
      }
    }
  }
  return($t, $s);
} # end subroutine aggregate definition
########################################################################

# XXX actually YAML::Syck doesn't always play-nice, so ...
my $dumper = eval{require YAML::Syck} ?
  sub {YAML::Syck::Dump($_[0])} :
  sub {YAML::Dump($_[0])};

=head2 print_report

  my $string = $rep->print_report;

=cut

sub print_report {
  my $self = shift;
  my $string = "";

  my $s = $self->{store};
  my $t = $self->{totals};
  my $c = $self->{config_hash};

  open(my $fh, '>', \$string) or die "gah";

  my $get_width = sub {
    length((sort({length($b) <=> length($a)} @_))[0]);
  };
  my $max_l = $get_width->(map({$c->{$_}{title}} keys(%$t)));
  $max_l++;

  print $fh join("\n  ", 'Totals:',
    map({sprintf("%-${max_l}s %10d",
      $c->{$_}{title} . ':', $t->{$_})} sort(keys(%$t)))
  ), "\n\n";

  my $gh = $self->_greatest_hits;
  print $fh "Greatest Hits\n";
  foreach my $k (sort(keys(%$gh))) {
    my $d = $gh->{$k};
    print $fh "  $c->{$k}{title}:\n";
    my @rows = sort({$d->{$b} <=> $d->{$a}} keys(%$d));
    my $max_w = $get_width->(@rows);
    $max_w++;
    print $fh join("\n",
      map({sprintf("    %-${max_w}s %10d", $_ . ':', $d->{$_})} @rows)
    ), "\n";
  }

  close($fh);
  my $yaml = $dumper->({
    totals        => $self->{totals},
    greatest_hits => $gh
  });

  return($string, $yaml);
} # end subroutine print_report definition
########################################################################

=head2 table_report

  $rep->table_report(@files);

=cut

sub table_report {
  my $self = shift;
  my (@files) = @_;

  my $ref = ref($files[0]) ? shift(@files) : undef;

  my $c = $self->{config_hash};

  my $collect;
  foreach my $file (@files) {
    my $t;
    if($ref) {
      my $agg = $self->new;
      foreach my $f (@{$ref->{$file}}) {
        my $data = YAML::Syck::LoadFile($f);
        $data ||= {}; # XXX is silence golden?
        ($t) = $agg->aggregate($data);
      }
    }
    else {
      my $data = YAML::Syck::LoadFile($file);
      $t = $data->{totals};
    }
    foreach my $k (keys(%$t)) {
      my $dest = $collect->{$k} ||= {};
      $dest->{$file} = $t->{$k};
    }
  }

  my @rows = sort(keys(%$collect));
  my @col0 = map({$c->{$_}{title}} @rows);

  my @table;
  push(@table, []) for(@rows);

  foreach my $file (@files) {
    my $r = 0;
    foreach my $row (@rows) {
      push(@{$table[$r++]}, $collect->{$row}{$file} || 0);
    }
  }
  {
    my $r = 0;
    unshift(@{$table[$r++]}, shift(@col0)) for(@rows);
  }
  return(@table);
} # end subroutine table_report definition
########################################################################

=head2 _greatest_hits

  $self->_greatest_hits;

=cut

sub _greatest_hits {
  my $self = shift;

  my $c = $self->{config_hash};
  my $s = $self->{store};
  my %o;
  foreach my $k (keys(%$s)) {
    my $d = $s->{$k};
    my @got = sort({$d->{$b} <=> $d->{$a}} keys(%$d));
    (@got > 1) or next;
    my $max = ($c->{$k}{top} || 10) - 1;
    $#got = $max if($#got > $max);
    #warn "@got\n";
    $o{$k} = {map({$_ => $d->{$_}} @got)};
  }
  return(\%o);
} # end subroutine _greatest_hits definition
########################################################################

# TODO sum_into is just deferred until write_report time?

=head2 write_report

  $rep->write_report($filename);

=cut

sub write_report {
  my $self = shift;
  my ($filename) = @_;

  open(my $fh, '>', $filename) or die "cannot write '$filename' $!";
  print $fh $dumper->($self->{store});
  close($fh) or die "cannot close '$filename' $!";
} # end subroutine write_report definition
########################################################################




=head1 AUTHOR

Eric Wilhelm @ <ewilhelm at cpan dot org>

http://scratchcomputing.com/

=head1 BUGS

If you found this module on CPAN, please report any bugs or feature
requests through the web interface at L<http://rt.cpan.org>.  I will be
notified, and then you'll automatically be notified of progress on your
bug as I make changes.

If you pulled this development version from my /svn/, please contact me
directly.

=head1 COPYRIGHT

Copyright (C) 2007 Eric L. Wilhelm, All Rights Reserved.

=head1 NO WARRANTY

Absolutely, positively NO WARRANTY, neither express or implied, is
offered with this software.  You use this software at your own risk.  In
case of loss, no person or entity owes you anything whatsoever.  You
have been warned.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

# vi:ts=2:sw=2:et:sta
1;
