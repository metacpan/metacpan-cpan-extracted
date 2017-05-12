package App::booklog2amazon;

use utf8;
use strict;
use warnings;

# ABSTRACT: Update amazon recommended according to booklog status
our $VERSION = 'v0.0.1'; # VERSION

use Pod::Usage;

use YAML::Any;
use Time::Local;

use Net::Amazon::Recommended;
use WebService::Booklog;

sub _conv_time
{
	my ($time) = @_;
	if($time =~ /(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2}):(\d{2})/) {
		return timelocal($6, $5, $4, $3, $2 - 1, $1 - 1900);
	} elsif($time =~ /(\d+)年(\d+)月(\d+)日/) {
		return timelocal(0, 0, 0, $3, $2 - 1, $1 - 1900);
	} else {
		die "Can't parse $time";
	}
}

sub run
{
	shift if @_ && eval { $_[0]->isa(__PACKAGE__) };
	my $conffile = shift || "$ENV{HOME}/.booklog2amazon.yaml";
	die "You need to make config file: $conffile" if ! -f $conffile;
	my $conf = YAML::Any::LoadFile($conffile) or die "You need to make config file: $conffile";

	my $last_sync = $conf->{last_sync} || 0;
	my $new_last_sync = time;

	my %candidate;
	my $booklog = WebService::Booklog->new;
	my $dat;
	# Loop for registered date
	my $page = 1;
	do {
		$dat = $booklog->get_shelf($conf->{booklog}{account}, 'sort' => 'date_desc', page => $page);
		foreach my $item (@{$dat->{books}}) {
			if($item->{service_id} != 1) {
				warn "Not amazon.co.jp item: book_id => $item->{book_id}, service_id => $item->{service_id}, id => $item->{id}";
				next;
			}
			last if _conv_time($item->{create_on}) < $last_sync;
			$candidate{$item->{id}} = $item->{rank};
		}
		++$page;
	} while($dat->{pager}{maxpage} != $dat->{pager}{page} && _conv_time($dat->{books}[-1]{create_on}) >= $last_sync);
	# Loop for read date
	if($last_sync) { # For the initial time, all items are checked by the previous loop section
		$page = 1;
		do {
			$dat = $booklog->get_shelf($conf->{booklog}{account}, 'sort' => 'read_desc', page => $page);
			foreach my $item (@{$dat->{books}}) {
				if($item->{service_id} != 1) {
					warn "Not amazon.co.jp item: book_id => $item->{book_id}, service_id => $item->{service_id}, id => $item->{id}";
					next;
				}
				last if ! defined $item->{read_at} || _conv_time($item->{read_at}) < $last_sync;
				$candidate{$item->{id}} = $item->{rank};
			}
			++$page;
		} while($dat->{pager}{maxpage} != $dat->{pager}{page} && defined $dat->{books}[-1]{read_at} && _conv_time($dat->{books}[-1]{read_at}) >= $last_sync);
	}

	print scalar(keys %candidate), " candidate items found\n";

	my $amazon = Net::Amazon::Recommended->new(
		email => $conf->{amazon}{email},
		password => $conf->{amazon}{password},
	);
	{
		local $| = 1;
		foreach my $item (keys %candidate) {
			print '.';
			my $status = { isOwned => 1 };
			$status->{starRating} = $candidate{$item} if $candidate{$item};
			$amazon->set_status($item, $status);
		}
	}
	print "\n";

	$conf->{last_sync} = $new_last_sync;
	YAML::Any::DumpFile($conffile, $conf);
}

1;

__END__

=pod

=head1 NAME

App::booklog2amazon - Update amazon recommended according to booklog status

=head1 VERSION

version v0.0.1

=head1 SYNOPSIS

  App::booklog2amazon->run(@ARGV);

=head1 DESCRIPTION

This is an implementation module for a script to update amazon recommended according to booklog status

=head1 METHODS

=head2 C<run(@arg)>

Process arguments. Typically, C<@ARGV> is passed. For argument details, see L<booklog2amazon>.

=head1 SEE ALSO

=over 4

=item *

L<booklog2amazon>

=item *

L<Net::Amazon::Recommended>

=item *

L<WebService::Booklog>

=back

=head1 AUTHOR

Yasutaka ATARASHI <yakex@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Yasutaka ATARASHI.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
