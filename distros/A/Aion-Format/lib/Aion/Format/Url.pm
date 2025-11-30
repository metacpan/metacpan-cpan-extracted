package Aion::Format::Url;

use common::sense;

use List::Util qw//;
use Encode qw//;

use Exporter qw/import/;
our @EXPORT = our @EXPORT_OK = grep {
	ref \$Aion::Format::Url::{$_} eq "GLOB"
		&& *{$Aion::Format::Url::{$_}}{CODE} && !/^(_|(NaN|import)\z)/n
} keys %Aion::Format::Url::;


#@category escape url

use constant UNSAFE_RFC3986 => qr/[^A-Za-z0-9\-\._~]/;

# Эскейпит значение
sub to_url_param(;$) {
	my ($param) = @_ == 0? $_: @_;
	use bytes;
	$param =~ s/${\ UNSAFE_RFC3986}/$& eq " "? "+": sprintf "%%%02X", ord $&/ge;
	$param
}

# Преобразует в формат url-параметров
sub to_url_params(;$) {
	my ($param) = @_ == 0? $_: @_;

	my @R;
	my @S = [$param];
	while(@S) {
		my $u = pop @S;
		my ($x, $key) = @$u;
		
		if(ref $x eq "HASH") {
			push @S, defined($key)
				? (map [$x->{$_}, "$key\[${\to_url_param}]"], sort keys %$x)
				: (map [$x->{$_}, to_url_param], sort keys %$x)
			;
		}
		elsif(ref $x eq "ARRAY") {
			my $i = '';
			push @S, map [$_, "$key\[${\($i++)}]"], @$x;
		}
		elsif(!defined $x) {}
		elsif($x eq 1) { unshift @R, $key }
		else {
			unshift @R, join "=", $key, to_url_param $x;
		}
	}
	
	join "&", @R
}

# Определяет кодировку. В koi8-r и в cp1251 большие и малые буквы как бы поменялись местами, поэтому у правильной кодировки вес будет больше
sub _bohemy {
	my ($s) = @_;
	my $c = 0;
	while($s =~ /[а-яё]+/gi) {
		my $x = $&;
		if($x =~ /^[А-ЯЁа-яё][а-яё]*$/) { $c += length $x } else { $c -= length $x }
	}
	$c
}

sub from_url_param(;$) {
	my ($param) = @_ == 0? $_: @_;

	utf8::encode($param) if utf8::is_utf8($param);

	{
		no utf8;
		use bytes;
		$param =~ tr!\+! !;
		$param =~ s!%([\da-f]{2})! chr hex $1 !iage;
	}

	eval { $param = Encode::decode_utf8($param, Encode::FB_CROAK) };

	if($@) { # видимо тут кодировка cp1251 или koi8-r
		my $cp  = Encode::decode('cp1251', $param);
		my $koi = Encode::decode('koi8-r', $param);
		# выбираем перекодировку в которой меньше больших букв внутри слова
		$param = _bohemy($koi) > _bohemy($cp)? $koi: $cp;
	}

	$param
}

sub _set_url_param(@) {
	my ($x, $val) = @_;
	if(ref $$x eq "ARRAY") { push @$$x, $val }
	elsif(ref $$x eq "HASH") { $$x = [$$x, $val] }
	else { $$x = $val }
}

sub from_url_params(;$) {
	my ($params) = @_ == 0? $_: @_;

	my %param;
	my $x;
	my $was_val;

	while($params =~ /\G (?: 
		(?:^|&) (?<key1> [^&=\[\]]* )
		| \[ (?<key> [^\[\]]* ) \]
		| (?: = (?<val> [^&]*) )
		| .
	) /gsx) {

		if(exists $+{key1}) {
			_set_url_param $x, 1 unless $was_val;
			$was_val = 0;
			$x = \$param{from_url_param $+{key1}};
		}
		elsif(exists $+{key}) {
			# Добрасываем в массив
			if($+{key} eq '' || int $+{key} eq $+{key}) {
				$$x = [$$x] if ref $$x ne 'ARRAY' && defined $$x;
				$x = \$$x->[$+{key}];
			}
			else {
				# Добавляем в хеш
				my $key = from_url_param $+{key};
				$$x = {$key => $$x} if ref $$x ne 'HASH' && defined $$x;
				$x = \$$x->{$key};
			}
		}
		elsif(exists $+{val}) {
			_set_url_param $x, from_url_param $+{val};
			$was_val = 1;
		}
		
	}
	
	_set_url_param $x, 1 unless $was_val;

	\%param
}

#@category parse url

sub _parse_url ($) {
	my ($link) = @_;
	$link =~ m!^
		( (?<proto> \w+ ) : )?
		( //
			( (?<user> [^:/?\#\@]* ) :
		  	  (?<pass> [^/?\#\@]*  ) \@  )?
			(?<domain> [^/?\#]* )  )?
		(  / (?<path>  [^?\#]* ) )?
		(?<part> [^?\#]+ )?
		( \? (?<query> [^\#]*  ) )?
		( \# (?<hash>  .*	   ) )?
	\z!xn;
	return %+;
}

# 1 - set / in each page, if it not file (*.*), or 0 - unset
use config DIR => 0;
use config ONPAGE => "off://off";

# Парсит и нормализует url
sub parse_url($;$$) {
	my ($link, $onpage, $dir) = @_;
	$onpage //= ONPAGE;
	$dir //= DIR;
	my $orig = $link;

	my %link = _parse_url $link;
	my %onpage = _parse_url $onpage;

	if(!exists $link{path}) {
		$link{path} = join "", $onpage{path}, $onpage{path} =~ m!/\z!? (): "/", $link{part};
		delete $link{part};
	}

	if(exists $link{proto}) {}
	elsif(exists $link{domain}) {
		$link{proto} = $onpage{proto};
	}
	else {
		$link{proto} = $onpage{proto};
		$link{user} = $onpage{user} if exists $onpage{user};
		$link{pass} = $onpage{pass} if exists $onpage{pass};
		$link{domain} = $onpage{domain};
	}

	# нормализуем
	$link{proto} = lc $link{proto};
	$link{domain} = lc $link{domain};
	$link{dom} = $link{domain} =~ s/^www\.//r;
	$link{path} = lc $link{path};

	my @path = split m!/!, $link{path}; my @p;

	for my $p (@path) {
		if($p eq ".") {}
		elsif($p eq "..") {
			#@p or die "Выход за пределы пути";
			pop @p;
		}
		else { push @p, $p }
	}

	@p = grep { $_ ne "" } @p;

	if(@p) {
		$link{path} = join "/", "", @p;
		if($link{path} =~ m![^/]*\.[^/]*\z!) {
			$link{dir} = $`;
			$link{file} = $&;
		} elsif($dir) {
			$link{path} = $link{dir} = "$link{path}/";
		} else {
			$link{dir} = "$link{path}/";
		}
	} elsif($dir) {
		$link{path} = "/";
	} else { delete $link{path} }

	$link{orig} = $orig;
	$link{onpage} = $onpage;
	$link{link} = join "", $link{proto}, "://",
		exists $link{user} || exists $link{pass}? ($link{user},
			exists $link{pass}? ":$link{pass}": (), '@'): (),
		$link{dom},
		$link{path},
		length($link{query})? ("?", $link{query}): (),
		length($link{hash})? ("#", $link{hash}): (),
	;

	return \%link;
}

# Нормализует url
sub normalize_url($;$$) {
	parse_url($_[0], $_[1], $_[2])->{link}
}

1;

__END__

=encoding utf-8

=head1 NAME

Aion::Format::Url - utilities for encoding and decoding URLs

=head1 SYNOPSIS

	use Aion::Format::Url;
	
	to_url_params {a => 1, b => [[1,2],3,{x=>10}]} # => a&b[][]&b[][1]=2&b[1]=3&b[2][x]=10
	
	normalize_url "?x", "http://load.er/fix/mix?y=6"  # => http://load.er/fix/mix?x

=head1 DESCRIPTION

Utilities for encoding and decoding URLs.

=head1 SUBROUTINES

=head2 to_url_param (;$scalar)

Escapes C<$scalar> for the search part of the URL.

	to_url_param "a b" # => a+b
	
	[map to_url_param, "a b", "🦁"] # --> [qw/a+b %F0%9F%A6%81/]

=head2 to_url_params (;$hash_ref)

Generates the search portion of the URL.

	local $_ = {a => 1, b => [[1,2],3,{x=>10}]};
	to_url_params  # => a&b[][]&b[][1]=2&b[1]=3&b[2][x]=10

=over

=item 1. Keys with C<undef> values are discarded.

=item 2. The value C<1> is used for a key without a value.

=item 3. Keys are converted in alphabetical order.

=back

	to_url_params {k => "", n => undef, f => 1}  # => f&k=

=head2 from_url_params (;$scalar)

Parses the search part of the URL.

	local $_ = 'a&b[][]&b[][1]=2&b[1]=3&b[2][x]=10';
	from_url_params  # --> {a => 1, b => [[1,2],3,{x=>10}]}

=head2 from_url_param (;$scalar)

Used to parse keys and values in a URL parameter.

Reverse to C<to_url_param>.

	local $_ = to_url_param '↬';
	from_url_param  # => ↬

=head2 parse_url ($url, $onpage, $dir)

Parses and normalizes URLs.

=over

=item * C<$url> - URL or part of it to be parsed.

=item * C<$onpage> is the URL of the page with C<$url>. If C<$url> is not complete, then it is completed from here. Optional. By default it uses the C<$onpage = 'off://off'> configuration.

=item * C<$dir> (bool): 1 - normalize the URL path with a "/" at the end if it is a directory. 0 - without "/".

=back

	my $res = {
	    proto  => "off",
	    dom    => "off",
	    domain => "off",
	    link   => "off://off",
	    orig   => "",
	    onpage => "off://off",
	};
	
	parse_url "" # --> $res
	
	$res = {
	    proto  => "https",
	    dom    => "main.com",
	    domain => "www.main.com",
	    path   => "/page",
	    dir    => "/page/",
	    link   => "https://main.com/page",
	    orig   => "/page",
	    onpage => "https://www.main.com/pager/mix",
	};
	
	parse_url "/page", "https://www.main.com/pager/mix"   # --> $res
	
	$res = {
	    proto  => "https",
	    user   => "user",
	    pass   => "pass",
	    dom    => "x.test",
	    domain => "www.x.test",
	    path   => "/path",
	    dir    => "/path/",
	    query  => "x=10&y=20",
	    hash   => "hash",
	    link   => 'https://user:pass@x.test/path?x=10&y=20#hash',
	    orig   => 'https://user:pass@www.x.test/path?x=10&y=20#hash',
	    onpage => "off://off",
	};
	parse_url 'https://user:pass@www.x.test/path?x=10&y=20#hash'  # --> $res

=head2 normalize_url ($url, $onpage, $dir)

Normalizes the URL.

Uses C<parse_url> and returns a link.

	normalize_url ""   # => off://off
	normalize_url "www.fix.com"  # => off://off/www.fix.com
	normalize_url ":"  # => off://off/:
	normalize_url '@'  # => off://off/@
	normalize_url "/"  # => off://off
	normalize_url "//" # => off://
	normalize_url "?"  # => off://off
	normalize_url "#"  # => off://off
	
	normalize_url "/dir/file", "http://www.load.er/fix/mix"  # => http://load.er/dir/file
	normalize_url "dir/file", "http://www.load.er/fix/mix"  # => http://load.er/fix/mix/dir/file
	normalize_url "?x", "http://load.er/fix/mix?y=6"  # => http://load.er/fix/mix?x

=head1 SEE ALSO

=over

=item * L<Badger::URL>.

=item * L<Mojo::URL>.

=item * L<Plack::Request>.

=item * L<URI>.

=item * L<URI::URL>.

=item * L<URL::Encode>.

=item * L<URL::XS>.

=back

=head1 AUTHOR

Yaroslav O. Kosmina L<mailto:darviarush@mail.ru>

=head1 LICENSE

⚖ B<GPLv3>

=head1 COPYRIGHT

The Aion::Format::Url module is copyright © 2023 Yaroslav O. Kosmina. Rusland. All rights reserved.
