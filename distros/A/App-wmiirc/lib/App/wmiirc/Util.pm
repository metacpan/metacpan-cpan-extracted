package App::wmiirc::Util;
{
  $App::wmiirc::Util::VERSION = '1.000';
}
# ABSTRACT: Various utilities for wmii
use strictures 1;
use parent 'Exporter';
use IPC::Open2;

our @EXPORT = qw(config wmiir wimenu);

our @CONFDIRS = split /:/, $ENV{WMII_CONFPATH} || "$ENV{HOME}/.wmii";

# TODO: This should use ixp (via Lib::IXP?)

sub wmiir {
  my($file, @args) = @_;

  my $action = do {
    if(@args) {
      if(not defined $args[0]) {
        "remove"
      } else {
        "create"
      }
    } else {
      "read"
    }
  };

  if($action eq 'create') {
    # TODO: hacky, maybe do need create as an explicit thing, but I quite like
    # not having the distinction.
    system "wmiir", "ls", $file or ($action = "write");
    open my $fh, "|-", "wmiir", $action, $file  or die $!;
    print $fh join("\n", @args), "\n" or return 0;
    close $fh or return 0;
    return !$?;
  } else {
    $action = "ls" if $action eq 'read' and $file =~ m{/$};
    my @items = qx{wmiir $action $file};
    chomp @items;
    return wantarray ? @items : $items[0];
  }
}

sub config {
  my($name, $defaults, $part) = @_;

  for my $dir(@CONFDIRS) {
    if(-r "$dir/$name") {
      open my $fh, "<", "$dir/$name" or return;
      if(defined $defaults and not ref $defaults) {
        return {_parse($fh)}->{$defaults} || $part;
      } elsif(wantarray) {
        return %$defaults, _parse($fh);
      } else {
        return join "", <$fh>;
      }
    }
  }
  return wantarray ? %$defaults : !ref($defaults) ? $part : $defaults;
}

sub _parse {
  my($fh) = @_;
  my %o;
  while(<$fh>) {
    chomp;
    next if /^\s*#/;
    my($k, $v) = $_ =~ /^\s*(\S+)(?:\s+(.*)|\s*$)/;
    $o{$k} = $v;
  }
  return %o;
}

# TODO: async API, maybe completion support?
sub wimenu {
  my(@items) = @_;
  my %opts;
  if(@items && ref $items[0] eq 'HASH') {
    %opts = %{shift @items};
    if(my $name = delete $opts{name}) {
      $opts{p} = $name;
      $opts{h} = "$CONFDIRS[0]/history." . (delete $opts{history} || $name);
      $opts{n} = delete $opts{num} || 5000;
    }
  }
  my $pid = open2 my($out_fh, $in_fh), "wimenu",
    map +("-$_" => $opts{$_}), keys %opts;
  print $in_fh join("\n",
    @items && ref $items[0] eq 'ARRAY' ? @{$items[0]} : @items), "\n";
  close $in_fh;
  waitpid $pid, 0;
  (<$out_fh> =~ /(.*)/)[0];
}

1;

__END__
=pod

=head1 NAME

App::wmiirc::Util - Various utilities for wmii

=head1 VERSION

version 1.000

=head1 AUTHOR

David Leadbeater <dgl@dgl.cx>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by David Leadbeater.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

