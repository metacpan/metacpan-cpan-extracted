package Dansguardian;
use warnings;
use strict;
use Carp;
use Tie::File;

our $VERSION = '0.05';

=head1 NAME

Dansguardian - Simple module for administer dansguardian's control files.

=head1 SYNOPSIS

  use Dansguardian;

  # Make the objet $dg using the contructor new()
  
  my $dg = Dansguardian->new(dir => '/etc/dansguardian', group_dir => '/etc/dansguardian/lists');

  # Save IP's banned in array
  
  my @banned_ips = $dg->get('bannediplist');
  print "The IP address $_ is banned!!\n" foreach @banned_ips;

  # Add exception web site
  
  my $site = 'mogaal.com';
  $dg->set(file => 'exceptionsitelist', add => $site, comment => "Is not porn site");

  # Remove banned IP
  
  my $ip_free = '192.168.0.2';
  $dg->remove(file => 'bannediplist', line => $ip_free);

  # list sites banned
  
  my @sites_banned = $dg->get('bannedsitelist');
  print "The site $_ is banned!!\n" foreach @sites_banned;

  # list dansguardian's config directory and the current group directory
  
  print "Dansguardian's config directory is " . $dg->group() . " and " . $dg->dir() . " is the current group directory\n";

  # Change group directory;
  
  $dg->group("/etc/dansguardian/chiefs");
  print "Dansguardian's config directory is " . $dg->dir() . " and " . $dg->group() . " is the current group directory\n";


=head1 DESCRIPTION

"DansGuardian is an award winning Open Source web content filter which currently runs on Linux, FreeBSD, OpenBSD, NetBSD, Mac OS X, HP-UX, and Solaris. It filters the actual content of pages based on many methods including phrase matching, PICS filtering and URL filtering. It does not purely filter based on a banned list of sites like lesser totally commercial filters."

Dansguardian Perl module is small module for administer dansguardian's content control files. It let you add, remove and get information from files control across methods.


=head1 METHODS

Dansguardian perl module provides some basic methods for administer control files, with it you can add, remove and get information about IP's blocked, sites denies, IP exception and other information. 

=head2 new (constructor)

  $dg = Dansguardian->new([%attributes])

The constructor will create an object. It accepts a list of key => value pairs:

=over 3

=item dir => 'dansguardian/config/directory'

If you don't set up a config directory for dansguardian the module will set up default value: /etc/dansguardian

=item group_dir => 'path/to/group_dir/directory'

Same that dir hash, and the default value is: /etc/dansguardian/lists

=back

=cut

sub new {
	my ($self, %args) = @_;
	my $object = bless {
		dir => $args{dir},
		group_dir => $args{group_dir}
		}, $self;
	return $object;
}


=pod

=head2 $dg->group([$group_dir]);

If group method don't have attribute: the function return array with dansguardian current group directory. Is possible change the group directory setting up $group_dir variable.

=cut

sub group {
	my $self = shift;
	$self->{group_dir} = shift if @_;
	return $self->{group_dir};
}

=pod


=head2 $dg->dir([$config_dir]);

If dir method don't have attribute: the function return array with dansguardian current config directory. Is possible change the group directory setting up $group_dir variable.

=cut

sub dir {
	my $self = shift;
	$self->{dir} = shift if @_;
	return $self->{dir};
}

=pod


=head2 $dg->set(%attributes);

set method must have hash attributes. So, it accepts a list of key => value pairs:

=over 3

=item file => 'FILE'

The FILE value is the file (locate inside current group dir) where you wish add information. For example: If you want add site to exception.

   $dg->set(file => 'exceptionsitelist', add => $site, comment => "Is not porn site");

This line will add $site to /etc/dansguardian/lists/exceptioniplist assuming that /etc/dansguardian/lists is current group directory

=item add => 'INFORMATION'

The 'add' value is the information to add in dansguardian control file. For example: If you need add one IP for bannediplist control file, then assign 'IP' value for add hash key.

=item comment => 'OPTIONAL COMMENT'

=back

This key is optional but very usefull for reading control files. It add comment at final line, after the 'add' value. 

=cut

sub set ($;@) {
	my ($self, %args) = @_;
	croak "undefined arguments, yo must set up 'file' and 'add'" unless ($args{add} and $args{file});
	my $file = "$self->{group_dir}/$args{file}";
	&agregar($file,$args{add},$args{comment});
	return 1;
}

=pod

=head2 $dg->remove($file)

remove method must have one hash attribute with keys: 

=over 3

=item file => 'FILE'

The FILE value is the file (locate inside current group dir) where you wish remove information.

=item line => 'LINE/IP/SITE/whatever'

The value of hash key line is the information for remove in dansguardian control file. For example: For remove IP address from bannediplist control file you must add 'IP' like value of line hash key.

=back

=head3 Example

   $dg->remove(file => 'bannediplist', line => '192.168.24.76');

=cut

sub remove {
	my ($self, %args) = @_;
	croak "undefined arguments, yo must set up 'file' and 'add'" unless $args{file} and $args{line};
	my $file = "$self->{group_dir}/$args{file}";
	&rm($file,$args{line});
	return 1;
}

=pod

=head2 $dg->get($file)

Get method return an array data with information inside content control file. The incoming parameter is the control file name. Example:

  @ips_banned = $dg->get('bannediplist')
  print "The IP address $_ is banned!!\n" foreach @banned_ips;


=cut

sub get ($) {
	my ($self, $file) = @_;	
	croak "undefined arguments, get() method must have file argument" unless $file;
	$file = "$self->{group_dir}/$file";
	my @data = &data($file);
	return @data;
}
	
### Common subrutines

sub data {
	my ($file) = @_;
	my @data;
	open(FILE, "$file") || croak "Can't open $file: $!";
	while (<FILE>){
		my ($data,$comments) = split((/\#/,$_));
		chomp($data);
		chomp $comments if $comments;
		$data =~ s/^\s+//;
		$data =~ s/\s+$//;
		push(@data,$data) if $data ne "";
	}
	close(FILE);
	return @data;
}

sub agregar {
	my ($file, $message, $comment) = @_;
	croak "You must set up 'file' and 'add' arguments" unless $file and $message;
	open(FILE, ">>$file") || croak "Can't open $file: $!";
   if ($comment) {
      print FILE "\n$message # $comment\n";
   } else {
      print FILE "\n$message\n";
   }
   close(FILE);
}

sub rm {
	my ($file, $line) = @_;
	tie my @content, 'Tie::File', $file or die "Can't open $file: $!";
	@content = grep { !/^$line/i } @content;
	untie @content;
}

1;

=pod

=head1 BUGS

The package don't have been bugs reported. If you find one notice me.

=head1 AUTHOR

Alejandro Garrido Mota <garridomota@gmail.com>.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2007 Alejandro Garrido Mota. All rights reserved. This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included with this module.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included with this module.

=cut

