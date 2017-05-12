package App::RemoteGnokii;

use 5.014000;
use strict;
use warnings;
our $VERSION = '0.001';

use Config::Any;
use File::Copy qw/move/;
use File::Temp qw/tempfile/;
use Plack::Request;

my $cfg;

sub cfg ($){ ## no critic (ProhibitSubroutinePrototypes)
	unless ($cfg) {
		$cfg = Config::Any->load_stems({stems => [$ENV{RGCONFIG} // '/etc/rg'], use_ext => 1, flatten_to_hash => 1});
		my @cfg = values %$cfg;
		$cfg = $cfg[0];
	}

	$cfg->{$_[0]}
}

sub sendsms {
	my ($number, $text) = @_;
	my ($fh, $file) = tempfile 'smsXXXX', TMPDIR => 1;
	print $fh "$number\n$text" or warn "print: $!"; ## no critic (RequireCarping)
	close $fh or warn "close: $!"; ## no critic (RequireCarping)
	move $file, cfg 'spool';
}

##################################################

sub action {
	my ($number, $date, $text) = @_;
	my $password = cfg 'password';
	sendsms cfg 'number', <<"EOF"
$password
$number
$date
$text
EOF
}

sub psgi {
	my $correct_password = cfg 'password';
	sub {
		my $r = Plack::Request->new(shift);
		my @numbers = split /,/s, $r->param('numbers');
		my $password = $r->param('password');
		return [403, ['Content-Type', 'text/plain'], ['Bad password']] unless $password eq $correct_password;
		my $text = $r->param('text');

		sendsms $_, $text for @numbers
	}
}

1;
__END__

=encoding utf-8

=head1 NAME

App::RemoteGnokii - Send SMS over the internet with gnokii-smsd

=head1 SYNOPSIS

  use App::RemoteGnokii;
  my $config_option = App::RemoteGnokii::cfg 'name';
  App::RemoteGnokii::sendsms '0755555555', 'Hello world';
  App::RemoteGnokii::action('0755555555', '2014-02-01', 'Goodbye');

=head1 DESCRIPTION

RemoteGnokii is a set of scripts that add networking to gnokii-smsd. With them, all messages received are forwarded to a given phone number, and messages can be sent via the HTTP gateway provided by RemoteGnokii.

=head1 CONFIGURATION OPTIONS

See below for the location of the configuration file. The following options are recognised:

=over

=item number

Forward incoming messages to this number (used by L<rg-action>).

=item password

The password needed to send a message with L<rg-psgi> and included in forwarded messages.

=item spool

The gnokii-smsd spool directory. Needs to be readable and writable by gnokii-smsd and L<rg-psgi>.

=back

=head1 ENVIRONMENT

=over

=item RGCONF

The basename of the configuration file. For example, if the configuration file is '/srv/rg/config.yml', RGCONF should be set to '/srv/rg/config'. Defaults to '/etc/rg'.

=back

=head1 TODO

=over

=item Write a section 7 manpage explaining everything

=item Add tests

=item Add a way to store messages for later retrieval via the webapp, instead of sending them immediately via SMS

=back

=head1 AUTHOR

Marius Gavrilescu E<lt>marius@ieval.roE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Marius Gavrilescu

This library is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or (at
your option) any later version.


=cut
