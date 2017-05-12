#ABSTRACT: DISCUZ X2 帖子处理

=pod

=encoding utf8

=head1 NAME

BBS::DiscuzX2

=over 

=back

=head1 DESCRIPTION 

Discuz X2 贴子处理器

=over 

=back

=head1 SYNOPSIS

   注意：数据库中的表名前缀固定为pre_

=over 

=back

=head1 FUNCTION

=head2 init_db_handler

    #初始化

    my $bbs = BBS::DiscuzX2->new();

    #初始化后台数据库连接

    #dp_port / db_charset 也可不填

    $bbs->init_db_handler(

        db_host => 'xxx.xxx.xxx.xxx',

        db_port => 3306, 

        db_user => 'xxx',

        db_passwd => 'xxx',

        db_name => 'xxx',

        db_charset => 'utf8', 
    );

=over

=back

=head2 create_user

    #后台新建论坛用户

    #如果passwd未指定，则采用default_passwd

    #group_id 为用户所在群组，如果未指定，则采用default_group_id

    #mail/user_ip可不填

    $bbs->{db_handler}{default_passwd} = 'ashaxj';

    $bbs->{db_handler}{default_group_id} = 10;

    my $uid = $bbs->create_user({

        user => 'xxx',

        passwd => 'xxx',

        group_id => 10, 

        mail => 'xxx@xxx.xxx',

        user_ip => 'xxx.xxx.xxx.xxx', 

    });

=over

=back

=head2 load_thread

    #从后台向 版块10 载入一个贴子

    my $data = {

        fid => 10, 

        floors => [

            {   poster => 'abc', subject => 'test', dateline => '2013-03-05 11:20:00', 

                message => 'just a test', user_ip => '123.123.123.123', 

                is_html => 0, is_bbcode => 1, 

            }, 

            {   poster => 'def', dateline => '2013-03-05 11:21:00', 

                message => 'just a test reply', user_ip => '222.222.222.222', 

            }, 

            {   poster => 'ghi',  dateline => '2013-03-06 10:00:03', 

                message => 'just a test reply update', user_ip => '202.202.202.202', 
            }, 

        ], 

    };

    my $tid = $self->load_thread($data);

=over 

=back

=head2 init_browser

    #初始化浏览器

    $bbs->init_browser(

        'User-Agent' => 

        'Mozilla/5.0 (Windows NT 6.1; rv:19.0) Gecko/20100101 Firefox/19.0',

    );

=over 

=back

=head2 login

    #用户登录

    $bbs->login(

        site => 'http://127.0.0.1/discuz_x2/',

        user => 'xxx',

        passwd => 'xxx', 

    );

=over 

=back

=head2 post_thread

    #在版块2发新帖

    my $r = $bbs->post_thread({

            fid => 2,

            subject => 'hello world',

            message => 'just a test ', 

        });

    #$r->{tid}为贴子编号

    #$r->{pid}为贴子内容编号

    #$r->{res}为返回的html response

=over 

=back

=head2 delete_thread

    #删帖

    $bbs->delete_thread({

            fid => 2, 

            tid => 6, 

            pid => 9, 

        });

=over

=back

=over 

=back

=cut

use strict;
use warnings;
package BBS::DiscuzX2;
use Moo;
use BBS::DiscuzX2::DB;
use WWW::Mechanize;

our $VERSION =0.01;

sub init_browser {
    my ($self, %opt) = @_;

    $self->{browser} = WWW::Mechanize->new(autocheck=>0);                                                        
    while(my ($k, $v) = each %opt){
        $self->{browser}->add_header($k => $v);
    }

    $self;
}

sub login {
    my ($self, %opt) = @_;

    $self->{browser}->add_header('Referer' => $opt{site});
    my $url = $opt{site}.'member.php?mod=logging&action=login&loginsubmit=yes&infloat=yes&lssubmit=yes&inajax=1';
    my $data = [
        username=>$opt{user},
        password=>$opt{passwd},
        fastloginfield=>'username',
        quickforward=>'yes',
        handlekey=>'ls', 
    ];
    my $res = $self->{browser}->post($url, $data);
    return unless($res->is_success);
    $self->{site}  = $opt{site};

    $res = $self->{browser}->get($opt{site}.'forum.php');
    return unless($res->is_success);

    ($self->{formhash}) = $res->decoded_content =~ m/formhash=(\w+)">/s;
    return 1;
}

sub post_thread {
    my ($self, $data) = @_;
    my $url = "$self->{site}forum.php?mod=post&action=newthread&fid=$data->{fid}&extra=&topicsubmit=yes";
    my $res = $self->{browser}->post($url,
        [
            'formhash' => $self->{formhash},
            'message' => $data->{message},
            'subject' => $data->{subject},
            'usesig' => $data->{use_sig} // 1,
            'allownoticeauthor' => $data->{notice_author} // 1,
            'wysiwyg' => '1',
            'newalbum' => '',
            'posttime' => '',
            'save' => '',
            'uploadalbum' => '',
        ],	
    );

    return unless($res->is_success);

    my ($tid, $pid) = $res->as_string =~ m[action=edit&amp;fid=\d+&amp;tid=(\d+)&amp;pid=(\d+)&amp;]s;
    return {
        tid => $tid,
        pid => $pid, 
        response => $res,
    };	
}

#sub append_thread {
#	my ($self, $data) = @_;
#	my $url = "$self->{site}forum.php?mod=misc&action=postappend&tid=$data->{tid}&pid=$data->{pid}&extra=&postappendsubmit=yes&infloat=yes";
#	my $res = $self->{browser}->post($url,
#		[
#			'formhash' => $self->{formhash},
#			'postappendmessage' => $data->{message}, 
#			'handlekey' => 'postappend',
#		],
#	);
#
#	return unless($res->is_success);
#	return $res;
#}

sub delete_thread {
    my ($self, $data) = @_;
    my $url = "$self->{site}forum.php?mod=post&action=edit&extra=&editsubmit=yes";
    my $referer = "$self->{site}forum.php?mod=post&action=edit&fid=$data->{fid}&tid=$data->{tid}&pid=$data->{pid}&page=1";
    $self->{browser}->add_header('Referer' => $referer);
    my $res = $self->{browser}->post($url,
        [
            fid	=> $data->{fid}, 
            tid	=> $data->{tid}, 
            pid	=> $data->{pid}, 
            formhash	=> $self->{formhash},
            allownoticeauthor	=> $data->{notice_author} // 1, 
            delattachop	=> $data->{del_attach} || 0, 
            delete	=> 1,
        ],
    );

    return unless($res->is_success);
    return 1;
}

sub init_db_handler {
    my ($self, %db_opt) = @_;
    $db_opt{db_port} ||= 3306;

    my $dsn      = "DBI:mysql:host=$db_opt{db_host};port=$db_opt{db_port};database=$db_opt{db_name}";
    $self->{db_handler} = BBS::DiscuzX2::DB->new(
        connect_info => [ $dsn, $db_opt{db_user}, $db_opt{db_passwd} ]
    );

    if($db_opt{db_charset}){
        $self->{db_handler}->do("SET character_set_client='$db_opt{db_charset}'");
        $self->{db_handler}->do("SET character_set_connection='$db_opt{db_charset}'");
        $self->{db_handler}->do("SET character_set_results='$db_opt{db_charset}'");
    }

    for my $k (qw/default_passwd default_group_id/){
        next unless(exists $db_opt{$k});
        $self->{db_handler}{$k} = $db_opt{$k};
    }

    $self;
}

sub create_user {
    my ($self,$data) = @_;
    $self->{db_handler}->create_user($data);
}

sub load_thread {
    my ($self,$data) = @_;
    $self->{db_handler}->load_thread($data);
}

1;
