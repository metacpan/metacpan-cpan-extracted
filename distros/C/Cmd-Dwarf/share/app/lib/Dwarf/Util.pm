package Dwarf::Util;
use Dwarf::Pragma;
use parent qw(Exporter);
use Encode ();
use File::Basename ();
use File::Path ();
use JSON ();
use Scalar::Util qw(blessed refaddr);

our @EXPORT_OK = qw/
	add_method
	load_class
	installed
	capitalize
	shuffle_array
	filename
	read_file
	write_file
	get_suffix
	safe_join
	merge_hash
	random_string
	safe_decode_json
	encode_utf8
	decode_utf8
	encode_utf8_recursively
	decode_utf8_recursively
	apply_recursively
	dwarf_log
/;

# メソッドの追加
sub add_method {
	my ($klass, $method, $code) = @_;
	$klass = ref $klass || $klass;
	no strict 'refs';
	no warnings 'redefine';
	*{"${klass}::${method}"} = $code;
}

# クラスの読み込み
sub load_class {
	my($class, $prefix) = @_;

	if ($prefix) {
		unless ($class =~ s/^\+// || $class =~ /^$prefix/) {
			$class = "$prefix\::$class";
		}
	}

	my $file = $class;
	$file =~ s!::!/!g;
	require "$file.pm";

	return $class;
}

# モジュールがインストールされているかを確認
sub installed {
	my ($class, $prefix) = @_;
	my $installed = 1;
	eval { load_class($class, $prefix) };
	if ($@) {
		# warn $@;
		$@ = undef;
		$installed = 0;
	}
	return $installed;
}

# キャピタライズ
sub capitalize {
	my $value = shift;
	$value =~ s/-/_/g;
	my @flagments = split '_', $value;
	return join '', map { ucfirst $_ } @flagments;
}

# 配列をシャッフル
sub shuffle_array {
	my @a = @_;
	return @a if @a == 0;

	for (my $i = @a - 1; $i >= 0; $i--) {
		my $j = int(rand($i + 1));
		next if $i == $j;
		@a[$i, $j] = @a[$j, $i];
	}

	return (@a);
}

# ある Perl モジュールのファイル名を返す
sub filename {
	my $invocant = shift;
	my $class = ref $invocant || $invocant;
	$class =~ s/::/\//g;
	$class .= '.pm';
	return exists $INC{$class} ? $INC{$class} : $class;
}

# ファイルを読み込む
sub read_file {
	my ($path, $glue) = @_;
	$glue //= "";
	my @body;
	open my $fh, '<', $path or die "Couldn't open $path";
	binmode $fh;
	while (my $line = <$fh>) {
		push @body, $line;
	}
	close $fh;
	return join $glue, @body;
}

# あるパスにコンテンツを書き出す（自動的に mkpath してくれる）
sub write_file {
	my ($path, $content) = @_;

	my $dir = File::Basename::dirname($path);

	unless (-d $dir) {
		File::Path::mkpath $dir or die "Couldn't make $dir"
	}

	open my $fh, '>', $path or die "Couldn't open $path";
	print $fh $content;
	close $fh;
}

# ファイルの拡張子を取得
sub get_suffix {
	my $filename = shift;
	my $suffix;
	if ($filename =~ /.+\.(\S+?)$/) {
		$suffix = lc $1;
	}
	return $suffix;
}

# undef が含まれるかも知れない変数の join
sub safe_join {
	my $a = shift;
	my @b = map { defined $_ ? $_ : '' } @_;
	join $a, @b;
}

# 二つのハッシュリファレンスを簡易マージ
sub merge_hash {
	my ($a, $b) = @_;
	return $b unless defined $a;
	return {} if ref $a ne 'HASH' or ref $b ne 'HASH';

	for my $k (%{ $b }) {
		next unless defined $k;
		if (defined $b->{ $k }) {
			$a->{ $k } = $b->{ $k };
		}
	}

	return $a;
}

# ランダム文字列
sub random_string {
	my $length = shift;
	$length ||= 32;
	my $str = "";
	for (1 .. $length) {
		$str .= (0 .. 9, 'a' .. 'z')[int rand 36];
	}
	return $str;
}

# decode_json の undef 対策
sub safe_decode_json {
	my ($data) = @_;
	return undef unless defined $data;
	return JSON::decode_json($data);
}

# Encode-2.12 以下対策
sub encode_utf8 {
	my $utf8 = shift;
	return unless defined $utf8;
	my $bytes = Encode::is_utf8($utf8) ? Encode::encode_utf8($utf8) : $utf8;
	return $bytes;
}

# Encode-2.12 以下対策
sub decode_utf8 {
	my $bytes = shift;
	return unless defined $bytes;
	my $utf8 = Encode::is_utf8($bytes) ? $bytes : Encode::decode_utf8($bytes);
	return $utf8;
}

# 再帰的に encode_utf8
sub encode_utf8_recursively {
    my ($stuff, $check) = @_;
    apply_recursively(sub { Encode::encode_utf8($_[0]) }, {}, $stuff);
}

# 再帰的に decode_utf8
sub decode_utf8_recursively {
    my ($stuff, $check) = @_;
    apply_recursively(sub { Encode::decode_utf8($_[0], $check) }, {}, $stuff);
}

# 関数の再帰
sub apply_recursively {
    my $code = shift;
    my $seen = shift;

    my @retval;
    for my $arg (@_) {
        if(my $ref = ref $arg){
            my $refaddr = refaddr($arg);
            my $proto;

            if(defined($proto = $seen->{$refaddr})){
                 # noop
            }
            elsif($ref eq 'ARRAY'){
                $proto = $seen->{$refaddr} = [];
                @{$proto} = apply_recursively($code, $seen, @{$arg});
            }
            elsif($ref eq 'HASH'){
                $proto = $seen->{$refaddr} = {};
                %{$proto} = apply_recursively($code, $seen, %{$arg});
            }
            elsif($ref eq 'REF' or $ref eq 'SCALAR'){
                $proto = $seen->{$refaddr} = \do{ my $scalar };
                ${$proto} = apply_recursively($code, $seen, ${$arg});
            }
            else{ # CODE, GLOB, IO, LVALUE etc.
                $proto = $seen->{$refaddr} = $arg;
            }

            push @retval, $proto;
        }
        else{
            push @retval, defined($arg) ? $code->($arg) : $arg;
        }
    }

    return wantarray ? @retval : $retval[0];
}

# Dwarf 開発用ロガー
sub dwarf_log {
	warn @_ if defined $ENV{DWARF_LOG_LEVEL} and $ENV{DWARF_LOG_LEVEL} > 0;
}

1;
