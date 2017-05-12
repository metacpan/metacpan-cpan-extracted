#!/usr/bin/perl
package AnyEvent::MultiDownload;
use strict;
use utf8;
use Moo;
use AE;
use Asset::File;
use AnyEvent::Digest;
use List::Util qw/shuffle/;
use AnyEvent::HTTP qw/http_get/;

our $VERSION = '1.13';

has path => (
    is => 'ro',
    isa => sub {
        die "文件存在" if -e $_[0];
    },
    required => 1,
);

has url => (
    is  => 'ro',
    required => 1,
);


has mirror => (
    is => 'rw',
    predicate => 1,
    isa => sub {
        return 1 if ref $_[0] eq 'ARRAY';
    },
);

has digest => (
    is => 'rw',
    isa => sub {
        return 1 if $_[0] =~ /Digest::(SHA|MD5)/;
    }
);


has on_finish => (
    is => 'rw',
    required => 1,
    isa => sub {
        return 2 if ref $_[0] eq 'CODE';
    }
);

has on_error => (
    is => 'rw',
    isa => sub {
        return 2 if ref $_[0] eq 'CODE';
    },
    default => sub {  sub { 1 } },
);

has on_block_finish => (
    is => 'rw',
    isa => sub {
        return 2 if ref $_[0] eq 'CODE';
    },
    default => sub { return sub {1} }
);

has cv => (
    is       => 'rw',
    lazy     => 1,
    default => sub { AE::cv },
);

has fh       => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        return Asset::File->new;
    },
);

has retry_interval => is => 'rw', default => sub { 10 };
has max_retries    => is => 'rw', default => sub { 3 };
has block_size       => is => 'rw', default => sub { 1 * 1024 * 1024 };
has timeout        => is => 'rw', default => sub { 10 };
has recurse        => is => 'rw', default => sub { 6 }; 
has headers        => is => 'rw', default => sub {{}};
has tasks          => is => 'rw', default => sub { [] };
has error          => is => 'rw', default => sub {};
has task_lists     => is => 'rw', default => sub {[]};
has max_per_host   => is => 'rw', default => sub { 8 };
has url_status  => (
    is      => 'rw', 
    lazy    => 1,
    default => sub { 
        my $self = shift;
        my %hash;
        if ($self->has_mirror) {
            %hash = map {
                        $_ => 0
                    } @{ $self->mirror }, $self->url;
        }
        else {
            $hash{$self->url} = 0;
        }
        return \%hash;
    }
);

sub start  {
    my $self = shift;
    my $cb   = shift;
    
    $self->cv->cb(sub{
        my $cv = shift;
        my ($info, $hdr) = $cv->recv;
        # 出错的回调
        if ($info) {
            AE::log debug => $info;
            return $self->on_error->($info, $hdr);
        }
        # 移文件
        eval {
            $self->fh->move_to($self->path);
        };
        if ($@) {
            AE::log debug => $@;
            return $self->on_error->("$@", []);
        }
        $self->on_finish->($self->fh->size);
    });

    $self->cv->begin;
    $self->first_request(0);
}


sub first_request {
    my ($self, $retry) = @_;
    my $url = $self->shuffle_url;

    my $first_task;
    my $ev; $ev = http_get $url,
        headers     => $self->headers, 
        timeout     => $self->timeout,
        recurse     => $self->recurse,
        on_header   => sub {
            my ($hdr) = @_;
            if ( $hdr->{Status} == 200 ) {
                my $len = $hdr->{'content-length'};
                return $self->cv->send(("Cannot find a content-length header.", $hdr)) 
                    if !defined($len) or $len <= 0;

                # 准备开始下载的信息
                my $ranges = $self->split_range($len);

                # 除了第一个块, 其它块现在开始下载
                # 事件开始, 但这个回调会在最后才调用.
                $first_task = shift @{ $self->tasks };
                $first_task->{block} = $first_task->{block} || 0;
                $first_task->{ofs}   = $first_task->{ofs}   || 0;
                return 1 if $len <= $self->block_size;

                for ( 1 .. $self->max_per_host ) {
                    my $block_task = shift @{ $self->tasks };
                    last unless defined $block_task;
                    $self->cv->begin;
                    $self->fetch_block($block_task) ;

                }
            }
            1
        },
        on_body   => sub {
            my ($partial_body, $hdr) = @_;
            if ( $self->on_body($first_task)->($partial_body, $hdr) ) {
                # 如果是第一个块的话, 下载到指定的大小就需要断开
                if ( ( $hdr->{'content-length'} <= $self->block_size and  $first_task->{size} == $hdr->{'content-length'} )
                        or 
                        $first_task->{size} >= $self->block_size
                    ) {

                    $self->cv->send(("The 0 block the compared failure", $hdr)) 
                        if !$self->on_block_finish->( $hdr, $first_task, $self->digest ? $first_task->{ctx}->hexdigest : '');
                    $self->cv->end;
                    return 0
                }
            }
            return 1;
        },
        sub {
            my (undef, $hdr) = @_;
            undef $ev;
            my $status = $hdr->{Status};
            # on_body 正常的下载
            return if ( $hdr->{OrigStatus} and $hdr->{OrigStatus} == 200 ) or $hdr->{Status} == 200 or $hdr->{Status} == 416;

            if ( ($status == 500 or $status == 503 or $status =~ /^59/) and $retry < $self->max_retries ) {
                my $w; $w = AE::timer( $self->retry_interval, 0, sub {
                    $first_task->{pos}  = $first_task->{ofs}; # 重下本块时要 seek 回零
                    $first_task->{size} = 0;
                    $first_task->{ctx}  = undef;
                     $self->first_request(++$retry);
                    undef $w;
                });
                AE::log debug => "地址 $url 的块 0 下载出错, 重试";
                return;
            }

            return $self->cv->send(( 
                sprintf("Status: %s, Reason: %s.", $status ? $status : '500', $hdr->{Reason} ? $hdr->{Reason} : ' '), 
                $hdr)
            );
        }
}


sub shuffle_url {
    my $self = shift;
    my $urls = $self->url_status;
    return (shuffle keys %$urls)[0];
}

sub on_body {
    my ($self, $task) = @_; 
    return sub {
        my ($partial_body, $hdr) = @_;
        return 0 unless ($hdr->{Status} == 206 || $hdr->{Status} == 200);

        my $len = length($partial_body);
        # 主要是用于解决第一个块会超过写的位置
        if ( $task->{size} + $len > $self->block_size ) {
            my $spsize = $len - ( $task->{size} + $len - $self->block_size );
            $partial_body = substr($partial_body, 0, $spsize);
            $len = $spsize; 
        }

        $self->fh->start_range($task->{pos});
        $self->fh->add_chunk($partial_body);

        if ( $self->digest ) {
            $task->{ctx} ||= AnyEvent::Digest->new($self->digest);
            $task->{ctx}->add_async($partial_body);
        }

        $task->{pos}   += $len;
        $task->{size}  += $len;
        return 1;
    }
}

sub fetch_block {
    my ($self, $task, $retry) = @_; 
    $retry ||= 0;
    my $url   = $self->shuffle_url;

    my $ev; $ev = http_get $url,
        timeout     => $self->timeout,
        recurse     => $self->recurse,
        persistent  => 1,
        keepalive   => 1,
        headers     => { 
            %{ $self->headers }, 
            Range => $task->{range} 
        },
        on_body => $self->on_body($task),
        sub {
            my ($hdl, $hdr) = @_;
            my $status = $hdr->{Status};
            undef $ev;

            # 成功下载到的流程
            # 1. 需要对比大小是否一致, 接着对比块较检
            # 2. 开始下一个任务的下载
            # 3. 当前块就退出, 不然下面会重试
            if ( $status == 200 || $status == 206  ) { # 第一个块, 这二个都有可能
                # not ok 块较检不相等 | 直接失败
                return $self->cv->send(("The $task->{block} block the compared failure", $hdr)) 
                    if ($task->{size} != ( $task->{tail} -$task->{ofs} + 1 ) 
                        or !$self->on_block_finish->($hdl, $task, $self->digest ? $task->{ctx}->hexdigest : ''));
                my $block_task = shift @{ $self->tasks };
                # 完成, 标记结束本次请求
                # ok  大小相等, 块较检相等, 当前块下载完成, 开始下载新的 
                AE::log debug => "地址 $url 的块 $task->{block} 下载完成 $$";
                # 处理接下来的一个请求
                $block_task ? $self->fetch_block($block_task) : $self->cv->end; 
                return; 
            } 

            # 是否重试的流程
            my $error  = sprintf(
                "Block %s the size is wrong, expect the size: %s actual size: %s, The %s try again,  Status: %s, Reason: %s.", 
                $task->{block},
                $self->block_size,
                $task->{size},
                $retry,
		    	$status ? $status : '500', 
                $hdr->{Reason} ? $hdr->{Reason} : ' ', );
            AE::log warn => $error; 
            
            # 失败
            # 如果有可能还连接上的响应, 就需要重试, 直到达到重试, 如果不可能连接的响应, 就直接快速的退出
            return $self->cv->send(($error, $hdr)) 
                if $status !~ /^(59.|503|500|502|200|206|)$/ or $retry > $self->max_retries;
            
            $self->retry($task, $retry);
        }
};

sub retry {
    my ($self, $task, $retry) = @_;
    my $w;$w = AE::timer( $self->retry_interval, 0, sub {
        $task->{pos}  = $task->{ofs}; # 重下本块时要 seek 回零
        $task->{size} = 0;
        $task->{ctx}  = undef;
        $self->fetch_block( $task, ++$retry );
        undef $w;
    });
}

sub split_range {
    my $self    = shift;
    my $length  = shift;

    # 每个请求的段大小的范围,字节
    my $block_size   = $self->block_size;
    my $segments   = int($length / $block_size);

    # 要处理的字节的总数
    my $len_remain = $length;

    my @ranges;
    my $block = 0;
    while ( $len_remain > 0 ) {
        # 每个 segment  的大小
        my $seg_len = $block_size;

        # 偏移长度
        my $ofs = $length - $len_remain;
        
        # 剩余字节
        $len_remain -= $seg_len;

        my $tail  = $ofs + $seg_len - 1; 
        if ( $length-1  < $tail) {
            $tail = $length-1;
        }

        my $task  = { 
            block => $block, # 当前块编号
            ofs   => $ofs,   # 当前的偏移量
            pos   => $ofs,   # 本块的起点
            tail  => $tail,  # 本块的结束
            range => 'bytes=' . $ofs . '-' . $tail, 
            size  => 0,      # 总共下载的长度
        }; 

        $self->tasks->[$block] = $task; 
        $block++;
    }
}

1;

__END__

=pod
 
=encoding utf8

=head1 NAME

AnyEvent::MultiDownload - 非阻塞的多线程多地址文件下载的模块

=head1 SYNOPSIS

这是一个全非阻塞的多线程多地址文件下载的模块, 可以象下面这个应用一样, 同时下载多个文件, 并且整个过程都是异步事件解发, 不会阻塞主进程.

下面是个简单的例子, 同时从多个地址下载同一个文件.

    use AE;
    use AnyEvent::MultiDownload;

    my @urls = (
        'http://mirrors.163.com/centos/7/isos/x86_64/CentOS-7.0-1406-x86_64-DVD.iso',
        'http://mirrors.sohu.com/centos/7/isos/x86_64/CentOS-7.0-1406-x86_64-DVD.iso',
    );
    
    my $cv = AE::cv;
    my $MultiDown = AnyEvent::MultiDownload->new( 
        url     => pop @urls, 
        mirror  => \@urls, 
        path  => '/tmp/ubuntu.iso',
        block_size => 1 * 1024 * 1024, # 1M
        on_block_finish => sub {
            my ($hdr, $block_ref, $md5) = @_;
            if ($md5 eq $src_md5) {
                return 1;
            }
            0
        },
        on_finish => sub {
            my $len = shift;
            $cv->send;
        },
        on_error => sub {
            my ($error, $hdr) = @_;
            $cv->send;
        }
    )->start;
    
    $cv->recv;


下面是异步同时下载多个文件的实例. 整个过程异步.

    use AE;
    use AnyEvent::MultiDownload;
    
    my $cv = AE::cv;
    
    $cv->begin;
    my $MultiDown = AnyEvent::MultiDownload->new( 
        url     => 'http://xxx/file1',
        path  => "/tmp/file2",
        on_finish => sub {
            my $len = shift;
            $cv->end;
        },
        on_error => sub {
            my ($error, $hdr) = @_;
            $cv->end;
        }
    );
    $MultiDown->start;
    
    $cv->begin;
    my $MultiDown1 = AnyEvent::MultiDownload->new( 
        url     => 'http://xxx/file2', 
        path  => "/tmp/file1",
        on_finish => sub {
            my $len = shift;
            $cv->end;
        },
        on_error => sub {
            my ($error, $hdr) = @_;
            $cv->end;
        }
    );
    $MultiDown1->start;
    
    $cv->recv;

以上是同时下载多个文件的实例. 这个过程有其它的事件并不会阻塞. 所以同时文件都会开始下载，并且这时可以执行其它的事件.

=head1 属性

=head2 url 

下载的主地址, 这个是下载用的 master 的地址, 是主地址, 这个参数必须有.

=head2 path 

下载后的存放地址, 这个地址用于指定, 下载完了, 存放在什么位置. 这个参数必须有.

=head2 mirror

文件下载的镜象地址, 这个是可以用来做备用地址和分块下载时用的地址. 需要一个数组引用, 其中放入这个文件的其它用于下载的地址. 如果块下载失败会自动切换成其它的地址下载. 本参数不是必须的.

=head2 block_size 

下载块的大小, 默认这个 block_size 是指每次取块的大小, 默认是 1M 一个块, 这个参数会给文件按照 1M 的大小来切成一个个块来下载并合并. 本参数不是必须的.

=head2 digest

用于指定所使用的块较检所使用的模块, 支持 Digest::MD5 和 Digest::SHA1

=head2 retry_interval 

重试的间隔, 默认为 10 s.

=head2 max_retries 

重试每个块所能重试的次数, 默认为 3 次.

=head2 max_per_host 

每个文件最多发出去的连接数量.

=head2 headers 

如果你想自己定义传送的 header , 就在这个参数中加就好了, 默认是一个哈希引用.

=head2 timeout

下载多久算超时, 可选参数, 默认为 10s.

=head2 recurse 重定向

如果请求过程中有重定向, 可以最多重定向多少次.

=head2 content_file DEPRECATED

这个属性被替换成 path

=head1 METHODS

=head2 start()

事件开始的方法. 只有调用这个函数时, 这个下载的事件才开始执行.

=head2 multi_get_file() DEPRECATED

这个方式替换成 start 了

=head1 回调

=head2 on_block_finish

当每下载完 1M 时, 会回调一次, 你可以用于检查你的下载每块的完整性, 这个时候只有 200 和 206 响应的时候才会回调.

回调传四个参数, 本块下载时响应的 header, 当前块的信息的引用 ( 包含 block 第几块, size 下载块的大小, pos 块的开始位置, 检查的 md5 或者 sha1 的结果 ). 这个需要返回值, 如果值为 1 证明检查结果正常, 如果为 0 证明检查失败. 

默认模块会帮助检查大小, 所以大小不用对比和检查了, 这个地方会根据 $self->digest 指定的信息, 给每块的 MD5 或者 SHA1 记录下来, 使用这个来对比. 本参数不是必须的. 如果没有这个回调默认检查大小正确.

=head2 on_finish

当整个文件下载完成时的回调, 下载完成的回调会传一个下载的文件大小的参数过来. 这个回调必须存在.

=head2 on_error

当整个文件下载过程出错时回调, 这个参数必须存在, 因为不能保证每次下载都能正常.

=head2 on_seg_finish DEPRECATED

这个回调被替换成 on_block_finish 回调了.

=head1 SEE ALSO

L<AnyEvent>, L<AnyEvent::HTTP>, L<App::ManiacDownloader>.

=head1 AUTHOR

扶凯 fukai <iakuf@163.com>

=cut
