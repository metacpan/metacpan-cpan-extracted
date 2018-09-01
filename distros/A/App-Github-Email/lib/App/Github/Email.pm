package App::Github::Email;
$App::Github::Email::VERSION = '0.3.3';
# ABSTRACT: Search and print particular Github user emails.

use strict;
use warnings;

use Carp qw(confess); 
use JSON;
use LWP::UserAgent;
use List::MoreUtils qw(uniq);


sub get_user {
    my $username = shift;

    my $ua = LWP::UserAgent->new;
    my $get_json =
      $ua->get("https://api.github.com/users/$username/events/public");

    if ( $get_json->is_success ) {
        my $raw_json    = $get_json->decoded_content;
        my $dec_json    = decode_json $raw_json;
        my @push_events = grep { $_->{type} eq 'PushEvent' } @{$dec_json};
        my @commits     = map { @{$_->{payload}->{commits}} } @push_events;
        my @addresses   = map { $_->{author}->{email} } @commits;
        my @unique_addr = uniq @addresses;
        my @retrieved_addrs;

        for my $address (@unique_addr) {
            if ( $address ne 'git@github.com' and not $address =~ /^":"/g ) {
                push( @retrieved_addrs, $address );
            }
        }

        return @retrieved_addrs;
    }

    else {
        confess("User is not exist.");
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Github::Email - Search and print particular Github user emails.

=head1 VERSION

version 0.3.3

=head1 SYNOPSIS

    github-email --username <Github username>

    # Example
    github-email --username faraco
    github-email --u faraco

=head2 Functions

=over 4

=item get_user($username)

    description: Retrieves Github user email addresses.

    parameter: $username - Github account username.

    returns: A list of email addresses.

=back

=head1 AUTHOR

faraco <skelic3@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017-2018 by faraco.

This is free software, licensed under:

  The MIT (X11) License

=cut
