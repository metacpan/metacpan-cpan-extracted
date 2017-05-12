package Config::Lite;

use strict;
use warnings;
use Fcntl qw/:flock/;

require Exporter;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(load_config set_config_separator);
our @EXPORT = qw();
our $VERSION = '0.03';

our %separator;
$separator{'kv'} = "=";
$separator{'comment'} = "#";
$separator{'line'} = "\n";

sub set_config_separator
{
	my $kind = shift;
	my $str = shift;
	$separator{$kind} = $str;
	return 1;
}

sub load_config
{
	my $config_filename = shift;
	open my $fh,"<", $config_filename or return "no config file found";
	flock $fh, LOCK_SH;
	my $config_string = do { local $/ ; <$fh> };
	flock $fh, LOCK_UN;
	close $fh;

	my @config_array = split /$separator{'line'}/, $config_string;
	my %config_hash;
	foreach ( @config_array )
	{
		next unless $_ =~ /$separator{'kv'}/;
		next if $_ =~ /^$separator{'comment'}/;
		my ($k, $v) = $_ =~ /\s*(.+?)$separator{'kv'}(.+?)\s*$/;
		$config_hash{$k} = $v;
	}
	return %config_hash;
}



1;
__END__

=head1 NAME

Config::Lite - Load config from file to hash.

=head1 SYNOPSIS

Once you make a config file like this:

  # /etc/myconfig.conf
  test1=123
  test2=abc
  right=left
  pop = bad  [
  so =gogogo
  lover = yejiao       
  #sharped=somevalue

You can code like this:

  use Config::Lite qw(load_config);
  my %config = load_config("/etc/myconfig.conf");

You got this:

  # %config = (
  #   "test1" => 123,
  #   "test2" => "abc",
  #   "right" => "left",
  #   "pop" => "bad  [",
  #   "so" => "gogogo",
  #   "lover" => "yejiao",
  # );

=head1 DESCRIPTION

Simple config load module.

Clean and no dependence. 

Easy to use and install.  

I<flock> inside.


=head1 METHODS

=head2 set_config_separator($type, $string)

Optional.

User set separator. Always return 1.

use set_config_separator("kv", "your_separator") set separator between key and value.

use set_config_separator("line", "your_separator") set separator between lines.

use set_config_separator("comment", "your_separator") set separator before a comment line.

=head2 load_config($filename)

Main method.

Read config file into a hash then return it.


=head1 EXPORT

None by default.



=head1 SEE ALSO

L<Config::Auto>, L<Config::General>

=head1 AUTHOR

Chen Gang, E<lt>yikuyiku.com@gmail.comE<gt>

L<http://blog.yikuyiku.com/>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Chen Gang

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=cut
