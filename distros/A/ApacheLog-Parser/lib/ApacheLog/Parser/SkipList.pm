package ApacheLog::Parser::SkipList;
$VERSION = v0.0.1;

use warnings;
use strict;
use Carp;

use Digest::MD5 ();
use YAML ();

=head1 NAME

ApacheLog::Parser::SkipList - a list of skippable lines

=head1 SYNOPSIS

  my $skipper = ApacheLog::Parser::SkipList->new;
  my %regexps = $skipper->set_config(\%conf);
  # you'll typically build %regexps into some condition sub

  my $sw = $skipper->new_writer($skipfile);
  my $counter = 0;
  while(...) {
    ...
    $counter++;
    $some_condition and $sw->skip($counter);
  }

Later, while reading a file with a prepared skiplist:

  my $skipper = ApacheLog::Parser::SkipList->new;
  $skipper->set_config(\%conf);

  my $sr = $skipper->new_reader($skipfile);
  my $skip = $sr->next_skip;
  my $counter = 0;
  while(my $line = <$fh>) {
    if(++$counter == $skip) {
      $counter += $sr->skip_lines($fh);
      $skip = $sr->next_skip;
      next;
    }
    
    # then do more expensive stuff
    ...
  }

=cut

=head2 new

  my $skipper = ApacheLog::Parser::SkipList->new;

=cut

sub new {
  my $package = shift;
  my $class = ref($package) || $package;
  my $self = {};
  bless($self, $class);
  return($self);
} # end subroutine new definition
########################################################################

=head2 set_config

  my %regexps = $skipper->set_config(\%conf);

=cut

sub set_config {
  my $self = shift;
  my ($conf) = (@_);

  my $handle = {
    file => {
      ext => sub {
        my $s = join('|', @_);
        return(qr/\.(?:$s)$/);
      },
      path => sub {
        my $s = join('|', @_);
        return(qr/^(?:$s)/);
      },
    },
  };
  my %reg;
  foreach my $k (keys(%$conf)) {
    my $ref = $handle->{$k};
    my @ans;
    foreach my $bit (sort({$b cmp $a} keys(%{$conf->{$k}}))) {
      $ref->{$bit} or croak("no handler for $k/$bit config");
      my $list = $conf->{$k}{$bit};
      push(@ans, $ref->{$bit}->(@$list));
    }
    if(@ans) {
      my $s = join("|", @ans);
      $reg{$k} = qr/(?:$s)/;
    }
  }

  $self->{config} = Digest::MD5::md5_hex(YAML::Dump($conf));
  $self->{regexps} = \%reg;
  return(%reg);
} # end subroutine set_config definition
########################################################################

=head2 get_matcher

  my $subref = $skipper->get_matcher;

=cut

sub get_matcher {
  my $self = shift;

  my %re = %{$self->{regexps}};

  my $code = '';
  foreach my $type (qw(file)) {
    $re{$type} or next;
    $code .= "(\$v->[$type] =~ m#$re{$type}#) and return(1);";
  }
  #die "compiling $code";
  my $doskip = eval("
    use ApacheLog::Parser qw(:fields);
    my \$code = sub {my \$v = shift; $code};
    no ApacheLog::Parser;
    \$code");
  $@ and die "cannot build doskip sub -- $@";
  return($doskip);
} # end subroutine get_matcher definition
########################################################################

=head2 merge

Merge existing files (adjusting the offsets.)

  $skipper->merge($dest, $file, $offset, $file);

=cut

  use constant flag => 2**31;

sub merge {
  my $self = shift;
  my ($dest, @parts) = @_;

  my $outfh = $self->_open_write($dest);

  # just slurp the entire first bit
  my $first_part = shift(@parts);
  {
    my $fh = $self->_open_read($first_part);
    print $outfh readline($fh);
  }

  while(@parts) {
    my ($offset, $part) = (shift(@parts), shift(@parts));
    my $fh = $self->_open_read($part);

    while(not eof($fh)) {
      my $v;
      (read($fh, $v, 4) == 4) or die "gah";
      my $n = unpack("N", $v);

      # if it is flagged, there's another byte
      if($n & flag) {
        my $val;
        (read($fh, $val, 4) == 4) or die "gah";
        $n &= ~flag; # de-mangle it
        $n += $offset;
        $n |= flag;  # re-mangle
        print $outfh pack('N', $n), $val;
      }
      else {
        $n += $offset;
        print $outfh pack('N', $n);
      }
    }
  }
} # end subroutine merge definition
########################################################################

=head2 new_writer

  my $sw = $skipper->new_writer($skipfile);

=cut

sub new_writer {
  my $self = shift;
  my ($filename) = @_;

  my $fh = $self->_open_write($filename);
  my $writer = __PACKAGE__ . '::Writer';
  return($writer->new($fh));
} # end subroutine new_writer definition
########################################################################
sub _open_write {
  my $self = shift;
  my ($filename) = @_;

  my $conf_check = $self->{config} or
    croak("cannot make a writer without a config");

  open(my $fh, '>', $filename) or
    croak("cannot open '$filename' for writing $!");

  print $fh $conf_check;
  return($fh);
}

=head2 new_reader

  my $sr = $skipper->new_reader($skipfile);

=cut

sub new_reader {
  my $self = shift;
  my ($filename) = @_;

  my $fh = $self->_open_read($filename);
  my $reader = __PACKAGE__ . '::Reader';
  return($reader->new($fh));
} # end subroutine new_reader definition
########################################################################
sub _open_read {
  my $self = shift;
  my ($filename) = @_;
  my $conf_check = $self->{config} or
    croak("cannot make a reader without a config");

  open(my $fh, '<', $filename) or
    croak("cannot open '$filename' for reading $!");

  my $verify;
  my $ok = read($fh, $verify, 32);
  (($ok||0) == 32) or
    croak("read error on $filename ", (defined($ok) ? 'eof' : $!));
  ($verify eq $conf_check) or
    croak("the config has changed since this skiplist was created\n",
      "  '$verify' vs '$conf_check'");

  return($fh);
}

{
  package ApacheLog::Parser::SkipList::Base;
  sub new {
    my $package = shift;
    my ($fh) = @_;
    my $class = ref($package) || $package;
    my $self = [$fh, 0, -1];
    bless($self, $class);
    return($self);
  }
}
{
  package ApacheLog::Parser::SkipList::Writer;
  use Carp;
  our @ISA = qw(ApacheLog::Parser::SkipList::Base);
  use constant flag => 2**31;
  sub skip {
    my $self = shift;
    my ($l) = @_;

    my $fh = $self->[0];
    if($l == $self->[2]+1) { # contiguous
      $self->[2] = $l;
    }
    else {
      # write-out
      if(my $num = $self->[1]) {
        if(my $span = $self->[2] - $num) {
          $num |= flag;
          print $fh pack('N2', $num, $span);
        }
        else {
          print $fh pack('N', $num);
        }
      }

      $self->[1] = $self->[2] = $l;
    }
  }
  sub DESTROY {
    close($_[0]->[0]) or
      croak("close file failed $!");
    @{$_[0]} = ();
  }
}
{
  package ApacheLog::Parser::SkipList::Reader;
  use Carp;
  our @ISA = qw(ApacheLog::Parser::SkipList::Base);
  use constant flag => 2**31;

  # return the next skip value and setup the line counter
  sub next_skip {
    my $self = shift;

    my $fh = $self->[0];
    eof($fh) and return(0);

    my $v;
    (read($fh, $v, 4) == 4) or die "gah";
    my $n = unpack("N", $v);

    # if it is flagged, there's another byte
    if($n & flag) {
      my $val;
      (read($fh, $val, 4) == 4) or die "gah";
      my $more = unpack("N", $val);
      $self->[1] = $more;
      $n &= ~flag; # de-mangle it
    }
    else {
      # a single line
      $self->[1] = 0;
    }
    return($self->[2] = $n);
  }
  sub skip_lines {
    my ($self, $fh) = @_;
    my $n = $self->[1] or return(0);
    my $q = 0;
    while(<$fh>) { (++$q >= $n) and return($n); }
    croak("eof while skipping");
  }
}

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
