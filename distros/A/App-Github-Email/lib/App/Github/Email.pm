package App::Github::Email;

use strict;
use warnings;

use LWP::UserAgent;
use Email::Address;
use List::MoreUtils qw(uniq);

# ABSTRACT: Search and print particular Github user emails.
our $VERSION = '0.1.1';    # VERSION


sub get_user
{
    my $username = shift;

    my $ua = LWP::UserAgent->new;
    my $get_json =
        $ua->get("https://api.github.com/users/$username/events/public");

    if ($get_json->is_success)
    {
        my $raw_json    = $get_json->decoded_content;
        my @addresses   = Email::Address->parse($raw_json);
        my @unique_addr = uniq @addresses;
        my @retrieved_addrs;

        for my $address (@unique_addr)
        {
            if ($address ne 'git@github.com' and not $address =~ /^":"/g)
            {
                push(@retrieved_addrs, $address);
            }
        }

        return @retrieved_addrs;
    }

    else
    {
        die "User is not exist!\n";
    }
}

=pod

=encoding UTF-8

=head1 NAME

App::Github::Email - Search and print particular Github user emails.

=head1 VERSION

version 0.1.1

=head1 SYNOPSIS

	github-email --name <Github username>

	github-email --name faraco
	github-email --n faraco 

=head2 Functions

=over 4

=item get_user($username)

    description: Retrieves Github user email addresses.

    parameter: C<$username> - Github account username.

    returns: A list of email addresses.

=back

=head1 AUTHOR

faraco <skelic3@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by faraco.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut

__END__


1;
