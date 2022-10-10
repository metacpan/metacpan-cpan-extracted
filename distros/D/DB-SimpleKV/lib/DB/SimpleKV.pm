package DB::SimpleKV;

use 5.006;
use strict;
use warnings;

=head1 NAME

DB::SimpleKV - Simple k/v interface to text configuration file

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

sub new {
  my $class = shift;
  my $file = shift || "/tmp/simplekv.db";

  unless (-f $file) {
    open my $db,">",$file or die $!;
    close $db;
  }

  bless { file=>$file }, $class;
}

sub exists {
  my $self = shift;
  my $key = shift;
  my $found = 0;

  open my $db, $self->{file} or die $!;
  while(<$db>) {
    my ($k,$v) = split/=/;
    $k =~ s/^\s+|\s+$//g;
    $v =~ s/^\s+|\s+$//g;
    if ($k eq $key) {
      $found =1;
      last;
    }
  }
  close $db;

  return $found;
}

sub set {
  my $self = shift;
  my $key = shift;
  my $value = shift;
  my %hash;

  open my $db, $self->{file} or die $!;
  while(<$db>) {
    my ($k,$v) = split/=/;
    $k =~ s/^\s+|\s+$//g;
    $v =~ s/^\s+|\s+$//g;
    $hash{$k} = $v;
  }
  close $db;

  $hash{$key} = $value;

  open my $dbx, ">", $self->{file} or die $!;
  for (sort keys %hash) {
    print $dbx $_,"=",$hash{$_},"\n";
  }
  close $dbx;
}

sub delete {
  my $self = shift;
  my $key = shift;
  my %hash;

  open my $db, $self->{file} or die $!;
  while(<$db>) {
    my ($k,$v) = split/=/;
    $k =~ s/^\s+|\s+$//g;
    $v =~ s/^\s+|\s+$//g;
    $hash{$k} = $v;
  }
  close $db;

  delete $hash{$key};

  open my $dbx, ">", $self->{file} or die $!;
  for (sort keys %hash) {
    print $dbx $_,"=",$hash{$_},"\n";
  }
  close $dbx;
}

sub get {
  my $self = shift;
  my $key = shift;
  my $value = undef;

  open my $db, $self->{file} or die $!;
  while(<$db>) {
    my ($k,$v) = split/=/;
    $k =~ s/^\s+|\s+$//g;
    $v =~ s/^\s+|\s+$//g;
    if ($k eq $key) {
      $value = $v;
      last;
    }
  }
  close $db;

  return $value;
}



=head1 SYNOPSIS

This module is mainly used to manipulate a configuration file like Postfix's main.cf

It creates the default db file under "/tmp/simplekv.db".

    use DB::SimpleKV;

    my $db = DB::SimpleKV->new;
    $db->set("hostname","h99.foo.com");
    $db->set("provider","rackspace cloud");
    $db->set("ip_addr","192.168.2.10");
    $db->set("netmask","255.255.255.0");

    print $db->get("provider"),"\n";
    $db->delete("netmask");
    print  "netmask exists? ", $db->exists("netmask") ? "yes" : "no", "\n";

Or you can specify the existing file for manipulation, one configuration per line, with '=' as delimiter.

    use DB::SimpleKV;

    my $db = DB::SimpleKV->new("/etc/postfix/main.cf");
    print $db->get("relayhost"),"\n";
    print  "relay exists? ", $db->exists("relayhost") ? "yes" : "no", "\n";



=head1 SUBROUTINES/METHODS

=head2 new

    my $db = DB::SimpleKV->new(...);

=head2 get

    my $value = $db->get("key");

=head2 set

    $db->set("key","value");

=head2 delete

    $db->delete("key");

=head2 exists

    my $exists = $db->exists("key");


=head1 AUTHOR

Ken Peng, C<< <yhpeng at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-db-simplekv at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=DB-SimpleKV>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc DB::SimpleKV


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=DB-SimpleKV>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/DB-SimpleKV>

=item * Search CPAN

L<https://metacpan.org/release/DB-SimpleKV>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2022 by Ken Peng.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of DB::SimpleKV
