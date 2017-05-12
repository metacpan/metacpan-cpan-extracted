# NAME

AnyEvent::MultiDownload - 非阻塞的多线程多地址文件下载的模块

# SYNOPSIS

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
            my ($hdr, $block_obj, $md5) = @_;
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

以上是同时下载多个文件的实例. 这个过程有其它的事件并不会阻塞.

# 属性

## url 

下载的主地址, 这个是下载用的 master 的地址, 是主地址, 这个参数必须有.

## path 

下载后的存放地址, 这个地址用于指定, 下载完了, 存放在什么位置. 这个参数必须有.

## mirror

文件下载的镜象地址, 这个是可以用来做备用地址和分块下载时用的地址. 需要一个数组引用, 其中放入这个文件的其它用于下载的地址. 如果块下载失败会自动切换成其它的地址下载. 本参数不是必须的.

## block\_size 

下载块的大小, 默认这个 block\_size 是指每次取块的大小, 默认是 1M 一个块, 这个参数会给文件按照 1M 的大小来切成一个个块来下载并合并. 本参数不是必须的.

## digest

用于指定所使用的块较检所使用的模块, 支持 Digest::MD5 和 Digest::SHA1

## retry\_interval 

重试的间隔, 默认为 10 s.

## max\_retries 

重试每个块所能重试的次数, 默认为 3 次.

## max\_per\_host 

每个文件最多发出去的连接数量.

## headers 

如果你想自己定义传送的 header , 就在这个参数中加就好了, 默认是一个哈希引用.

## timeout

下载多久算超时, 可选参数, 默认为 10s.

## recurse 重定向

如果请求过程中有重定向, 可以最多重定向多少次.

## content\_file DEPRECATED

这个属性被替换成 path

# METHODS

## start()

事件开始的方法. 只有调用这个函数时, 这个下载的事件才开始执行.

## multi\_get\_file() DEPRECATED

这个方式替换成 start 了

# 回调

## on\_block\_finish

当每下载完 1M 时, 会回调一次, 你可以用于检查你的下载每块的完整性, 这个时候只有 200 和 206 响应的时候才会回调.

回调传四个参数, 本块下载时响应的 header, 当前块的信息的引用 ( 包含 block 第几块, size 下载块的大小, pos 块的开始位置 ), 检查的 md5 或者 sha1 的结果. 这个需要返回值, 如果值为 1 证明检查结果正常, 如果为 0 证明检查失败. 

默认模块会帮助检查大小, 所以大小不用对比和检查了, 这个地方会根据 $self->digest 指定的信息, 给每块的 MD5 或者 SHA1 记录下来, 使用这个来对比. 本参数不是必须的. 如果没有这个回调默认检查大小正确.

## on\_finish

当整个文件下载完成时的回调, 下载完成的回调会传一个下载的文件大小的参数过来. 这个回调必须存在.

## on\_error

当整个文件下载过程出错时回调, 这个参数必须存在, 因为不能保证每次下载都能正常.

## on\_seg\_finish DEPRECATED

这个回调被替换成 on\_block\_finish 回调了.

# SEE ALSO

[AnyEvent](https://metacpan.org/pod/AnyEvent), [AnyEvent::HTTP](https://metacpan.org/pod/AnyEvent::HTTP), [App::ManiacDownloader](https://metacpan.org/pod/App::ManiacDownloader).

# AUTHOR

扶凯 fukai <iakuf@163.com>
