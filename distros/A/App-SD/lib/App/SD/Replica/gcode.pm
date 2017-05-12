 package App::SD::Replica::gcode;
use Any::Moose;
extends qw/App::SD::ForeignReplica/;

use Params::Validate qw(:all);
use File::Temp 'tempdir';
use Memoize;
use Try::Tiny;

use constant scheme => 'gcode';
use constant pull_encoder => 'App::SD::Replica::gcode::PullEncoder';
use constant push_encoder => 'App::SD::Replica::gcode::PushEncoder';
use Prophet::ChangeSet;

our %PROP_MAP = (
    summary    => 'summary',
    status     => 'status',
    owner      => 'owner',
    reporter   => 'reporter',
    cc         => 'cc',
    closed     => 'completed',
    reported   => 'created',
    labels     => 'tags',
    priority   => 'priority',
    mergedinto => 'merged_into',
    blockedon  => 'blocked_on',
);


has query            => ( isa => 'Str', is               => 'rw');
has gcode            => ( isa => 'Net::Google::Code', is => 'rw');
has project          => ( isa => 'Str', is               => 'rw');
has foreign_username => ( isa => 'Str', is               => 'rw' );

sub remote_url { return "http://code.google.com/p/".shift->project}

sub BUILD {
    my $self = shift;

    # Require rather than use to defer load
    try {
        require Net::Google::Code;
        require Net::Google::Code::Issue;
    } catch {
        die "SD requires Net::Google::Code to sync with Google Code.\n".
        "'cpan Net::Google::Code' may sort this out for you.\n";
    };

    $Net::Google::Code::Issue::USE_HYBRID = 1
      if $Net::Google::Code::VERSION ge '0.15';

    my ( $userinfo, $project, $query ) =
      $self->{url} =~ m!^gcode:(?:(.*)@)?(.*?)(?:/(.*))?$!
      or die
"Can't parse Google::Code server spec. Expected gcode:k9mail or gcode:user:password\@k9mail or gcode:user:password\@k9mail/q=string&can=all";
    $self->project($project);
    $self->url($project); # url should be raw url minus scheme and auth info
    $self->query($query) if defined $query;

    # Since we don't need a username / password to clone or pull, we don't save
    # the username and password here, if specified-- we only want to save
    # username/password combinations after they've been verified to work. (So
    # we save later if we end up trying to auth.) We do still want to parse any
    # username/password specified in the url.

    my ( $email, $password );
    if ( $userinfo ) {
        ( $email, $password ) = split /:/, $userinfo, 2;
    }

    my %gcode_args = ( project => $self->project );
    $gcode_args{email} = $email if $email;
    $gcode_args{password} = $password if $password;
    # should never fail (no auth performed on create)
    $self->gcode( Net::Google::Code->new( %gcode_args ) );

    try {
        $self->gcode->load();
    } catch {
        if ( $_ =~ m{Error GETing .*: Not Found} ) {
            die "The Google Code project '$project' does not exist. Aborting!\n";
        }
        else {
            # some other error
            die $_;
        }
    }
}

sub get_txn_list_by_date {
    my $self   = shift;
    my $ticket = shift;

    my $ticket_obj = Net::Google::Code::Issue->new( project => $self->project);
    $ticket_obj->load($ticket);
        
    my @txns = map {
        {
            id      => $_->sequence,
            creator => $_->author,
            created => $_->date->epoch,
        }
      }
      sort { $b->date <=> $a->date } @{ $ticket_obj->comments };
    return @txns;
}

sub remote_uri_path_for_comment {
    my $self = shift;
    my $id = shift;
    return "/comment/".$id;
}

sub remote_uri_path_for_id {
    my $self = shift;
    my $id = shift;
    return "/ticket/".$id;
}

sub database_settings {
    my $self = shift;
    my $issue = $self->gcode->issue;
    $issue->load_predefined;
    my $status = $issue->predefined_status;
    return {
        project_name => $self->project,
        $status
        ? (
            active_statuses => [ map { lc } @{ $status->{open} } ],
            statuses =>
              [ map { lc } @{ $status->{open} }, @{ $status->{closed} } ]
          )
        : (
            active_statuses => [qw/new accepted started/],
            statuses        => [
                qw/new accepted started duplicate fixed verified
                  invalid wontfix done/
            ],
        ),
    };
}

sub _uuid_url {
    my $self = shift;
    return $self->remote_url;
}

__PACKAGE__->meta->make_immutable;
no Any::Moose;

1;
