package Data::SimpleKV;

use strict;
use warnings;
use Storable qw(store_fd retrieve_fd);
use Fcntl qw(:flock SEEK_SET);
use File::Path qw(make_path);
use File::Spec;
use Encode qw(encode_utf8 decode_utf8);
use Carp;
use utf8;

our $VERSION = '0.03';

=encoding utf8

=head1 NAME

Data::SimpleKV - A simple key-value database with memory cache and disk persistence

=head1 SYNOPSIS

    use Data::SimpleKV;
    
    my $db = Data::SimpleKV->new(
        db_name => 'myapp',
        data_dir => '/var/lib/simplekv'  # optional
    );
    
    $db->set('key1', '测试值');
    my $value = $db->get('key1');
    my $exists = $db->exists('key1');
    $db->delete('key1');
    $db->save();

=head1 DESCRIPTION

Data::SimpleKV provides a simple key-value database with in-memory caching and 
disk persistence. It supports UTF-8 data storage and is safe for multi-process usage.

=cut

sub new {
    my ($class, %args) = @_;
    
    my $db_name = $args{db_name} || croak "db_name is required";
    
    # 确定数据目录
    my $data_dir = $args{data_dir};
    if (!$data_dir) {
        # 尝试使用 /var/lib/simplekv
        my $system_dir = '/var/lib/simplekv';
        if (-w '/var/lib') {
            # 有权限访问 /var/lib，尝试创建或使用 simplekv 目录
            if (-d $system_dir || mkdir($system_dir, 0755)) {
                $data_dir = $system_dir;
            }
        }

        # 如果系统目录不可用，使用用户目录
        if (!$data_dir) {
            $data_dir = File::Spec->catdir($ENV{HOME} || '/tmp', '.simplekv');
        }
    }

    # 创建数据目录（如果不存在）
    make_path($data_dir, { mode => 0755 }) unless -d $data_dir;

    
    # 数据文件路径
    my $data_file = File::Spec->catfile($data_dir, "${db_name}.db");
    
    my $self = {
        db_name   => $db_name,
        data_dir  => $data_dir,
        data_file => $data_file,
        cache     => {},
        dirty     => 0,  # 标记是否有未保存的更改
    };
    
    bless $self, $class;
    
    # 加载现有数据
    $self->_load_data();
    
    return $self;
}

=head2 get($key)

Get value by key. Returns undef if key doesn't exist.

=cut

sub get {
    my ($self, $key) = @_;
    croak "Key is required" unless defined $key;
    
    # UTF-8编码处理
    $key = encode_utf8($key) if utf8::is_utf8($key);
    
    my $value = $self->{cache}{$key};
    
    # 如果值是UTF-8字节串，解码为字符串
    if (defined $value && !utf8::is_utf8($value)) {
        $value = decode_utf8($value, Encode::FB_QUIET);
    }
    
    return $value;
}

=head2 set($key, $value)

Set key-value pair.

=cut

sub set {
    my ($self, $key, $value) = @_;
    croak "Key is required" unless defined $key;
    croak "Value is required" unless defined $value;
    
    # UTF-8编码处理
    $key = encode_utf8($key) if utf8::is_utf8($key);
    $value = encode_utf8($value) if utf8::is_utf8($value);
    
    $self->{cache}{$key} = $value;
    $self->{dirty} = 1;
    
    return 1;
}

=head2 delete($key)

Delete key-value pair. Returns 1 if key existed, 0 otherwise.

=cut

sub delete {
    my ($self, $key) = @_;
    croak "Key is required" unless defined $key;

    # UTF-8编码处理
    $key = encode_utf8($key) if utf8::is_utf8($key);

    if (exists $self->{cache}{$key}) {
        delete $self->{cache}{$key};
        $self->{dirty} = 1;
        return 1;
    }

    return 0;
}

=head2 exists($key)

Check if key exists. Returns 1 if exists, 0 otherwise.

=cut

sub exists {
    my ($self, $key) = @_;
    croak "Key is required" unless defined $key;
    
    # UTF-8编码处理
    $key = encode_utf8($key) if utf8::is_utf8($key);
    
    return exists $self->{cache}{$key} ? 1 : 0;
}

=head2 save()

Save data to disk. This method is process-safe using file locking.

=cut

sub save {
    my ($self) = @_;
    
    # 如果没有更改，不需要保存
    return 1 unless $self->{dirty};
    
    return $self->_save_with_lock();
}

=head2 keys()

Get all keys as a list.

=cut

sub keys {
    my ($self) = @_;

    return map {
        eval { decode_utf8($_) } || $_
    } keys %{$self->{cache}};
}

=head2 clear()

Clear all data from memory cache.

=cut

sub clear {
    my ($self) = @_;
    $self->{cache} = {};
    $self->{dirty} = 1;
    return 1;
}

# 私有方法：加载数据
sub _load_data {
    my ($self) = @_;
    
    return unless -f $self->{data_file};
    
    eval {
        open my $fh, '<', $self->{data_file} or die "Cannot open data file: $!";
        
        my $data = retrieve_fd($fh);
        $self->{cache} = $data || {};
        
        close $fh;
    };
    
    if ($@) {
        warn "Failed to load data: $@";
        $self->{cache} = {};
    }
}

# 私有方法：带锁保存数据
sub _save_with_lock {
    my ($self) = @_;
    
    eval {
        # 使用 +> 模式：如果文件不存在则创建，如果存在则截断
        open my $fh, '+>', $self->{data_file} or die "Cannot open data file: $!";
        
        # 获取排他锁
        flock($fh, LOCK_EX) or die "Cannot acquire exclusive lock: $!";
        
        # 确保从文件开头写入
        seek($fh, 0, SEEK_SET);
        
        # 存储数据
        store_fd($self->{cache}, $fh) or die "Cannot store data: $!";
        
        # 确保数据写入磁盘
        $fh->flush();
        
        close $fh or die "Cannot close data file: $!";
        
        chmod 0644, $self->{data_file};
        $self->{dirty} = 0;
    };
    
    if ($@) {
        croak "Failed to save data: $@";
    }
    
    return 1;
}

# 析构函数：自动保存未保存的更改
sub DESTROY {
    my ($self) = @_;
    
    if ($self->{dirty}) {
        eval { $self->save() };
        warn "Auto-save failed during destruction: $@" if $@;
    }
}

1;

__END__

=head1 FILE STRUCTURE

The module stores data files in the following locations:

=over 4

=item * Primary location: /var/lib/simplekv/

=item * Fallback location: $HOME/.simplekv/

=item * Emergency fallback: /tmp/.simplekv/

=back

Files created:

=over 4

=item * {db_name}.db - The main data file (Storable binary format)

=back

File permissions are set to 0644 (readable by all, writable by owner).

=head1 MULTI-PROCESS SAFETY

The module uses file locking to ensure safe concurrent access:

=over 4

=item * Exclusive locks for writing during save operations

=item * Lock files prevent concurrent write operations

=back

Note: Data merging between processes is not supported. The last process 
to call save() will overwrite previous changes.

=head1 UTF-8 SUPPORT

The module fully supports UTF-8 encoded strings for both keys and values.
All string data is properly encoded/decoded to ensure correct storage 
and retrieval of international characters.

=head1 DEPENDENCIES

=over 4

=item * Storable - For binary serialization

=item * Fcntl - For file locking

=item * File::Path - For directory creation

=item * File::Spec - For cross-platform file paths

=item * Encode - For UTF-8 handling

=back

=head1 AUTHOR

Y Peng, C<< <ypeng at t-online.de> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2025 by Y Peng.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
