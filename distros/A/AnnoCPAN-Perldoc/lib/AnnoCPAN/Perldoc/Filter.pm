package AnnoCPAN::Perldoc::Filter;

$VERSION = '0.10';

use strict;
use warnings;
use IO::String;
use DBI;
use Digest::MD5 'md5_hex';

sub new {
    bless {}, shift;
}

sub filter {
    my ($self, $pod) = @_;
    my $notes  = $self->find_notes($pod);
    return $pod unless @$notes;

    my $filtered_pod;
    my $fh_in  = IO::String->new($pod);
    my $fh_out = IO::String->new($filtered_pod);
    my $parser = AnnoCPAN::Perldoc::Parser->new(ac_notes => $notes);

    $parser->parse_from_filehandle($fh_in, $fh_out);

    return $filtered_pod;
}

sub find_notes {
    my ($self, $pod) = @_;
    my $signature = md5_hex($pod);
    my $db_file;
    DIR: for my $dir (@ENV{qw(HOME USERPROFILE ALLUSERSPROFILE)}, 
        '/var/annocpan', '.'
    ) {
        for my $file ('annopod.db', '.annopod.db') {
            no warnings 'uninitialized';
            $db_file = "$dir/$file", last DIR if -e "$dir/$file";
        }
    }
    unless ($db_file) {
        warn "Couldn't find any AnnoCPAN database\n";
        return [];
    }
    my $dbh = DBI->connect("dbi:SQLite:dbname=$db_file")
        or die "Couldn't connect to database: $@\n";
    my $notes = $dbh->selectall_arrayref(
        'SELECT DISTINCT n.note note, n.user user, n.time time, np.pos pos
        FROM note n, notepos np, podver pv
        WHERE np.note=n.id AND np.podver=pv.id AND pv.signature=?
        ORDER by pos, time',
        {Slice => {}}, 
        $signature,
    ) or die "$@";
    $dbh->disconnect;
    return $notes;
}


package AnnoCPAN::Perldoc::Parser;

use base 'Pod::Parser';

sub verbatim {
    my ($self, $text, $line_num, $pod_para) = @_;
    $self->ac_section($text);
}

sub textblock {
    my ($self, $text, $line_num, $pod_para) = @_;
    $self->ac_section($text);
}

sub command {
    my ($self, $cmd, $text, $line_num, $pod_para)  = @_;
    $self->ac_section($pod_para->raw_text);
}

sub ac_section {
    my ($self, $text) = @_;
    my $pos = ++$self->{ac_pos};

    # print the original POD
    my $out_fh = $self->output_handle;
    print $out_fh $text;

    # print notes if available
    my $notes = $self->{ac_notes};
    while (@$notes and $notes->[0]{pos} == $pos) {
        my $note = shift @$notes;
        $note->{time_str} = gmtime($note->{time});
        print $out_fh <<NOTE;

=over 8

=over 4

=item AnnoCPAN note by I<$note->{user}>, $note->{time_str}:

$note->{note}

=back

=back

NOTE
    }
}

1;
