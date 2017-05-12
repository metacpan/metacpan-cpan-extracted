package Config::Backend::File;

use 5.006;
use strict;

sub new {
  my $class=shift;
  my $filename=shift;
  my $self;

  # Read in config

  my $str="";
  my @order;
  my %conf;
  my $invar=0;
  my $open=1;
  my @vars_and_comments;

  open my $in,"<$filename" or $open=0;;
  if ($open) {
    while (my $line=<$in>) {
      $str.=$line;
    }
    close $in;
  }

  # Process Comments and %%

  my $i=0;
  my $k=0;
  my $N=length($str);

  while ($i<$N) {
    if (substr($str,$i,3) eq "\n%#") {
      if ($k!=$i) {
	push @vars_and_comments,substr($str,$k,($i-$k));
	$k=$i+1;
	$i+=2;
      }
    } elsif (substr($str,$i,3) eq "\n%%") {
      $i+=2;
    } elsif (substr($str,$i,2) eq "\n%") {
      if ($k!=$i) { 
	push @vars_and_comments,substr($str,$k,($i-$k));
	$k=$i+2;
	$i+=2;
      }
    }
    $i+=1;
  }

  if ($k!=$i) {
    push @vars_and_comments,substr($str,$k,($N-$k));
  }

  my $comment=0;
  for my $item (@vars_and_comments) {
    if ($item=~/^%#/) {
      push @order,"%#$comment,$item";
      $comment+=1;
    } else {
      my ($var,$val)=split /=/,$item,2;
      $var=~s/^%//;
      push @order,$var;
      $val=~s/\n%%/\n%/;
      $conf{$var}=$val;
    }
  }

  # Set config to string

  $self->{"filename"}=$filename;
  $self->{"order"}=\@order;
  $self->{"conf"}=\%conf;
  $self->{"changed"}=0;

  # bless

  bless $self,$class;

return $self;
}

sub DESTROY {
  my $self=shift;
  $self->commit();
}

sub commit {
  my $self=shift;

  # Only commit on changes

  if (not $self->{"changed"}) {
    return;
  }

  # Commit to file

  my $filename=$self->{"filename"};
  my $firstvar=1;
  open my $out,">$filename";
  my $delim="";
  my $cdelim="";
  for my $var (@{$self->{"order"}}) {
    if ($var=~/^%#/) {
      my ($cm,$val)=split /,/,$var,2;
      print $out "$cdelim$val";
    }
    else {
      my $val=$self->{"conf"}->{"$var"};
      $val=~s/\n%/\n%%/g;
      print $out "$delim$var=$val";
    }
    $delim="\n%";
    $cdelim="\n";
  }

  close $out;
}

sub set {
  my $self=shift;
  my $var=shift;
  my $val=shift;

  $self->{"changed"}=1;

  my $oldval=$self->get($var);
  if (not exists $self->{"conf"}->{$var}) {
    push @{$self->{"order"}},$var;
  }
  $self->{"conf"}->{$var}=$val;

  $self->commit();
}

sub get {
  my $self=shift;
  my $var=shift;
return $self->{"conf"}->{$var};
}

sub del {
  my ($self,$var)=@_;

  $self->{"changed"}=1;

  delete $self->{"conf"}->{$var};

  my @neworder;
  for my $elem (@{$self->{"order"}}) {
    if ($elem ne $var) {
      push @neworder,$elem;
    }
  }
  $self->{"order"}=\@neworder;

  $self->commit();
}

sub variables {
  my $self=shift;
return keys %{$self->{"conf"}};
}

1;
__END__

=head1 NAME

Config::Backend::File - a file backend for Config::Frontend.

=head1 ABSTRACT

Config::Backend::File is a file backend for Config::Frontend. It handles
files with identifiers that are assigned values.
The files can have comments.

=head1 Description

Each call C<set()> will immediately result in file to
be rewritten.

The configuration file has following syntax:

  %# Head of the configuration file
  %variable=value
  %variable=mult
  line value with
  %% double percentage sign
  at the beginning of the line % indicating
  %%# (This is not a comment)
  a single escaped percentage sign.
  %# Comments start with %#.
   

=head2 C<new(filename)> --E<gt> Config::Backend::File

Invoked with a valid filename, new will open the filename for
reading and read in the configuration items. A configuration
file will have the following form:

  %var = value
  %multiline=Hi there,
  This is a multiline, with a hundred,
  %% (percent) read 
  back.
  %test=1000.0

Notice that the percentage sign in a multiline config item
will be doubled to distinguish it from config  variables.

=head2 DESTROY()

This function will write back the configuration to file.

=head2 C<set(var,value) --E<gt> void>

Sets config key var to value. Writes the config file right
away.

=head2 C<get(var) --E<gt> string>

Reads var from config. Returns C<undef>, if var does not
exist. Returns the value of configuration item C<var>,
otherwise.

=head2 C<del(var) --E<gt> void>

Deletes var from the configuration file.

=head2 C<variables() --E<gt> list of strings>

Returns all variables in the configuraton file.

=head1 SEE ALSO

L<Config::Frontend|Config::Frontend>.

=head1 AUTHOR

Hans Oesterholt-Dijkema, E<lt>oesterhol@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Hans Oesterholt-Dijkema

This library is free software; you can redistribute it and/or modify
it under LGPL. 

=cut

  



=cut


