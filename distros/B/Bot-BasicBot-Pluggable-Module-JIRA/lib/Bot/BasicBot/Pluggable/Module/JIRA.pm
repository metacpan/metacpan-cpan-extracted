package Bot::BasicBot::Pluggable::Module::JIRA;
BEGIN {
  $Bot::BasicBot::Pluggable::Module::JIRA::VERSION = '0.03';
}

use warnings;
use strict;

=head1 NAME

Bot::BasicBot::Pluggable::Module::JIRA - Access JIRA via IRC!

=head1 VERSION

This POD describes version 0.02

=cut

=head1 SYNOPSIS

You will need to load the module into your instance:

    $bot->load('JIRA');

Then feel free to interrogate the shit out of her:

    <diz> purl: what's going on with PRJ-284?
    <purl> diz: PRJ-284 (add jira support to bot) is unresolved - http://jira.domain.com/issue/284
    <diz> purl: who fixed PRJ-284?
    <purl> diz: gphat marked PRJ-284 as fixed in changeset bbb6a0f9

=head1 CONFIGURATION

=head2 uri

The location of the JIRA instance.  (Ex, http://jira.domain.com)

=head2 username

User to authenticate against JIRA with.  This is configured in JIRA.
Note that the user will need permissions to view issues in order to
send getIssue requests over the SOAP interface.

=head2 password

The password to use for the user during authentication.  Also setup in
JIRA (or LDAP if you're using the LDAP linkage).

=head2 db_dsn (optional)

=head2 db_user (optional)

=head2 db_pass (optional)

The SOAP API in JIRA is hit or miss.  It exposes functionality that
I'll never use while omitting other functionality that makes the API
seem downright useless.

One of the particular egregious omissions happens to be the lack of a
remote interface for retrieving the ChangeHistory for an issue.  If,
however, you configure db_dsn, db_user, and db_pass, this module will
attempt to extract that information directly from the database.  This
isn't recommended and has only been tested with 4.1.2.

=head2 status_verbs

The default inquiry format reports issue status by referring to the
last status change in the past tense.  By default, the reply uses
"changed to" prepended to the status name.  Instead of this, you may
want the bot to respond using more colloquial language.  You may do
this by setting status_verbs to a hashref mapping status names to
status verb phrases.  (ie, { Open => 'opened' })  Any missing pairs
default to "changed to".

=head2 status_colors

This one is fun.  You may map issue status names to individual IRC
colors by setting status_colors to a hashref containing the map.  The
following colors are understood:

=over 2

=item * bold

=item * white

=item * black

=item * blue

=item * green

=item * red

=item * brown

=item * purple

=item * orange

=item * yellow

=item * light_green

=item * teal

=item * cyan

=item * light_blue

=item * pink

=item * gray

=back

=head2 formats

Inquiry responses may be custom formatted.  The formats configuration
item is expected to be a hashref containing key/value pairs for each
class of inquiry.  The format is rendered using Text::Xslate.  Several
convienient xslate functions have also been provided.  In addition to
a function for each of the individual color names above, the following
functions are available:

=over 2

=item * colorize

colors the given text according to the configured status_colors

=back

The RemoteIssue object returned by JIRA::CLient is the root context of
the template rendering, with the following keys added to the hashref:

=over 2

=item * issue (shortcut for key)

=item * version (shortcut for the first fixVersion listed)

=item * status_name (the issue's current status)

=item * status_verb (the issue's current status in the past tense)

=back

If you've enabled the DBI options above, these are also available to
you:

=over 2

=item * status_last_changed_user (user that most recently changed the issue status)

=item * status_last_changed_datetime (DateTime object for the most recent status change)

=back

More details on the RemoteIssue object may be found in the JIRA docs:

http://docs.atlassian.com/rpc-jira-plugin/4.1-1/com/atlassian/jira/rpc/soap/beans/RemoteIssue.html

Most all accessors methods on the RemoteIssue object are available in
the stash as keys of the hashref.  For example, getAssignee may be
accessed in xslate like:

    <: $assignee :>

The getComponents method, which returns a list of components, may be
accessed using similar perl/xslate idioms:

    <: $components.0 :>

The default inquiry format is:

    <: colorize($issue) :> [<: $version :>] <: bold($summary) :> for <: $assignee :>

which produces replies such as:

    <purl> PRJ-284 [Unscheduled] add jira to bot for diz

The default status format is:

    <: $issue :> [<: $version :>] was <: $status_verb :> by <: $status_last_changed_user :> on <: $status_last_changed_datetime.strftime("%Y %b %d (%a) at %l:%M %P") :>

which produces replies such as:

    <purl> PRJ-284 [Unscheduled] was closed by diz on 2010 Sep 13 (Mon) at  1:26 pm

=cut

use Moose;
use MooseX::Traits;

use POE;
use Try::Tiny;

use DateTime;
use DateTime::Format::MySQL;
use Lingua::StopWords::EN;
use JIRA::Client;
use Text::Xslate;

#use Data::Dump qw(dd pp);

#$Data::Dump::INDENT = '';

extends 'Bot::BasicBot::Pluggable::Module';

has log =>
	is			=> 'ro',
	isa			=> 'Log::Log4perl::Logger',
	lazy		=> 1,
	default		=> sub { Log::Log4perl->get_logger(__PACKAGE__) };

has xslate =>
	is			=> 'ro',
	isa			=> 'Text::Xslate',
	lazy_build	=> 1;

has client =>
	is			=> 'ro',
	lazy_build	=> 1;

has dbh =>
	is			=> 'rw',
	isa			=> 'Maybe[DBI::db]';

has sths =>
	is			=> 'rw',
	isa			=> 'HashRef[DBI::st]';

has projects =>
	is			=> 'ro',
	isa			=> 'ArrayRef[RemoteProject]',
	lazy_build	=> 1;

has project_keys =>
	is			=> 'ro',
	isa			=> 'ArrayRef[Str]',
	lazy_build	=> 1;

has context =>
	is			=> 'rw',
	isa			=> 'RemoteIssue';

has statuses =>
	is			=> 'ro',
	isa			=> 'HashRef',
	lazy_build	=> 1,
	traits		=> [ 'Hash' ],
	handles		=> { get_status_name => 'get', get_statuses => 'values' };

has status_verbs =>
	is			=> 'ro',
	isa			=> 'HashRef',
	lazy_build	=> 1,
	traits		=> [ 'Hash' ],
	handles		=> { get_verb_for_status => 'get' };

has status_colors =>
	is			=> 'ro',
	isa			=> 'HashRef',
	lazy_build	=> 1,
	traits		=> [ 'Hash' ],
	handles		=> { get_color_for_status => 'get' };

has formats =>
	is			=> 'ro',
	isa			=> 'HashRef',
	lazy_build	=> 1,
	traits		=> [ 'Hash' ],
	handles		=> { get_format_for_inquiry => 'get' };

has stopwords =>
	is			=> 'ro',
	isa			=> 'HashRef',
	lazy		=> 1,
	default		=> sub { Lingua::StopWords::EN->getStopWords };

has regex =>
	is => 'ro',
	lazy_build => 1;

has handlers =>
	is			=> 'ro',
	isa			=> 'ArrayRef',
	traits		=> [ 'Array' ],
	lazy		=> 1,
	default		=> sub { [] },
	handles		=> { add_handler => 'push' };

sub _build_xslate
{
	my $self = shift;

	my $colorizers =
	{
		bold		=> sub { "$_[0]" },
		white		=> sub { "0$_[0]" },
		black		=> sub { "1$_[0]" },
		blue		=> sub { "2$_[0]" },
		green		=> sub { "3$_[0]" },
		red			=> sub { "4$_[0]" },
		brown		=> sub { "5$_[0]" },
		purple		=> sub { "6$_[0]" },
		orange		=> sub { "7$_[0]" },
		yellow		=> sub { "8$_[0]" },
		light_green	=> sub { "9$_[0]" },
		teal		=> sub { "10$_[0]" },
		cyan		=> sub { "11$_[0]" },
		light_blue	=> sub { "12$_[0]" },
		pink		=> sub { "13$_[0]" },
		gray		=> sub { "14$_[0]" },
	};

	new Text::Xslate
		function =>
		{
			%$colorizers,

			colorize => sub {
				my $status		= $self->get_status_name($self->context->{status});
				my $color		= $self->get_color_for_status($status) || '';
				my $colorizer	= $colorizers->{$color};

				return $colorizer ? $colorizer->($_[0]) : $_[0];
			}
		};
}

sub _build_client
{
	my $self = shift;

	# we have to use the Store directly since Moose already
	# defines a get method for us.

	my $uri		= $self->store->get(JIRA => 'uri');
	my $user	= $self->store->get(JIRA => 'username');
	my $pass	= $self->store->get(JIRA => 'password');
	my $client	= undef;

	$self->log->warn('missing configuration item "uri"')		if not $uri;
	$self->log->warn('missing configuration item "username"')	if not $user;
	$self->log->warn('missing configuration item "password"')	if not $pass;

	return undef unless $uri and $user and $pass;

	my $meta = Class::MOP::Class->initialize('JIRA::Client');

	$meta->add_around_method_modifier(AUTOLOAD => sub {
		my $next	= shift;
		my $self	= shift;
		my @args	= @_;
		my $res		= undef;

		try {
			$res = $self->$next(@args);
		} catch {
			if (/RemoteAuthenticationException/) {
				my $auth = $self->{soap}->login($user, $pass);

				die $auth->faultcode . ': ' . $auth->faultstring
					if defined $auth->fault;

				$self->{auth} = $auth->result;
				$res = $self->$next(@args);
			} else {
				die $_;
			}
		};

		return $res;
	});

	return new JIRA::Client $uri, $user, $pass;
}

sub _build_projects
{
	my $self = shift;

	return $self->client
		? $self->client->getProjectsNoSchemes
		: [];
}

sub _build_project_keys
{
	my $self = shift;

	my @keys = map { $_->{key} } @{ $self->projects };

	return \@keys;
}

sub _build_statuses
{
	my $self = shift;

	my $statuses = { map { $_->{id} => $_->{name} } @{ $self->client->getStatuses } };

	#foreach my $status (values %$statuses) {
	#	$status =~ s/under quality review/submitted for QA/;
	#	$status =~ s/under technical review/submitted for review/;
	#}

	return $statuses;
}

sub _build_status_verbs
{
	my $self = shift;

	my $verbs = $self->store->get(JIRA => 'status_verbs');

	$verbs = {} unless ref($verbs) eq 'HASH';

	foreach my $status ($self->get_statuses) {
		$verbs->{$status} ||= "changed to $status";
	}

	return $verbs;
}

sub _build_status_colors
{
	my $self = shift;

	my $colors = $self->store->get(JIRA => 'status_colors');

	$colors = {} unless ref($colors) eq 'HASH';

	return $colors;
}

sub _build_formats
{
	my $self = shift;

	my $formats = $self->store->get(JIRA => 'formats');

	$formats = {} unless ref($formats) eq 'HASH';

	return
	{
		default	=> '<: colorize($issue) :> [<: $version :>] <: bold($summary) :> for <: $assignee :>',
		status	=> '<: $issue :> [<: $version :>] was <: $status_verb :> by <: $status_last_changed_user :> on <: $status_last_changed_datetime.strftime("%Y %b %d (%a) at %l:%M %P") :>',
		%$formats
	#my $date	= $dt->strftime('%Y %b %d (%a)');
	#my $time	= $dt->strftime('%l:%M %P');
	}
}

sub _build_regex
{
	my $self = shift;

	my $keys	= join '|', @{ $self->project_keys };
	my $re		= qr/([a-zA-Z]*)\s*((?:$keys)-[0-9]+)/;

	return $re;
}

sub init
{
	my $self = shift;

	$self->init_dbh;

	$self->add_handler([ qr/fix(ed|es)/			=> \&inquiry_fixed ]);
	$self->add_handler([ qr/closed/				=> \&inquiry_closed ]);
	$self->add_handler([ qr/opened|reported/	=> \&inquiry_reporter ]);
	$self->add_handler([ qr/status/				=> \&inquiry_status ]);
	#$self->add_handler([ qr/details/			=> \&inquiry_details ]);
	$self->add_handler([ qr/.?/					=> \&inquiry_default ]);
}

sub init_dbh
{
	my $self = shift;

	my $dsn		= $self->store->get(JIRA => 'db_dsn');
	my $user	= $self->store->get(JIRA => 'db_user');
	my $pass	= $self->store->get(JIRA => 'db_pass');

	return unless $dsn and $user and $pass;

	$self->dbh(DBI->connect($dsn, $user, $pass));

	$self->sths({
		last_status_modification_info => $self->dbh->prepare('SELECT cg.created, cg.author FROM changegroup cg JOIN changeitem ci ON ci.groupid=cg.ID JOIN jiraissue ji ON ji.id=cg.issueid WHERE ji.pkey=? AND ci.field="status" ORDER BY cg.created DESC LIMIT 1')
	});

	foreach my $name (keys %{ $self->sths }) {
		my $coderef = sub {
			my $self	= shift;
			my $issue	= shift;

			$self->sths->{$name}->execute($issue);
			$self->sths->{$name}->fetch;
		};

		$self->meta->add_method("get_$name" => $coderef);
	}
}

sub inquiry_fixed
{
}

sub inquiry_closed
{
}

sub inquiry_reporter
{
}

sub inquiry_details
{
	my $self		= shift;
	my $issue		= shift;
	my $callback	= shift;

	# IDEA: using the stopword filter, pull out text at
	# random out of the description and display it.  kinda
	# neat.  multiple calls will return different things,
	# exposing information about the ticket without flooding
	# the channel

	my $href	= $self->client->getIssue($issue);

	return unless defined $href;

	my $ver		= $href->{fixVersions}->[0] ? $href->{fixVersions}->[0]->{name} : '';
	my $details	= '';

	if ($href->{description} < 80) {
		$details = $href->{description};
	} else {
		my @tokens = grep { not exists $self->stopwords->{$_} }
			split /\s+/, $href->{description};
		my %keywords = map { $tokens[int rand $#tokens] => 1 } (1 .. 10);

		$details = join ', ', keys %keywords;
	}

	$callback->("$issue [$ver] details: $details");
}

sub inquiry_status
{
	my $self		= shift;
	my $key			= shift;
	my $callback	= shift;

	my $issue = $self->get_issue($key);

	return unless defined $issue;

	#my $status	= $self->get_status_name($issue->{status});
	#my $color	= $self->get_color_for_status($status);
	#my $verb	= $self->get_verb_for_status($status);
	#my $aref	= $self->get_last_status_modification_info($issue);
	#my $dt		= DateTime::Format::MySQL->parse_datetime($aref->[0]);
	#my $user	= $aref->[1];
	#my $date	= $dt->strftime('%Y %b %d (%a)');
	#my $time	= $dt->strftime('%l:%M %P');

	#$time =~ s/^ //;

	$callback->($self->render(status => $issue));

	#$callback->("$issue [$ver] was $sverb by $user on $date at $time");
}

sub get_issue
{
	my $self	= shift;
	my $key		= shift;

	my $issue = $self->client->getIssue($key);

	if ($issue) {
		my $status	= $self->get_status_name($issue->{status});
		my $color	= $self->get_color_for_status($status);

		$issue->{issue}			= $issue->{key};
		$issue->{status_name}	= $status;
		$issue->{status_verb}	= $self->get_verb_for_status($status);

		if ($self->meta->has_method('get_last_status_modification_info')) {
			if (my $aref = $self->get_last_status_modification_info($key)) {
				my $dt		= DateTime::Format::MySQL->parse_datetime($aref->[0]);
				my $user	= $aref->[1];

				$issue->{status_last_changed_user} = $aref->[1];
				$issue->{status_last_changed_datetime} = $dt;
			}
		}

		$issue->{version} = $issue->{fixVersions}->[0]
			? $issue->{fixVersions}->[0]->{name}
			: 'Unscheduled';

		$self->context($issue);
	}

	return $issue;
}

sub inquiry_default
{
	my $self		= shift;
	my $key			= shift;
	my $callback	= shift;

	my $issue = $self->get_issue($key);

	return unless defined $issue;
	#dd $issue;

	#my $msg = $self->xslate->render_string($self->get_format_for_inquiry('default'), $issue);

	$callback->($self->render(default => $issue));
}

sub render
{
	my $self	= shift;
	my $format	= shift;
	my $issue	= shift;

	return $self->xslate->render_string($self->get_format_for_inquiry($format), $issue);
}

sub said
{
	my $self = shift;
	my $msg = shift;
	my $pri = shift;

	#dd { priority => $pri, %$msg};

	return if $pri == 0;

	#$self->log->info("said(pri => $pri)");

	my $re			= $self->regex;
	my @tokens		= grep { not exists $self->stopwords->{$_} } split /\s+/, $msg->{body};
	my $body		= join ' ', @tokens;

	my @response	= ();
	my $callback	= sub { push @response, $_[0] ? $_[0] : () };

	# strip shit out of the message
	#$body =~ s/\?//g;

	if (my @pairs = ($body =~ /$re/g)) {
		#$callback->('match');

		while (my ($inquiry, $issue) = splice @pairs, 0, 2) {
			my $handler = [ grep { $inquiry =~ $_->[0] } @{ $self->handlers } ]->[0]->[1];

			$handler->($self, $issue, $callback) if $handler and $self->client;
		}
	}

	$self->say(%$msg, body => $_) foreach @response[0..$#response-1];

	return $response[$#response];
}

=head1 BUGS

Probably a lot of them.  The test suite does nothing beyond what
Module::Starter already provides.

=head1 AUTHOR

Mike Eldridge, C<< <diz at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Mike Eldridge

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=head1 SEE ALSO

=over 2

=item * L<Bot::BasicBot::Pluggable>

=item * L<JIRA::Client>

=back

=cut

1;

