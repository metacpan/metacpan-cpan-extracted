package AnnoCPAN::DBI;

$VERSION = '0.22';

use strict;
use warnings;
use base 'Class::DBI';
use AnnoCPAN::Config;

# override to make fatal errors more informative
sub _croak {
    my ($self, $msg) = @_;
    Carp::confess($msg || $self);
}

=head1 NAME

AnnoCPAN::DBI - AnnoCPAN model class (database access module)

=head1 SYNOPSIS

    use AnnoCPAN::DBI;
    my @pods = AnnoCPAN::DBI::Pod->search(name => 'My::Module');
    # etc...

=head1 DESCRIPTION

This is a collection of classes based on L<Class::DBI>, used for representing
the AnnoCPAN data. B<Warning>: Some of the documentation here is incomplete.

=head1 CLASSES

=head2 AnnoCPAN::DBI

The base class; based on Class::DBI.

=cut

our $dbh;

sub reset_dbh {
    $dbh = undef;
}

sub db_Main {
    my ($self) = @_;
    $dbh ||= DBI->connect(
        AnnoCPAN::Config->option('dsn'),
        AnnoCPAN::Config->option('db_user'),
        AnnoCPAN::Config->option('db_passwd'),
        { $self->_default_attributes },
    );
    #no warnings 'uninitialized';
    #warn sprintf "db_Main; dbh=($dbh);, ping=(%s); mysql_auto_reconnect=(%s,%s,%s)\n", $dbh->ping, 
        #$dbh->{mysql_auto_reconnect}, $dbh->{mysql_dbd_stats}{auto_reconnects_ok}, $dbh->{mysql_dbd_stats}{auto_reconnects_failed};
    return $dbh;
}

=head2 AnnoCPAN::DBI::Dist

Represents a distribution (regardless of version); has the following columns:

    id
    name
    rating
    review_count
    creation_time

=cut

package AnnoCPAN::DBI::Dist;
use base 'AnnoCPAN::DBI';
__PACKAGE__->table('dist');
__PACKAGE__->columns(Essential => qw(id name rating review_count creation_time));

sub stars {
    my ($self) = @_;
    return int($self->rating / 20 + 0.5);
}

sub rating5 { shift->rating / 20 }

sub latest_distver {
    my ($self) = @_;
    return ($self->distvers)[-1];
}

sub garbage_collect {
    my ($class) = @_;
    my $it = $class->retrieve_all;
    while (my $dist = $it->next) {
        if ($dist->distvers->count == 0) {
            $dist->delete;
        }
    }
}

sub count_notes {
    my ($self) = @_;
    return $self->sql_count_notes->select_val($self->id);
}

__PACKAGE__->set_sql(count_notes => 'SELECT count(*) 
    FROM dist d, pod_dist pd, pod p, note n 
    WHERE d.id=? AND pd.dist=d.id AND pd.pod=p.id AND n.pod=p.id'
);

sub latest_note_date {
    my ($self) = @_;
    return $self->sql_latest_note_date->select_val($self->id);
}

__PACKAGE__->set_sql(latest_note_date => 'SELECT n.time
    FROM dist d, pod_dist pd, pod p, note n 
    WHERE d.id=? AND pd.dist=d.id AND pd.pod=p.id AND n.pod=p.id
    ORDER BY n.time DESC LIMIT 1'
);

sub recent {
    my ($self, $start, $count) = @_;
    $start ||= 0;
    $count ||= 25;
    return $self->retrieve_from_sql(
        "1 ORDER BY creation_time DESC LIMIT $start, $count");

}

=head2 AnnoCPAN::DBI::Pod

Represents a document (typically a module, but it may be some other .pod file),
regardless of version. Columns:

    id
    name

=cut

package AnnoCPAN::DBI::Pod;
use base 'AnnoCPAN::DBI';
__PACKAGE__->table('pod');
__PACKAGE__->columns(Essential => qw(id name));

sub garbage_collect {
    my ($class) = @_;
    my $it = $class->retrieve_all;
    while (my $pod = $it->next) {
        if ($pod->podvers->count == 0) {
            $pod->delete;
        }
    }
}

sub path {
    my (@pv) = shift->podvers;
    return unless @pv;
    $pv[0]->path; # take the first podver's path as representative
}

__PACKAGE__->set_sql(
    pod_dist => "SELECT pod.id id, pod.name name FROM dist, pod, pod_dist
                 WHERE pod_dist.pod=pod.id AND pod_dist.dist=dist.id
                 AND pod.name=? AND dist.id=?");

__PACKAGE__->set_sql(
    families => 'SELECT pod id, count(*) c FROM pod_dist GROUP BY id
        HAVING c>1');

__PACKAGE__->set_sql(
    by_author => "SELECT DISTINCT p.id, p.name 
        FROM pod p, distver dv, podver pv 
        WHERE dv.pause_id=? AND pv.distver=dv.id AND pv.pod=p.id");

sub count_notes {
    my ($self) = @_;
    return $self->sql_count_notes->select_val($self->id);
}

__PACKAGE__->set_sql(count_notes => 'SELECT count(*) 
    FROM note n 
    WHERE pod=?'
);

sub latest_note_date {
    my ($self) = @_;
    return $self->sql_latest_note_date->select_val($self->id);
}

__PACKAGE__->set_sql(latest_note_date => 'SELECT time
    FROM note n 
    WHERE pod=?
    ORDER BY time DESC
    LIMIT 1'
);

sub join_pods {
    my ($self, @others) = @_;
    my (@notes)   = map { $_->notes }   (@others); 
    my (@podvers) = map { $_->podvers } (@others); 
    my (@pod_dists) = map { $_->pod_dists } (@others); 

    # steal the notes and podvers
    for my $child (@notes, @podvers, @pod_dists) {
        $child->pod($self);
        $child->update;
    }

    # union of all the notes/podvers
    push @notes,   $self->notes;
    push @podvers, $self->podvers;

    # boldly translate the notes to where they have never been before
    for my $note (@notes) {
        for my $podver (@podvers) {
            my ($np) = AnnoCPAN::DBI::NotePos->search_podver_note(
                $podver, $note);
            unless ($np) {
                $note->guess_section($podver);
            }
        }
    }

    # delete the other pods
    $_->delete for @others;
    $self;
}

=head2 AnnoCPAN::DBI::PodDist

Links a pod with a dist (its a many-to-many relationship).
Columns:

    id 
    dist 
    pod

=cut


package AnnoCPAN::DBI::PodDist;
use base 'AnnoCPAN::DBI';
__PACKAGE__->table('pod_dist');
__PACKAGE__->columns(Essential => qw(id dist pod));
__PACKAGE__->has_a(dist => 'AnnoCPAN::DBI::Dist');
__PACKAGE__->has_a(pod => 'AnnoCPAN::DBI::Pod');


sub notes { return shift->pod->notes }
sub podvers { return shift->pod->podvers }

=head2 AnnoCPAN::DBI::DistVer

Represents a specific version of a distribution
Columns:

    id
    dist 
    version 
    path 
    pause_id 
    distver 
    mtime

=cut

package AnnoCPAN::DBI::DistVer;
use base 'AnnoCPAN::DBI';
__PACKAGE__->table('distver');
__PACKAGE__->columns(Essential => qw(id dist version path pause_id 
    distver mtime maturity));
__PACKAGE__->has_a(dist => 'AnnoCPAN::DBI::Dist');

sub translate_notes {
    my ($self) = @_;
    for my $podver ($self->podvers) {
        for my $note ($podver->pod->notes) {
            $note->guess_section($podver);
        }
    }
}

sub count_visible_notes {
    my ($self) = @_;
    return $self->sql_count_visible_notes->select_val($self->id);
}

__PACKAGE__->set_sql(count_visible_notes => 'SELECT count(*) 
    FROM distver dv, podver pv, section s, notepos np
    WHERE dv.id=?  AND pv.distver=dv.id AND s.podver=pv.id AND np.section=s.id
    AND np.status >= 0'
);

sub latest_visible_note_date {
    my ($self) = @_;
    return $self->sql_latest_visible_note_date->select_val($self->id);
}

__PACKAGE__->set_sql(latest_visible_note_date => 'SELECT n.time
    FROM distver dv, podver pv, section s, notepos np, note n
    WHERE dv.id=?  
    AND pv.distver=dv.id AND s.podver=pv.id AND np.section=s.id AND np.note=n.id
    AND np.status >= 0 
    ORDER BY n.time DESC LIMIT 1'
);

=head2 AnnoCPAN::DBI::PodVer

Represents a specific version of a document (a "pod").
Columns:

    id
    pod
    distver
    path
    description
    html

=cut

package AnnoCPAN::DBI::PodVer;
use base 'AnnoCPAN::DBI';
__PACKAGE__->table('podver');
__PACKAGE__->columns(Essential => qw(id pod distver path description signature));
__PACKAGE__->columns(Others => qw(html));
__PACKAGE__->has_a(pod => 'AnnoCPAN::DBI::Pod');
__PACKAGE__->has_a(distver => 'AnnoCPAN::DBI::DistVer');

sub mtime { shift->distver->mtime }
sub name  { shift->pod->name }
sub raw_sections {
    my ($self) = @_;
    my $pv = $self->id;
    #my $sth = AnnoCPAN::DBI::Section->sql_Retrieve("podver=$pv order by pos");
    my $sth = AnnoCPAN::DBI::Section->sql_Retrieve("podver=$pv");
    $sth->execute;
    $sth->fetchall_hash;
}

sub flush_cache {
    my ($self) = @_;
    if (ref $self) {
        $self->html('');
        $self->update;
    } else {
        my $sth = $self->sql_flush_cache;
        $sth->execute;
    }
}

sub visible_notepos {
    my ($self) = @_;
    my @ret = grep { $_->is_visible } $self->notepos;
    \@ret;
}

sub notepos {
    my ($self) = @_;
    AnnoCPAN::DBI::NotePos->search_by_podver($self->id);
}

sub count_visible_notes {
    my ($self) = @_;
    return $self->sql_count_visible_notes->select_val($self->id);
}

__PACKAGE__->set_sql(count_visible_notes => 'SELECT count(*) 
        FROM notepos np, section s, podver pv
        WHERE s.podver = pv.id AND np.section = s.id
        AND np.status>=0 AND pv.id=?'
);

__PACKAGE__->set_sql( flush_cache => 'UPDATE __TABLE__ SET html=null');

__PACKAGE__->set_sql(
    distver_pod => 'SELECT podver.id FROM podver, distver
        WHERE podver.distver=distver.id AND distver.distver=?
        AND podver.path=?');

__PACKAGE__->set_sql(
    dist_pod => 'SELECT podver.id FROM podver, distver, dist
        WHERE podver.distver=distver.id AND distver.dist=dist.id
        AND dist.name=? AND podver.path=?');

__PACKAGE__->set_sql(note_count_all => '
    SELECT dv.pause_id, dv.path dist_path, pv.path pod_path, 
        count(*) note_count
    FROM distver dv, podver pv, section s, notepos np
    WHERE pv.distver=dv.id AND s.podver=pv.id AND np.section=s.id
    AND np.status >= 0 GROUP BY dist_path, pod_path 
    ORDER BY dist_path, pod_path'
);

=head2 AnnoCPAN::DBI::Section

Represents a paragraph in a POD document. Columns:

    id
    podver
    pos
    content
    type 

=cut

package AnnoCPAN::DBI::Section;
use base 'AnnoCPAN::DBI';
use AnnoCPAN::PodToHtml;
use AnnoCPAN::PodParser ':all';

__PACKAGE__->table('section');
__PACKAGE__->columns(Essential => qw(id podver pos content type));
__PACKAGE__->has_a(podver => 'AnnoCPAN::DBI::PodVer');
__PACKAGE__->add_trigger(before_delete  => \&before_delete);


my %methods = (
    VERBATIM,  'verbatim',
    TEXTBLOCK, 'textblock',
    COMMAND,   'command',
);


sub html {
    my ($self) = @_;
    $self->{parser} ||= AnnoCPAN::PodToHtml->new;
    my $method = $methods{$self->type};
    my @args = $self->content;
    if ($method eq 'command') {
        # split into command and content
        @args = $args[0] =~ /==?(\S+)\s+(.*)/s;
    }
    my $html = $self->{parser}->$method(@args);
}


sub before_delete {
    my ($self) = @_;
    # make sure no notes use us as their reference section...
    for my $note ($self->original_notes) {
        my $max_sim = 0;
        my $best_sect;
        for my $notepos ($note->notepos) {
            if ($notepos->section->id != $self->id 
                and $notepos->score > $max_sim) 
            {
                $max_sim   = $notepos->score;
                $best_sect = $notepos->section;
            }
        }
        $note->section($best_sect);
        $note->update;
    }
}

=head2 AnnoCPAN::DBI::User

Represents an AnnoCPAN user. Columns:

    id
    username
    password
    name
    email
    profile 
    reputation
    member_since
    last_visit
    privs

Note that some of these columns are unused, but they exist for historical
reasons.

Other Methods:

=over

=cut

package AnnoCPAN::DBI::User;
use base 'AnnoCPAN::DBI';
__PACKAGE__->table('user');
__PACKAGE__->columns(Essential => qw(id username password name email profile 
    reputation member_since last_visit privs));

=item $user->can_delete($note)

Return true if the user has the authority to delete $note (an
AnnoCPAN::DBI::Note object).

=cut

sub can_delete {
    my ($user, $note) = @_;
    ($user->privs > 1 or $user == $note->user);
}

=item $user->can_edit($note)

Return true if the user has the authority to edit $note (an
AnnoCPAN::DBI::Note object).

=cut

sub can_edit { shift->can_delete(@_) }

=item $user->can_move($note)

Return true if the user has the authority to move $note (an
AnnoCPAN::DBI::Note object).

=back

=cut

sub can_move { shift->can_delete(@_) }
sub can_hide { shift->can_delete(@_) }

package AnnoCPAN::DBI::Prefs;
use base 'AnnoCPAN::DBI';
__PACKAGE__->table('prefs');
__PACKAGE__->columns(Essential => qw(id user name value));
__PACKAGE__->has_a(user => 'AnnoCPAN::DBI::User');

package AnnoCPAN::DBI::Vote;
use base 'AnnoCPAN::DBI';
__PACKAGE__->table('vote');
__PACKAGE__->columns(Essential => qw(id note user value));

=head2 AnnoCPAN::DBI::Note

Represents a note. Columns:

    id
    pod
    min_ver
    max_ver
    note
    ip
    time
    score
    user
    section

Note that some of these columns are unused, but they exist for historical
reasons.

=cut

package AnnoCPAN::DBI::Note;
use base 'AnnoCPAN::DBI';
use String::Similarity 'similarity';
use AnnoCPAN::PodParser ':all';
use POSIX qw(nice);
use constant {
    ORIGINAL    => 1,
    MOVED       => 2,
    CALCULATED  => 0,
    HIDDEN      => -1,
    SCALE       => 1000,
};

my $recent_notes = AnnoCPAN::Config->option('recent_notes') || 25;

__PACKAGE__->table('note');
__PACKAGE__->columns(
    Essential => qw(id pod min_ver max_ver note ip time score user section));

sub recent {
    my ($self, $start, $count) = @_;
    $start ||= 0;
    $count ||= $recent_notes;
    return $self->retrieve_from_sql(
        "1 ORDER BY time DESC LIMIT $start, $count");

}

__PACKAGE__->set_sql(recent_by_author =>  "SELECT DISTINCT n.id
    FROM note n, distver dv, podver pv, pod p
    WHERE dv.pause_id=? AND pv.distver=dv.id AND pv.pod=p.id
    AND n.pod=p.id
    ORDER BY n.time DESC LIMIT $recent_notes"
);

sub count_by_author {
    my ($self, $pause_id) = @_;
    return $self->sql_count_by_author->select_val($pause_id);
}

__PACKAGE__->set_sql(count_by_author =>  "SELECT count(distinct n.id)
    FROM note n, distver dv, podver pv, pod p
    WHERE dv.pause_id=? AND pv.distver=dv.id AND pv.pod=p.id
    AND n.pod=p.id"
);

__PACKAGE__->has_a(pod      => 'AnnoCPAN::DBI::Pod');
__PACKAGE__->has_a(user     => 'AnnoCPAN::DBI::User');
__PACKAGE__->has_a(section  => 'AnnoCPAN::DBI::Section'); 

sub create { # Class::DBI
    my ($self, $data) = @_;
    my $section = $data->{section};
    my $pos     = $section->pos;

    my $podver  = $section->podver;
    # delete cached html
    $podver->flush_cache;

    # make sure the note is not there already, to avoid duplicates
    # if people reload, submit twice, or are otherwise repetitive
    my @notes   = $self->search(
        note    => $data->{note},
        ip      => $data->{ip},
        pod     => $data->{pod},
        section => $data->{section},
    );
    return if @notes;

    # create the note
    my $note    = $self->SUPER::create($data);
    AnnoCPAN::DBI::NotePos->create({ 
        note => $note, section => $section, 
        score => SCALE, status => ORIGINAL });

    $self->reset_dbh;
    unless (fork) {
        # child process
        nice(+19);
        close STDIN;
        close STDOUT;
        close STDERR;
        # Now "translate" the note to other versions
        my $pod = $data->{pod};
        for my $pv ($pod->podvers) {
            if ($pv->id != $podver->id) { # note was not added here
                $note->guess_section($pv);
            }
        }
        exit;
    }
    return $note; # only parent returns
}

sub simple_create { shift->SUPER::create(@_) }
sub simple_update { shift->SUPER::update(@_) }

sub guess_section {
    my ($self, $podver) = @_;

    # delete cached html
    $podver->flush_cache;

    # XXX version check might go here
    my $ref_section = $self->section or return;
    my $orig_cont = $ref_section->content;

    my $max_sim   = AnnoCPAN::Config->option('min_similarity') || 0;
    my $best_sect;
    for my $sect ($podver->raw_sections) {
        next if $sect->{type} & COMMAND; # can't attach notes to commands
        my $sim = similarity($orig_cont, $sect->{content}, $max_sim);
        if ($sim > $max_sim) {
            $max_sim   = $sim;
            $best_sect = $sect;
        }
    }
    if ($best_sect) {
        AnnoCPAN::DBI::NotePos->create({ note => $self, 
            section => $best_sect->{id}, score => int($max_sim * SCALE),
            status => CALCULATED });
        return 1;
    }
    return;
}

sub update {
    my $self = shift;
    for my $pv ($self->pod->podvers) {
        $pv->flush_cache;
    }
    $self->SUPER::update(@_);
}

sub delete {
    my $self = shift;
    for my $pv ($self->pod->podvers) {
        $pv->flush_cache;
    }
    $self->SUPER::delete(@_);
}

sub ref_notepos {
    my ($self) = @_;
    AnnoCPAN::DBI::NotePos->retrieve(note => $self, section => $self->section);
}

sub html {
    my ($self) = @_;

    my $p = AnnoCPAN::PodToHtml->new(annocpan_simple => 1);
    my $pod = $self->note;

    # clean up and split the pod
    $pod =~ s/\r\n?/\n/g;       # normalize newlines
    $pod =~ s/^\s*\n//;         # get rid of leading blank lines
    my @paragraphs = split /\n\s*\n/, $pod;

    my $errors = '';
    $p->errorsub(sub {
        my $err = shift;
        $err =~ s/at line.*//;
        for ($err) {
            s/&/&amp;/g;
            s/</&lt;/g;
            s/>/&gt;/g;
        }
        $errors .= qq{<p class="error">$err</p>\n};
    });

    my $ret = '';
    for my $para (@paragraphs) {
        my $method = $para =~ /^ / ? 'verbatim' : 'textblock';
        $ret .= $p->$method($para);
    }
    return $errors . $ret;
}

package AnnoCPAN::DBI::NotePos;
use base 'AnnoCPAN::DBI';
__PACKAGE__->table('notepos');
__PACKAGE__->columns(Essential => qw(id note section score status));
__PACKAGE__->has_a(note     => 'AnnoCPAN::DBI::Note');
__PACKAGE__->has_a(section  => 'AnnoCPAN::DBI::Section');

sub is_visible {
    my ($self) = @_;
    ($self->status != AnnoCPAN::DBI::Note::HIDDEN);
}

sub hide {
    my ($self) = @_;
    return unless $self->is_visible;
    $self->status(AnnoCPAN::DBI::Note::HIDDEN);
    $self->update;
    $self->podver->html('');
    $self->podver->update;
}

sub unhide {
    my ($self) = @_;
    return if $self->is_visible;
    $self->status(AnnoCPAN::DBI::Note::MOVED);
    $self->update;
    $self->podver->html('');
    $self->podver->update;
}

sub score_class {
    my ($self) = @_;
    my $score = $self->score;
    "sim_" . int($score / 100) * 10;
}

sub time   { shift->note->time }
sub distver_mtime   { shift->section->podver->mtime }
sub podver { shift->section->podver }

__PACKAGE__->set_sql(
    podver_note => "SELECT notepos.id FROM notepos, section 
        WHERE notepos.section=section.id AND section.podver=? 
        AND notepos.note=?");

__PACKAGE__->set_sql(
    by_podver => 'SELECT np.id FROM notepos np, section s, podver pv, note n
        WHERE s.podver = pv.id AND np.section = s.id AND np.note = n.id
        AND pv.id=?
        ORDER BY np.section, n.time');

package AnnoCPAN::DBI::Author;
use base 'AnnoCPAN::DBI';
__PACKAGE__->table('author');
__PACKAGE__->columns(Essential => qw(id pause_id name email url));

# ONE TO MANY

AnnoCPAN::DBI::Dist->has_many(distvers => 'AnnoCPAN::DBI::DistVer',
    { order_by => 'mtime' });
AnnoCPAN::DBI::Pod->has_many(podvers => 'AnnoCPAN::DBI::PodVer');
AnnoCPAN::DBI::Pod->has_many(notes => 'AnnoCPAN::DBI::Note');
AnnoCPAN::DBI::Pod->has_many(pod_dists => 'AnnoCPAN::DBI::PodDist');
AnnoCPAN::DBI::PodVer->has_many(sections => 'AnnoCPAN::DBI::Section',
    { order_by => 'pos' } );
AnnoCPAN::DBI::DistVer->has_many(podvers => 'AnnoCPAN::DBI::PodVer');
AnnoCPAN::DBI::User->has_many(prefs => 'AnnoCPAN::DBI::Prefs');
AnnoCPAN::DBI::User->has_many(
    notes => 'AnnoCPAN::DBI::Note', { order_by => 'time DESC' });
AnnoCPAN::DBI::Section->has_many(notepos => 'AnnoCPAN::DBI::NotePos');
AnnoCPAN::DBI::Section->has_many(original_notes => 'AnnoCPAN::DBI::Note');
AnnoCPAN::DBI::Note->has_many(notepos => 'AnnoCPAN::DBI::NotePos');

# MANY TO MANY

AnnoCPAN::DBI::Section->has_many(
    notes => ['AnnoCPAN::DBI::NotePos' => 'note']);
AnnoCPAN::DBI::Note->has_many(
    sections => ['AnnoCPAN::DBI::NotePos' => 'section']);
AnnoCPAN::DBI::Pod->has_many(
    dists => ['AnnoCPAN::DBI::PodDist' => 'dist']);
AnnoCPAN::DBI::Dist->has_many(
    pods => ['AnnoCPAN::DBI::PodDist' => 'pod']);


=head1 SEE ALSO

L<AnnoCPAN::Control>, L<AnnoCPAN::Config>

=head1 AUTHOR

Ivan Tubert-Brohman E<lt>itub@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (c) 2005 Ivan Tubert-Brohman. All rights reserved. This program is
free software; you can redistribute it and/or modify it under the same terms as
Perl itself.

=cut

1;

