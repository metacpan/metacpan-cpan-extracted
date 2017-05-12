package App::cdnget::Exception;
use Object::Base qw(Object::Exception);
use v5.14;
use bytes;
use DateTime;


BEGIN
{
	our $VERSION     = '0.03';
}


sub msg :lvalue
{
	my $self = shift;
	my ($msg) = @_;
	my @args = @_;
	if (@args >= 1 and not ref($msg))
	{
		$msg = "Unknown" unless $msg;
		my $dts = DateTime->now(time_zone => POSIX::strftime("%z", localtime), locale => "en")->strftime('%x %T %z');
		$msg = "[$dts] $msg";
		$args[0] = $msg;
	}
	$self->SUPER::msg(@args);
}


1;
__END__
=head1 REPOSITORY

B<GitHub> L<https://github.com/orkunkaraduman/p5-cdnget>

B<CPAN> L<https://metacpan.org/release/App-cdnget>

=head1 AUTHOR

Orkun Karaduman <orkunkaraduman@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017  Orkun Karaduman <orkunkaraduman@gmail.com>

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

=cut
