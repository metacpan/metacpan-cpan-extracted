package Bot::BasicBot::Pluggable::Module::ReviewBoard;

use strict;
use warnings;

# ABSTRACT: Review Board Basic Bot IRC plugin

BEGIN { $Bot::BasicBot::Pluggable::Module::ReviewBoard::VERSION = '1.0.1' }

use base qw(Bot::BasicBot::Pluggable::Module);

use 5.010;
use LWP::Simple qw($ua);
use JSON qw( decode_json );


sub init {
	my $self = shift;

	$self->get( 'user_field_not_set' ) || $self->set( user_field_not_set => '*NOT SET*' );

	$self->{input_regexp} = 'rb (?:\#|\s)? (?<rb>\d+) | %RB_URL%/r/(?<rb>\d+)';

	$self->get( 'user_output_message' )
		|| $self->set( user_output_message =>
			'%SUBMITTER%(%GROUPS%) - branch: %BRANCH% - %SUMMARY%, last updated: %LAST_UPDATED% %RB_URL%/r/%ID%/' );
}

sub told {
	my ($self, $message) = @_;
	my $rb_url = $self->get( 'user_rb_url' );
	unless ( $rb_url ) {
		warn 'user_rb_url not set!';
		return;
	}
	my $regexp = $self->get( 'user_input_regexp' ) || $self->{input_regexp};

	$regexp =~ s{ %RB_URL% }{ $rb_url }xg;
	if ( $message->{body} =~ m{ $regexp }ix ) {
		if ( ( my $rb = $+{rb} ) =~ m{^\d+$} ) {
			return $self->_rb_message( $self->_get_rb_data( $rb ) );
		}
		else {
			warn "$rb is not a number, there must be something wrong with the input regexp";
		}
	}

	return;
}

sub help {
	return q{Matches rb followed by a number (e.g. rb1234) or an RB URL for a given rb (e.g. http://example.com/r/1234)
Variables:
* user_rb_url         - Review Board URL
* user_field_not_set  - This will replace the value when a field doesn't have a value in RB
* user_input_regexp   - The regexp that messages will be tested against, must include at least one named closure called "rb" that match the RB number.
  %RB_URL% will be replaced by the value from user_rb_url.
  Default: rb (?:\#|\s)? (?<rb>\d+) | %RB_URL%/r/(?<rb>\d+)
* user_output_message - The formatted output message. Words between two percent signs (e.g. %BRANCH%) will replaced with the data from RB. The following fields are available:
  RB_URL ID SUBMITTER GROUPS BRANCH BUGS_CLOSED SUMMARY TIME_ADDED LAST_UPDATED REPOSITORY DESCRIPTION PUBLIC PEOPLE TESTING_DONE.};
}

sub _get_rb_data {
	my ($self, $rb) = @_;
	$self->ua;
	my $content = decode_json LWP::Simple::get( sprintf( "%s/api/review-requests/%d", $self->get('user_rb_url'), $rb ) );
	my $review = $content->{review_request};
	my $groups = join ", ", map { $_->{title} } @{ $review->{target_groups} };
	my $people = join ", ", map { $_->{title} } @{ $review->{target_people} };
	my $bugs_closed = join ", ", @{ $review->{bugs_closed} };

	return {
		RB_URL       => $self->get('user_rb_url'),
		ID           => $review->{id},
		SUBMITTER    => $review->{links}->{submitter}->{title},
		GROUPS       => $groups,
		BRANCH       => $review->{branch},
		BUGS_CLOSED  => $bugs_closed,
		SUMMARY      => $review->{summary},
		TIME_ADDED   => $review->{time_added},
		LAST_UPDATED => $review->{last_updated},
		REPOSITORY   => $review->{repository}->{title},
		DESCRIPTION  => $review->{description},
		PUBLIC       => $review->{public},
		PEOPLE       => $people,
		TESTING_DONE => $review->{testing_done},
	};
}


sub ua { $ua }

sub _rb_message {
	my ($self, $rb_data) = @_;
	my $message = $self->get( 'user_output_message' );
	my $not_set = $self->get( 'user_field_not_set' );
	while ( my ($k, $v) = each %$rb_data ) {
		$v //= $not_set;
		$message =~ s{\Q%$k%\E}{$v}g;
	}

	return $message
}



1;

__END__

=pod

=head1 NAME

Bot::BasicBot::Pluggable::Module::ReviewBoard - Review Board Basic Bot IRC plugin

=head1 VERSION

version 1.0.1

=head1 SYNOPSIS

  use Bot::BasicBot::Pluggable;

  my $bot = Bot::BasicBot::Pluggable->new(
      server => "chat.freenode.net",
      port   => "6667",
      channels => [qw( #rbbottest ) ],
      nick      => "rbbot",
      username  => "rbbot",
      name      => "RB Bot",
      charset => "utf-8",
  );

  my $rb = $bot->load('ReviewBoard');
  $rb->set(rb_url => 'https://rb.example.com');
  $rb->ua->ssl_opts( verify_hostname => 0 );

  $bot->run();

=head1 DESCRIPTION

This BasicBot plugin allows to retrieve various information about submissions
to Review Board L<http://www.reviewboard.org/>.

=head1 METHODS

=head2 ua

Return the LWP::UserAgent object that will be used to connect with Review Board.

=head1 SETTINGS

=over

=item user_rb_url

Review Board URL

=item user_input_regexp

The regexp that messages will be tested against, must include at least
one named closure called "rb" that match the RB number.
%RB_URL% will be replaced by the value from user_rb_url.

Default: C<rb (?:\#|\s)? (?<rb>\d+) | %RB_URL%/r/(?<rb>\d+)>

=item user_field_not_set

This will replace the value when a field doesn't have a value in RB.

=item user_output_message

The formatted output message.
Tags between two percent signs (e.g. %BRANCH%) will replaced with
the data from RB. The following tags are available:

=over

=item RB_URL

Review Board URL set in user_rb_url.

=item ID

Review Board's submission reference number.

=item SUBMITTER

Submitter's username.

=item GROUPS

Groups that the review request belongs to.

=item BRANCH

The branch of the review request.

=item BUGS_CLOSED

The Bugs section of the review request.

=item SUMMARY

The Summary section of the review request.

=item TIME_ADDED

The timestamp when the review request was first posted.

=item LAST_UPDATED

The timestamp of the last update to the review request.

=item REPOSITORY

The repository that the review request is against.

=item DESCRIPTION

The description of the review request.

=item PUBLIC

A boolean to state whether the review request is public or not.

=item PEOPLE

The people added to the review request.

=item TESTING_DONE

The Testing Done section of the review request.

=back

=back

=head1 SEE ALSO

=over 4

=item *

L<Bot::BasicBot::Pluggable::Module>

=item *

L<Bot::BasicBot::Pluggable>

=item *

L<LWP::UserAgent>

=back

=head1 AUTHOR

Daniel Lukasiak

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Daniel Lukasiak.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
