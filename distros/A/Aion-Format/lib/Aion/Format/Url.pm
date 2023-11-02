package Aion::Format::Url;

use common::sense;

use List::Util qw//;

use Exporter qw/import/;
our @EXPORT = our @EXPORT_OK = grep {
    ref \$Aion::Format::Url::{$_} eq "GLOB"
        && *{$Aion::Format::Url::{$_}}{CODE} && !/^(_|(NaN|import)\z)/n
} keys %Aion::Format::Url::;


#@category escape url

use constant UNSAFE_RFC3986 => qr/[^A-Za-z0-9\-\._~]/;

sub to_url_param(;$) {
	my ($param) = @_ == 0? $_: @_;
	$param =~ s/${\ UNSAFE_RFC3986}/$& eq " "? "+": sprintf "%%%02X", ord $&/age;
	$param
}

sub _escape_url_params {
	my ($key, $param) = @_;

	!defined($param)? ():
	$param eq 1? $key:
	ref $param eq "HASH"? do {
		join "&", map _escape_url_params("${key}[$_]", $param->{$_}), sort keys %$param
	}:
	ref $param eq "ARRAY"? do {
		join "&", map _escape_url_params("${key}[]", $_), @$param
	}:
	join "", $key, "=", to_url_param $param
}

sub to_url_params(;$) {
	my ($param) = @_ == 0? $_: @_;

	if(ref $param eq "HASH") {
		join "&", map _escape_url_params($_, $param->{$_}), sort keys %$param
	}
	else {
		join "&", List::Util::pairmap { _escape_url_params($a, $b) } @$param
	}
}

# #@see https://habr.com/ru/articles/63432/
# # В multipart/form-data
# sub to_multipart(;$) {
# 	my ($param) = @_ == 0? $_: @_;
# 	$param =~ s/[&=?#+\s]/$& eq " "? "+": sprintf "%%%02X", ord $&/ge;
# 	$param
# }

#@category parse url

sub _parse_url ($) {
	my ($link) = @_;
	$link =~ m!^
		( (?<proto> \w+ ) : )?
		( //
			( (?<user> [^:/?\#\@]* ) :
		  	  (?<pass> [^/?\#\@]*  ) \@  )?
			(?<domain> [^/?\#]* )             )?
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

Aion::Format::Url - the utitlities for encode and decode the urls

=head1 SYNOPSIS

	use Aion::Format::Url;
	
	to_url_params {a => 1, b => [[1,2],3,{x=>10}]} # => a&b[][]&b[][]=2&b[]=3&b[][x]=10
	
	normalize_url "?x", "http://load.er/fix/mix?y=6"  # => http://load.er/fix/mix?x

=head1 DESCRIPTION

The utitlities for encode and decode the urls.

=head1 SUBROUTINES

=head2 to_url_param (;$scalar)

Escape scalar to part of url search.

	to_url_param "a b" # => a+b
	
	[map to_url_param, "a b", "🦁"] # --> [qw/a+b %1F981/]

=head2 to_url_params (;$hash_ref)

Generates the search part of the url.

	local $_ = {a => 1, b => [[1,2],3,{x=>10}]};
	to_url_params  # => a&b[][]&b[][]=2&b[]=3&b[][x]=10

=over

=item 1. Keys with undef values not stringify.

=item 2. Empty value is empty.

=item 3. C<1> value stringify key only.

=item 4. Keys stringify in alfabet order.

=back

	to_url_params {k => "", n => undef, f => 1}  # => f&k=

=head2 parse_url ($url, $onpage, $dir)

Parses and normalizes url.

=over

=item * C<$url> — url, or it part for parsing.

=item * C<$onpage> — url page with C<$url>. If C<$url> not complete, then extended it. Optional. By default use config ONPAGE = "off://off".

=item * C<$dir> (bool): 1 — normalize url path with "/" on end, if it is catalog. 0 — without "/".

=back

	my $res = {
	    proto  => "off",
	    dom    => "off",
	    domain => "off",
	    link   => "off://off",
	    orig   => "",
	    onpage => "off://off",
	};
	
	parse_url ""    # --> $res
	
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

See also C<URL::XS>.

=head2 normalize_url ($url, $onpage, $dir)

Normalizes url.

It use C<parse_url>, and it returns link.

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

=item * C<URI::URL>.

=back

=head1 AUTHOR

Yaroslav O. Kosmina LL<mailto:darviarush@mail.ru>

=head1 LICENSE

⚖ B<GPLv3>

=head1 COPYRIGHT

The Aion::Format::Url module is copyright © 2023 Yaroslav O. Kosmina. Rusland. All rights reserved.
