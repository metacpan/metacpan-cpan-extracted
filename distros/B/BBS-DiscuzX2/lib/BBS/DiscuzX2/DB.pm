#ABSTRACT : Discuz X2 的 数据库操作
package BBS::DiscuzX2::DB;
use parent 'Teng';
use Digest::MD5 qw(md5_hex);
use Date::Calc qw(Mktime);
our @SALT_CHARS  = ( 0 .. 9, 'a' .. 'z' );
our $DEFAULT_MAIL = 'xxx@xxx.com';
our $DEFAULT_USER_IP = '0.0.0.0';
our $DEFAULT_PASSWD = 'ashaxj';
our $DEFAULT_GROUP_ID = 10;

sub create_user {
    my ( $self, $data ) = @_;

    my $uid = $self->check_username($data->{user});
    return $uid if ($uid);

    my $salt = $self->mksalt();
    my $passwd = md5_hex( md5_hex( $data->{passwd} || $self->{default_passwd} || $DEFAULT_PASSWD ) . $salt );

    my $time = time();
    $self->insert(
        'pre_ucenter_members',
        +{
            username => $data->{user},
            password => $passwd,
            email    => $data->{mail} || $DEFAULT_MAIL,
            regip    => $data->{user_ip} || $DEFAULT_USER_IP,
            regdate  => $time,
            salt     => $salt,
        }
    );

    $uid = $self->check_username($data->{user});
    return unless ($uid);

    $self->insert( 'pre_ucenter_memberfields', +{ uid => $uid, } );

    $self->insert(
        'pre_common_member',
        +{
            uid        => $uid,
            email      => $data->{mail} || $DEFAULT_MAIL,
            username   => $data->{user},
            password   => $passwd,
            groupid    => $data->{group_id} // $self->{default_group_id} // $DEFAULT_GROUP_ID,
            regdate    => $time,
            adminid    => $data->{is_admin} || 0,
            timeoffset => $data->{time_offset} || 0,
        }
    );

    $self->insert(
        'pre_common_member_count',
        +{
            uid         => $uid,
            extcredits2 => 2,
        }
    );

    return $uid;
}

sub check_username {
    my ( $self, $username ) = @_;
    my $row =
    $self->single( 'pre_ucenter_members', { username => $username, } );
    return unless ( $row->{row_data} );
    return $row->{row_data}{uid};
}

sub mksalt {
    my ($self) = @_;
    my @salts = map {
    my $i = int( rand(9999) ) % $#SALT_CHARS;
    $SALT_CHARS[$i]
    } ( 1 .. 6 );
    return join( "", @salts );
}

sub load_thread {
    my ( $self, $data ) = @_;

    $_->{dateline} = $self->make_time_dateline($_->{dateline}) for @{$data->{floors}};
    
    my $tid = $self->load_forum_thread($data);
    return unless ($tid);

    $data->{tid} = $tid;
    $self->load_forum_post( $data );

    return $tid;
}

sub make_time_dateline {
    my ( $self, $t ) = @_;
    return $t if($t=~/^\d+$/);
    my @args = split /[:\- \/]+/, $t;
    return Mktime(@args);
}

sub load_forum_thread {
    my ( $self, $d ) = @_;

    my $first = $d->{floors}[0];
    my $author_id = $self->create_user({ user => $first->{poster} });

    my $last = $d->{floors}[-1];

    my %data = (
        fid        => $d->{fid},
        author     => $first->{poster},
        authorid   => $author_id,
        subject    => $first->{subject},
        dateline   => $first->{dateline},
        lastpost   => $last->{dateline},
        lastposter => $last->{poster},
        replies    => $#{$d->{floors}},
    );

    $self->insert( 'pre_forum_thread', \%data );
    my $tid = $self->get_tid( \%data );

    return $tid;
}

sub get_tid {
    my ( $self, $opt ) = @_;
    my $row = $self->single( 'pre_forum_thread', $opt );
    return unless ( $row->{row_data} );
    return $row->{row_data}{tid};
}

sub load_forum_post {
    my ( $self, $data ) = @_;

    my %author_to_id;
    my @floors_data;

    my $f = $data->{floors};
    for my $i ( 0 .. $#$f ) {
        my $r      = $f->[$i];

        my $author = $r->{poster};
        $author_to_id{$author} ||= $self->create_user({ user => $author });

        my %temp = (
            fid       => $data->{fid},
            tid       => $data->{tid},
            first     => $i > 0 ? 0 : 1,
            author    => $author,
            authorid  => $author_to_id{$author},
            subject   => $r->{subject} || '',
            dateline  => $r->{dateline},
            message   => $r->{message},
            useip     => $r->{user_ip} || $DEFAULT_USER_IP,
            htmlon    => $r->{is_html} || 0,
            bbcodeoff => ! $r->{is_bbcode} || 0,
        );

        $self->insert( 'pre_forum_post', \%temp );
}
}

1;

package BBS::DiscuzX2::DB::Schema;
use Teng::Schema::Declare;

#贴子内容
table {
    name 'pre_forum_post';
    columns
    qw( fid tid first author authorid subject dateline message useip htmlon bbcodeoff);
};

#贴子索引
table {
    name 'pre_forum_thread';
    columns
    qw(tid fid author authorid subject dateline lastpost lastposter replies);
};

#激活用户
table {
    name 'pre_common_member';
    pk 'uid';
    columns qw(uid email username password adminid groupid regdate timeoffset);
};

table {
    name 'pre_common_member_count';
    pk 'uid';
    columns qw(uid extcredits2);
};

#新建用户
#salt : 6字符随机数[0-9a-z]
#passwd : md5(md5(raw_passwd).salt)
#test : hcyy -> salt 043746, regdate 1328622816
table {
    name 'pre_ucenter_members';
    columns qw(uid username password email regip regdate salt);
};

table {
    name 'pre_ucenter_memberfields';
    pk 'uid';
    columns qw(uid);
};

1;
