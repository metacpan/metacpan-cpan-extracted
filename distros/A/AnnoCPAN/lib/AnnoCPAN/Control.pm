package AnnoCPAN::Control;

$VERSION = '0.22';

use strict;
use warnings;
no warnings 'uninitialized';
use AnnoCPAN::Config;
use AnnoCPAN::DBI;
use CGI::Cookie;
use Digest::MD5 qw(md5_hex);
use IO::String;
use POSIX qw(ceil);
use Lingua::EN::Inflect qw(NO);
use AnnoCPAN::Feed;

# it should be possible to subclass this module to use a different
# interface and templating system by overriding new and the simple
# 'delegational' methods param, process, header...

=head1 NAME

AnnoCPAN::Control - Main AnnoCPAN Web Interface Control Module

=head1 SYNOPSIS

    # in the simplest case, this is all you need...
    use AnnoCPAN::Control;
    AnnoCPAN::Control->new->run;

=head1 DESCRIPTION

This is the main module that handles the AnnoCPAN web application. It handles
getting the CGI parameters, running the appropriate handlers, and making sure
that the appropriate templates are processed.

=head1 METHODS

=over

=item $class->new(%options)

Create a new AnnoCPAN control object. Options:

 cgi => cgi object
 tt  => template object

=cut

sub new {
    my ($class, %args) = @_;
    my $self = bless {
        log => [],
        cgi => $args{cgi} || CGI->new, 
        tt  => $args{tt}  || Template->new(
            INCLUDE_PATH => AnnoCPAN::Config->option('template_path'),
            PRE_PROCESS => 'util.tt',
            FILTERS => { myuri => \&myuri_filter },
        ),
    }, $class;
    $self;
}

=item $obj->run

Process the request. This includes figuring out the runmode, checking if 
the user is logged in, running the handler, printing the headers, and
processing the template.

=cut

sub run {
    my ($self) = @_;
    my $mode = $self->mode;
    $self->check_login;
    my ($vars, $template, $type);

    eval {
        ($vars, $template, $type) = $self->$mode;
    };
    if ($@) {
        $vars     = { error => $@ };
        if ($self->param('fast')) {
            $template = 'error';
        } else {
            ($vars, $template, $type) = $self->Main($vars);
        }
    }
    if ($template) {
        my $default_vars = $self->default_vars;
        $vars = { %$default_vars, %$vars };
        print $self->header(
            -charset => 'UTF-8',
            -cookie => $self->cookies,
            $type ? (-type => $type) : (),
        );
        $template .= '.html' unless $template =~ /\./;
        my $output = '';
        $self->process($template, $vars, \$output) or print $@;
        print $output;
    }
}

=item $obj->mode

Return the runmode. Runmodes must be made of word characters, begin with an
uppercase letter, and be a method in $obj.

=cut

sub mode {
    my ($self) = @_;
    my $mode = ucfirst $self->param('mode');
    #$self->_log("mode?=($mode)");
    $mode = 'Main' unless $mode =~ /^[A-Z]\w+$/ and $self->can($mode);
    #$self->_log("mode=($mode)");
    $mode;
}

=item $obj->cgi

Returns the CGI object.

=cut

sub cgi { shift->{cgi} }

=item $obj->tt

Returns the Template object.

=cut

sub tt  { shift->{tt} }

=item $obj->param(@_)

Get CGI parameters. Delegated to $self->cgi.

=cut

sub param { shift->cgi->param(@_) }

sub param_obj {
    my ($self, $name, $key) = @_;
    my (@values) = $self->param(lc $name)
        or  die "unspecified $name\n";
    my $class = "AnnoCPAN::DBI::$name";
    $key ||= 'id';
    my @objs;
    for my $value (@values) {
        $key ne 'id' or $value =~ /^\d+$/
            or  die "invalid $name: '$value'\n";
        my $obj = $class->retrieve($key => $value)
            or die "$name '$value' not found\n";
        return $obj unless wantarray;
        push @objs, $obj;
    }
    return @objs;
}

=item $obj->header(@_)

Return HTTP headers as a string. Delegated to $self->cgi.

=cut

sub header { shift->cgi->header(@_) }

=item $obj->redirect($uri)

Print a 303 HTTP redirect header, including the cookies in $obj->cookies.

=cut

sub redirect {
    my ($self, $uri) = @_;
    unless ($uri =~ /^\w+:/) {
        require URI;
        $uri = URI->new(AnnoCPAN::Config->option('root_uri_abs') . $uri);
        $uri->host($ENV{HTTP_HOST});
    }
    print $self->header(
        -cookie => $self->cookies, 
        -status => $ENV{REQUEST_METHOD} eq 'POST' ? 303 : 302, 
        -location => $uri,
    );
}

=item $obj->process($template_file, \%vars [, \$ret])

Process a template. Delegated to $self->tt.

=cut

sub process { shift->tt->process(@_) }

=item $obj->default_vars

Return a hashref with the default template variables, common to all runmodes
(for example, the user object).

=cut

sub default_vars {
    my ($self) = @_;
    +{
        param        => sub { $self->param(@_) },
        user         => $self->user,
        mode         => $self->mode,
        log          => $self->{log},
        prefs        => sub { $self->prefs(@_) },
        my_html      => sub { $self->my_html(@_) },
        request_uri  => $ENV{REQUEST_URI},
        cgi          => $self->cgi,
        root_uri_rel => AnnoCPAN::Config->option('root_uri_rel'),
        img_root     => AnnoCPAN::Config->option('img_root'),
        root_uri_abs => AnnoCPAN::Config->option('root_uri_abs'),
        NO           => \&NO,
    }
}

=item $obj->prefs($pref_name)

Returns the value for a given user preference.

=cut

sub prefs {
    my ($self, $name) = @_;
    my $user = $self->user;
    my $value;
    if ($user) {
        $value = AnnoCPAN::DBI::Prefs->retrieve(user => $user, name => $name);
    }
    defined $value ? $value->value : AnnoCPAN::Config->option($name);
}

=item $obj->cookies

Return an arrayref with the current cookies (which are L<CGI::Cookie> objects).

=cut

sub cookies { 
    my ($self) = @_;
    $self->{cookies} || [];
}

=item $obj->add_cookie($name, $value)

Create a cookie. It will be later pushed to the client with the HTTP headers,
and it is immediately available via $obj->cookies.

=cut

sub add_cookie {
    my ($self, $name, $val) = @_;

    my $max_time = AnnoCPAN::Config->option('cookie_duration');
    push @{$self->{cookies}}, CGI::Cookie->new(
        -name => $name, -value => $val,
        $max_time ? (-expires => "+${max_time}d") : (),
    );
}

=item $obj->delete_cookie($name)

Issue an expired cookie with a given name, forcing the client to forget it (one
use is for logging out).

=cut

sub delete_cookie {
    my ($self, $name) = @_;
    push @{$self->{cookies}}, CGI::Cookie->new(
        -name => $name, -value => '', -expires => '-1Y',
    );
}

=item $obj->check_login

Check if the user is logged in (by checking the login, time, and key cookies);
Returns an AnnoCPAN::DBI::User object if logged in, or false if not.

=cut

sub check_login {
    my ($self) = @_;
    if ($ENV{TEST_USER}) {
        return AnnoCPAN::DBI::User->retrieve(username => 'test');
    }
    my %cookies = CGI::Cookie->fetch;
    my $login = $cookies{login}  && $cookies{login}->value;
    my $time  = $cookies{'time'} && $cookies{'time'}->value;
    my $key   = $cookies{key}    && $cookies{key}->value;
    my $max_time = (AnnoCPAN::Config->option('cookie_duration') || 1E9) * 86400;
    if ($self->key($login, $time) eq $key and time-$time < $max_time) {
        return AnnoCPAN::DBI::User->retrieve(username => $login);
    }
    0;
}

=item $obj->set_login_cookies($user)

Creates the login cookies for $user (which should be an L<AnnoCPAN::DBI::User> 
object).

=cut

sub set_login_cookies {
    my ($self, $user) = @_;
    $self->user($user);
    my $login = $user->username;
    my $time = time;
    my $key = $self->key($login, $time);
    $self->add_cookie(login  => $login);
    $self->add_cookie(key    => $key);
    $self->add_cookie('time' => $time);
}

=item $obj->user($user)

May be used to set an arbitrary user (to force a login). If no $user is 
provided (and none has been provided before), returns whatever check_login
would return (a user object or false).

=cut

sub user {
    my ($self, $user) = @_;
    if (@_ > 1) {
        $self->{user} = $user;
    } else {
        $self->{user} = $self->check_login unless exists $self->{user};
    }
    $self->{user};
}

=item $obj->key($login, $time)

Returns a login key as a string. Depends on the "secret" configuration option.

=cut

sub key {
    my ($self, $login, $time) = @_;
    my $secret = AnnoCPAN::Config->option('secret');
    md5_hex("$login $time $secret");
}

############# MODES ###############

=back

=head2 Runmode methods

A runmode method has the following characteristics:

1) Its name matches /[A-Z]\w+/

2) Returns a list ($vars, $template, $type). $vars is a hash reference of
variables that should be passed to the template; $template is the name of the
template that should be processed (sans the extension). $type is the MIME type
that should be given in the header. $type is optional; it defaults to
text/html. If $template is false, no headers will be printed and no template
will be processed.

3) Takes an optional parameter $vars. If given, it is expected to be a hash
reference which will be appended to the variables normally returned by the
method. It is used when one mode decides to fall back to another but wants to
add or override some variables of its own.

For example, the Main method could be:

    sub Main {
        my ($self, $vars) = @_;
        $vars ||= {};
        my @recent = AnnoCPAN::DBI::Note->search_recent;
        ({recent => \@recent, %$vars}, "main");
    }

B<Warning>: the documentation below may be slighly incomplete or outdated:

=over

=item $obj->Main($vars)

The front page. Provides the "recent notes" list.

=cut

sub Main {
    my ($self, $vars) = @_;
    $vars ||= {};
    my $page = ($self->param('page') * 1) || 1;
    my $page_size = AnnoCPAN::Config->option('recent_notes') || 25;
    my $start  = ($page - 1) * $page_size;
    my @recent = AnnoCPAN::DBI::Note->recent($start, $page_size);
    my $n      = AnnoCPAN::DBI::Note->count_all;
    my $pages  = ceil($n / $page_size);
    ({
        recent      => \@recent, 
        note_count  => $n, 
        page        => $page,
        pages       => $pages,
        %$vars
    }, "main");
}

=item $obj->Show($vars)

Displays one POD page. Uses the pid CGI parameter.

=cut

sub Show {
    my ($self, $vars) = @_;
    $vars ||= {};
    my $podver = $vars->{podver} || $self->param_obj('PodVer');
    ({ 
        podver   => $podver,
        %$vars,
    }, "show");
}

=item $obj->Show_note

Displays the POD page that is the "main reference" for a given note. Uses the
id CGI parameter.

=cut

sub Show_note {
    my ($self) = @_;
    my $note = $self->param_obj('Note');
    my $podver = $note->section->podver; 
    my $uri = sprintf "/dist/%s/%s", $podver->distver->distver, $podver->path;
    $self->redirect($uri);
    #$self->Show({ podver => $podver });
}

sub Show_notepos {
    my ($self) = @_;
    my $note = $self->param_obj('Note');
    ({ note => $note }, 'show_notepos');
}

sub Update_notepos {
    my ($self) = @_;
    my $note = $self->param_obj('Note');
    my $vars = { note => $note };
    my $user = $self->user;
    if ($user && $user->can_hide($note)) {
        my %to_hide;
        @to_hide{$self->param('hide')} = ();
        my $ref = $self->param('ref');
        for my $notepos ($note->notepos) {
            if ($notepos->id eq $ref) {
                $note->section($notepos->section);
                $note->update;
            }
            if (exists $to_hide{$notepos->id}) {
                $notepos->hide;
            } else {
                $notepos->unhide;
            }
        }
        $vars->{message} = "Note bindings updated";
    } else {
        $vars->{error} = "Edit not authorized";
    }
    ($vars, 'show_notepos');
}

=item $obj->Show_dist($vars)

Displays one distribution (distver) page. Uses the id CGI parameter or 
$vars->{distver}.

=cut

sub Show_dist {
    my ($self, $vars) = @_;
    $vars ||= {};
    my $distver = $vars->{distver} || $self->param_obj('DistVer');
    ({ 
        distver   => $distver,
        %$vars,
    }, "show_dist");
}

=item $obj->Edit

The edit screen (like Show, but includes the edit form).

=cut

sub Edit {
    my ($self, $vars) = @_;
    $vars ||= {};

    my $notepos   = $self->param_obj('NotePos');
    ({ 
        podver   => $notepos->podver,
        note     => $notepos->note,
        %$vars,
        #message => "here ($section, $podver)" . $podver->pod->name,
    }, "edit");
}

sub Raw_note {
    my ($self, $vars) = @_;
    my $notepos = $self->param_obj('NotePos');
    my $text = $notepos->note->note;
    ({ note => $text }, 'note.txt', 'text/plain');
}

sub Create {
    my ($self, $vars) = @_;
    $vars ||= {};

    # get user, see if can edit
    my $user = $self->user
        or return $self->error("Not logged in; can't create note");

    my $section = $self->param_obj('Section');
    my $podver  = $section->podver;
    ({ 
        podver   => $podver,
        section  => $section,
        %$vars,
        #message => "here ($section, $podver)" . $podver->name,
    }, "edit");
}

sub _search_podver {
    my ($self, $vars) = @_;
    $vars ||= {};
    my $pod_name  = $self->param('name');
    return $self->Main unless $pod_name;
    my @pods = AnnoCPAN::DBI::Pod->search(name => $pod_name);
    return $self->error("not found") unless @pods;
    return $self->choose_podver($vars, \@pods);
}

sub _search_dist {
    my ($self, $vars) = @_;
    $vars ||= {};
    my $dist_name  = $self->param('name');
    return $self->Main unless $dist_name;

    my $author     = uc $self->param('author');

    # try distvers first
    my @distvers = AnnoCPAN::DBI::DistVer->search(distver => $dist_name);
    @distvers = grep { $_->pause_id eq $author } @distvers if $author;

    unless (@distvers) {
        my ($dist) = AnnoCPAN::DBI::Dist->search(name => $dist_name);
        @distvers = $dist->distvers if $dist;
        @distvers = grep { $_->pause_id eq $author } @distvers if $author;
        if (@distvers == 1) {
            $self->redirect($self->distver_uri($distvers[0]));
            return;
        }
    }

    return $self->choose_distver($vars, \@distvers) if @distvers;
    return $self->error("not found");
}

sub _search_author {
    my ($self, $vars) = @_;
    $vars ||= {};
    my $pause_id  = $self->param('name');
    return $self->Main unless $pause_id;
    my @distvers = AnnoCPAN::DBI::DistVer->search(pause_id => $pause_id);

    # get only unique dists XXX this should be done in SQL
    my %seen;
    for (@distvers) {
        $seen{$_->dist} = $_->dist;
    }

    return $self->error("not found") unless @distvers;
    ({
        %$vars, dists => [ values %seen ], author => uc $pause_id,
        note_count => AnnoCPAN::DBI::Note->count_by_author($pause_id),
    }, 'show_author');
}


sub _search_both {
    my ($self, $vars) = @_;
    $vars ||= {};

    # find the pods
    my $pod_path  = $self->param('pod');
    return $self->Main unless $pod_path;

    # find the distvers
    my $dist_name  = $self->param('dist');
    return $self->Main unless $dist_name;

    my @podvers = AnnoCPAN::DBI::PodVer->search_distver_pod(
        $dist_name, $pod_path);
    unless (@podvers) {
        @podvers = AnnoCPAN::DBI::PodVer->search_dist_pod(
            $dist_name, $pod_path);
    }
    my $author     = uc $self->param('author');
    @podvers = grep { $_->distver->pause_id eq $author } @podvers if $author;

    return $self->error("not found") unless @podvers;

    if ($self->param('latest')) {
        @podvers = sort { $b->mtime <=> $a->mtime } @podvers;
        splice @podvers, 1;
    }
    if (@podvers == 1) {
        return ({ podver => $podvers[0] }, "show");
    } else {
        return ({ podvers => \@podvers, pod_name => $podvers[0]->pod->name}, 
            "choose");
    }
}


sub Search {
    my ($self, $vars) = @_;
    my $field  = $self->param('field');
    return $self->_search_dist($vars)   if $field eq 'Distribution';
    return $self->_search_author($vars) if $field eq 'Author';
    return $self->_search_podver($vars)    if $field eq 'Module';
    return $self->_search_both($vars);
    die;
}

sub Join_pod {
    my ($self, $vars) = @_;
    $vars ||= {};
    my $pod_name  = $self->param('name');
    return $self->Main unless $pod_name and $self->user->privs >= 10; # XXX magic number
    my @pods = AnnoCPAN::DBI::Pod->search(name => $pod_name);
    return $self->error("not found") unless @pods;
    return ({ %$vars, pods => \@pods, pod_name => $pods[0]->name}, 
            "join_pod");
}

sub Join_pod_save {
    my ($self) = @_;
    return $self->Main unless $self->user->privs >= 10; # XXX magic number
    # XXX add better error checking
    my ($first, @others) = $self->param_obj('Pod');
    $first->join_pods(@others);
    $self->Join_pod({ message => 'Pods joined'});
}

sub Pod_families {
    my ($self) = @_;
    my @pods = AnnoCPAN::DBI::Pod->search_families;
    return ({ pods => \@pods}, "pod_families");
}

sub podver_uri {
    my ($self, $podver) = @_;
    sprintf "%s/~%s/%s/%s", AnnoCPAN::Config->option('root_uri_rel'),
        $podver->distver->pause_id, $podver->distver->distver, $podver->path;
}

sub choose_podver {
    my ($self, $vars, $pods) = @_;
    my @podvers = map { $_->podvers } @$pods;
    if ($self->param('latest')) {
        @podvers = sort { $b->mtime <=> $a->mtime } @podvers;
        splice @podvers, 1;
    }
    if (@podvers == 1) {
        if ($self->param('redirect')) {
            $self->redirect($self->podver_uri($podvers[0]));
            return;
        } else {
            return ({ podver => $podvers[0] }, "show");
        }
    } else {
        return ({ podvers => \@podvers, pod_name => $pods->[0]->name,
            pods => $pods}, 
            "choose");
    }
}

sub distver_uri {
    my ($self, $distver) = @_;
    sprintf "%s/~%s/%s/", AnnoCPAN::Config->option('root_uri_rel'),
        $distver->pause_id, $distver->distver;
}

sub choose_distver {
    my ($self, $vars, $distvers) = @_;
    if ($self->param('latest')) {
        $distvers = [ sort { $b->mtime <=> $a->mtime } @$distvers ];
        splice @$distvers, 1;
    }
    if (@$distvers == 1) {
        return ({ distver => @$distvers }, "show_dist");
    } else {
        my $dist = $distvers->[0]->dist;
        return ({ distvers => \@$distvers, dist => $dist}, "choose_dist");
    }
}


sub error {
    my ($self, $message) = @_;
    $self->Main({ error => $message });
}

sub _message {
    my ($self, $message, $vars) = @_;
    ({ %{$vars||{}}, message => $message }, "message");
}

sub _error {
    my ($self, $message, $vars) = @_;
    ({ %{$vars||{}}, error => $message }, "error");
}

sub _log {
    my ($self, $message) = @_;
    push @{$self->{log}}, $message;
}

=item $obj->About

The "about" page. Uses the about.pod file.

=cut

sub About {
    my $parser = AnnoCPAN::PodToHtml->new(annocpan_print => 1);
    my $html;
    my $fh = IO::String->new($html);
    $parser->parse_from_file('about.pod', $fh);
    ({ content => $html }, 'about');
}

sub Faq { ({}, 'faq') }
sub News { ({}, 'news') }
sub Motd { ({}, 'motd') }
sub Note_help { ({}, 'note_help') }
sub Policy { ({}, 'policy') }
sub Contact { ({}, 'contact') }

sub Show_user {
    my ($self) = @_;
    my $u = $self->param_obj('User', 'username');
    ({ a_user => $u }, 'show_user');
}

sub Move {
    my ($self) = @_;
    my $notepos = $self->param_obj('NotePos');
    shift->Show({ podver => $notepos->podver });
}

sub Do_move {
    my ($self) = @_;
    return $self->_do_move if $self->param('fast');
    my ($vars) = $self->_do_move;
    return $self->Main($vars) if $vars->{error};
    $self->Show($vars);
}

sub _do_move {
    my ($self) = @_;

    my $notepos = $self->param_obj('NotePos');
    my $section = $self->param_obj('Section');

    # get user, see if can edit
    my $user = $self->user
        or return $self->_error("Not logged in; can't move");

    $user->can_move($notepos->note)
        or return $self->_error("Move not authorized");

    $section->podver eq $notepos->section->podver
        or return $self->_error("Move not within the same document");

    my $podver = $section->podver;

    $notepos->section($section);
    $notepos->status(AnnoCPAN::DBI::Note::MOVED);
    $notepos->score(AnnoCPAN::DBI::Note::SCALE);
    $notepos->update;

    $podver->flush_cache;

    $self->_message("note moved", { podver => $podver });
}


sub Hide {
    my ($self) = @_;
    return $self->_hide if $self->param('fast');
    my ($vars) = $self->_hide;
    return $self->Main($vars) if $vars->{error};
    $self->Show($vars);
}

sub _hide {
    my ($self) = @_;
    my $notepos_id = $self->param('notepos');

    my $notepos = $self->param_obj('NotePos');

    my $note    = $notepos->note;
    my $section = $notepos->section;
    
    # get user, see if can edit
    my $user = $self->user
        or return $self->_error("not logged in; can't move");
    $user->can_hide($note)
        or return $self->_error("move not authorized");

    my $podver = $section->podver;
    $podver->flush_cache;

    $notepos->status(AnnoCPAN::DBI::Note::HIDDEN);
    $notepos->update;

    $self->_message("note hidden", { podver => $notepos->podver });
}

=item $obj->Save

Save a new note (comes from the Edit mode). Uses the pid, pos, id, and note CGI
parameters.

=cut

sub Save {
    my ($self) = @_;
    return $self->_save if $self->param('fast');
    my ($vars) = $self->_save;
    return $self->Main($vars) if $vars->{error};
    $self->Show($vars);
}

# to save new note, need section and note text
# to save edited note, need notepos and note text
sub _save {
    my ($self) = @_;
    my $note_text    = $self->param('note_text');

    my ($note, $podver);

    # get user, see if can edit
    my $user = $self->user
        or return $self->_error("Not logged in; can't save note");

    if ($self->param('notepos')) { # edit existing note
        my $notepos = $self->param_obj('NotePos');
        $podver = $notepos->podver;
        $note   = $notepos->note;

        $user->can_edit($note)
            or return $self->_error("Edit not authorized");
        $note->note($note_text);
        $note->ip($ENV{REMOTE_ADDR});
        #$note->time(time);
        $note->update;
        $note->remove_from_object_index;

    } else { # create new note
        my $section = $self->param_obj('Section');
        $podver  = $section->podver;
        $note = AnnoCPAN::DBI::Note->create({
            pod         => $podver->pod, 
            min_ver     => '',
            max_ver     => '',
            note        => $note_text, 
            ip          => $ENV{REMOTE_ADDR},
            time        => time,
            user        => $self->user,
            section     => $section,
        }) or return $self->_error("Duplicate note?");
    }
    ({ note => $note, podver => $podver, notepos => $note->ref_notepos }, 
        'note');
}

=item $obj->New_user

"Create new user" screen.

=cut

sub New_user {
    ({}, "new_user");
}

=item $obj->Create_user

Coming from the New_user form, create a new account. Uses the login, passwd,
passwd2, and email CGI parameters. Checks that the login and password are not
blank, that the passwords match, and that the login is not already taken.

=cut

sub Create_user {
    my ($self) = @_;
    my $login   = $self->param('login');
    my $passwd  = $self->param('passwd');
    my $passwd2 = $self->param('passwd2');
    my $email   = $self->param('email');
    my %vars = (login => $login, email => $email);

    return ({%vars, error => "missing password"}, "new_user")
        unless (length $passwd);

    return ({%vars, error => "missing login"}, "new_user")
        unless (length $login);

    $login =~ s/^\s+//;
    $login =~ s/\s+$//;

    return ({%vars, error => "invalid login"}, "new_user")
        unless ($login =~ /^\w+$/);

    if (AnnoCPAN::DBI::User->retrieve(username => $login)) {
        return ({%vars, error => 'login already taken'}, "new_user");
    }

    if ($passwd ne $passwd2) {
        return ({%vars, error => "passwords don't match"}, "new_user");
    }

    my $user = AnnoCPAN::DBI::User->create({
        username => $login,
        password => crypt($passwd, $login),
        email    => $email,
        member_since => time,
        privs    => 1,
    });
    $self->set_login_cookies($user);
    $self->Main({%vars, message => "account created"});
}

=item $sub->Login

Log in; comes from the login form on login_form.html. Uses the login and
passwd CGI parameters.

=cut

sub Login {
    my ($self) = @_;
    my $passwd  = $self->param('passwd');

    my $user = eval { $self->param_obj('User', 'username') };
    unless ($user and crypt($passwd, $user->password) eq $user->password) {
        return $self->Main({error => 'invalid login/password'});
    }
    $self->set_login_cookies($user);
    my $from = $self->param('from');
    $self->redirect($from =~ /logout/ ? '/' : $from);
    return;
    #$self->Main({message => "welcome, you have logged in!"});
}

=item $obj->Logout

Log out. Clears the authentication key.

=cut

sub Logout {
    my ($self) = @_;
    $self->delete_cookie('key');
    $self->user(undef);
    $self->redirect($self->param('from'));
    return;
    #$self->Main({message => "You have logged out"});
}

sub Prefs {
    my ($self) = @_;
    return $self->error("Can't edit prefs without logging in first!")
        unless $self->user;
    ({}, 'prefs');
}

sub Save_prefs {
    my ($self) = @_;
    # XXX untaint
    my $user = $self->user;
    return $self->error("Can't edit prefs without logging in first!")
        unless $user;
    AnnoCPAN::DBI::Prefs->search(user => $user)->delete_all;
    for my $name (@{AnnoCPAN::Config->option('prefs')}) {
        AnnoCPAN::DBI::Prefs->create({user => $user, name => $name, 
            value => $self->param($name) || '' });
    }
    ({ message => 'Preferences saved'}, 'prefs');
}


sub Delete {
    my ($self) = @_;
    return $self->_delete if $self->param('fast');
    my ($vars) = $self->_delete;
    return $self->Main($vars) if $vars->{error};
    $self->Show($vars);
}

# global delete
sub _delete {
    my ($self) = @_;

    my $notepos = $self->param_obj('NotePos');
    my $note    = $notepos->note;
    my $podver  = $notepos->podver;

    # get user, see if can delete
    my $user = $self->user
        or return $self->_error("not logged in; can't delete");
    $user->can_delete($note)
        or return $self->_error("deletion not authorized");

    $note->delete;

    $self->_message("note deleted", { podver => $podver });
}


sub Main_rss {
    my ($self) = @_;

    my ($vars) = $self->Main;

    my $link = AnnoCPAN::Config->option('root_uri_abs');
    my $rss  = AnnoCPAN::Feed->note_rss(notes => $vars->{recent}, 
        link => $link, title => 'AnnoCPAN Recent Notes');

    ({ %$vars, rss => $rss }, 'rss', 'text/xml');
}


sub Author_recent {
    my ($self, $vars) = @_;
    $vars ||= {};
    my $pause_id  = $self->param('pause_id');
    my @recent = AnnoCPAN::DBI::Note->search_recent_by_author($pause_id);
    ({notes => \@recent, author => uc $pause_id, %$vars }, "show_author_recent");
}

sub Author_rss {
    my ($self, $vars) = @_;
    $vars ||= {};

    my $pause_id  = $self->param('name');
    return $self->Main unless $pause_id;
    my @pods = AnnoCPAN::DBI::Pod->search_by_author($pause_id);
    my @notes = map { $_->notes } @pods;

    my $link = AnnoCPAN::Config->option('root_uri_abs') . "/~$pause_id";
    my $rss  = AnnoCPAN::Feed->note_rss(notes => \@notes, link => $link,
        title => "AnnoCPAN Notes for PAUSE ID '$pause_id'");

    ({ %$vars, rss => $rss }, 'rss', 'text/xml');
}

sub Note_dump {
    my @notes = AnnoCPAN::DBI::Note->retrieve_all;
    ({ notes => \@notes}, "note_dump.xml", "text/xml");
}

sub Podver_note_count {
    my @podvers = AnnoCPAN::DBI::PodVer->search_note_count_all;
    for my $podver (@podvers) {
        ($podver->{path_from_author_dir} = $podver->{dist_path}) 
            =~ s|^authors/id/./../[^/]*/||; 
    }
    ({ podvers => \@podvers}, "podver_note_count.txt", "text/plain");
}

sub Flush {
    my ($self) = @_;
    if ($self->user && $self->user->privs >= 10) {
        AnnoCPAN::DBI::PodVer->flush_cache;
        $self->Main({ message => 'Cache flushed'});
    } else {
        $self->error('Not authorized');
    }
}

sub my_html {
    my ($self, $podver) = @_;
    my $html = '';

    AnnoCPAN::DBI::Note->clear_object_index;

    if (AnnoCPAN::Config->option('cache_html')
        and $self->mode !~ /(Edit|Move|Create)/
    ) {
        $html = $podver->html;
        return $html if $html;
    }
    my $tt = Template->new(
        INCLUDE_PATH => AnnoCPAN::Config->option('template_path'),
        PRE_PROCESS => 'util.tt',
    );
    my $vars = {
        %{ $self->default_vars },
        podver => $podver,
    };
    $tt->process('pod.html', $vars, \$html) or print $@;
    if (AnnoCPAN::Config->option('cache_html')) {
        $podver->html($html);
        $podver->update;
    }
    return $html;
}

sub myuri_filter {
   my $text = shift;
   our $URI_ESCAPES ||= {
       map { ( chr($_), sprintf("%%%02X", $_) ) } (0..255),
   };

   $text =~ s/([^\/?:@+\$,A-Za-z0-9\-_.!~*'()])/$URI_ESCAPES->{$1}/g;
   $text;
}

=back

=head1 SEE ALSO

L<AnnoCPAN::DBI>, L<AnnoCPAN::Config>

=head1 AUTHOR

Ivan Tubert-Brohman E<lt>itub@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (c) 2005 Ivan Tubert-Brohman. All rights reserved. This program is
free software; you can redistribute it and/or modify it under the same terms as
Perl itself.

=cut

1;

