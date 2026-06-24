package Aion::Env::Etc;

use common::sense;

use YAML::Syck qw//;

use Aion::Env AION_ENV_ETC_PATH => (default => 'etc/include.yml');
use Aion::Env APP_ENV => (default => 'prod');

our %etc = %{ -e AION_ENV_ETC_PATH? parse(AION_ENV_ETC_PATH): () };

sub import {
	my ($cls, $name, %kw) = @_;
	my $isa = delete $kw{isa};
	my $is_default = exists $kw{default};
	my $default = delete $kw{default};
	my $key = delete $kw{key} // lc($name) =~ y/_/./r;
	die sprintf "Unknown keyword%s: %s",
		scalar keys %kw == 1? '': 's',
	 	join ", ", sort keys %kw if keys %kw;

	my ($val, $key_exists) = by_key(\%etc, $key);
	die "$name is'nt defined!" if !$key_exists and !$is_default;

	my $pkg = caller;
	my $val = $key_exists? $val: $default;

	if($isa) {
	   	if(UNIVERSAL::isa($isa, "Aion::Type")) { $isa->validate($val, $name) }
	   	else {
			local $_ = $val;
			die UNIVERSAL::can($isa, "get_message")? $isa->get_message($val): "$name type is'nt isa!" unless $isa->();
		}
	}
	
	constant->import("$pkg\::$name", $val);
}

# Считывает и парсит конфигурационный файл с включениями
sub parse {
	my ($path) = @_;

	my $etc;
	my @S = $path;
	while(@S) {
		my $path = shift @S;
		open my $f, '<:utf8', $path or die "$path :$!";
		read $f, my $buf, -s $f;
		close $f;
		$buf =~ s!\$\{([a-z_]\w*)\}! val($ENV{$1} // $Aion::Env::env{$1}) !gie;
		my $include = YAML::Syck::Load($buf); undef $buf;
		push @S, @{$include->{includes}};
		%$include = (%$include, %{$include->{'when@' . APP_ENV}});
		$etc = merge_hashes($path, undef, $etc, $include);
	}

	$etc
}

# Рекурсивное объединение двух хешей
sub merge_hashes {
	my ($file, $path, $x, $y) = @_;

	my %val = %$x;
	for my $k (keys %$y) {
		if(exists $val{$k}) {
			my $a_path = $path? "$path.$k": $k;
			die "$file > $a_path: x is'nt hash" if ref $val{$k} ne 'HASH';
			die "$file > $a_path: y is'nt hash" if ref $y->{$k} ne 'HASH';
			$val{$k} = merge_hashes($file, $a_path, $val{$k}, $y->{$k});
		}
		else { $val{$k} = $y->{$k} }
	}

	\%val
}

# Добавляет бэкслеши
sub val {
	my ($s) = @_;
	$s =~ s/[\\"']/\\$&/g;
	$s =~ s/\n/\\n/g;
	$s =~ s/\r/\\r/g;
	$s =~ s/\t/\\t/g;
	$s
}

# Получить значение по ключу
sub by_key($$) {
	my ($hash, $path) = @_;
	exists $hash->{$_}? $hash = $hash->{$_}: return undef, 0 for split /\./, $path;
	return $hash, 1;
}

1;

__END__

=encoding utf-8

=head1 NAME

Aion::Env::Etc - creates a constant associated with a key from configuration files

=head1 SYNOPSIS

etc/include.yml file:

	includes:
	  - etc/test.yml
	
	test:
	  abc: -12

File etc/test.yml:

	test:
	  abc: 100
	
	when@dev:
	  test:
	    val: 10



	BEGIN { $ENV{APP_ENV} = 'dev' }
	
	sub Int { sub { /^-?\d+$/ } }
	
	use Aion::Env::Etc TEST_ABC => (isa => Int);
	use Aion::Env::Etc VAL => (isa => Int, key => 'test.val');
	
	TEST_ABC # -> -12
	VAL # -> 10

=head1 DESCRIPTION

Parses the configuration file. The path to it is specified by the environment variable C<AION_ENV_ETC_PATH>.

It may contain the C<includes> key with the inclusion of other configuration files, and those with other ones.
For simplicity, C<includes> are triggered from the current directory, which should correspond to the project root (this is the convention).

Keys of the form C<when@ID> will overlap with their keys the keys of the configuration file if the C<ID> of them matches C<APP_ENV>.

Hashes in keys, if the keys match in different files, are combined recursively. However, if one of the keys does not have a hash, an exception will be thrown.

=head1 SUBROUTINES

=head2 import ($name, %kw)

Creates a constant in the package from which it was called.

Valid options:

=over

=item * C<isa> – tester routine or C<Aion::Type> object for type checking.

=item * C<default> – default value.

=item * C<key> – key from configuration files. By default, the name of the constant is converted to it (translated to lower case and underscores are replaced with dots).

=back

=head2 parse ($path)

Reads and parses a configuration file in C<yaml> format. C<${ID}> are replaced with values from C<%ENV>, and if not there, then from the C<.env> file. Parses files in C<include> recursively.

=head2 merge_hashes ($file, $path, $x, $y)

Concatenates two hashes recursively. If the matching keys do not have hashes, then it throws an error with C<$file> and C<$path>, where C<$file> is the connecting file, and C<$path> is the path from the keys through the dot.

=head2 val ($s)

Adds backslashes. Used for escaping environments.

	my $escape_string = "\\\"\\'\\\\\\t\\r\\n";
	Aion::Env::Etc::val("\"'\\\t\r\n") # -> $escape_string

=head2 by_key ($hash, $path)

Get the value by key from the hash.

	my ($val, $key_exists) = Aion::Env::Etc::by_key({x => {y => {z => 3}}}, "x.y.z");
	
	$val # -> 3
	$key_exists # -> 1
	
	($val, $key_exists) = Aion::Env::Etc::by_key({x => {y => {t => 10}}}, "x.y.z");
	
	$val # -> undef
	$key_exists # -> 0

=head1 AUTHOR

Yaroslav O. Kosmina L<mailto:dart@cpan.org>

=head1 LICENSE

⚖ B<Perl5>

=head1 COPYRIGHT

The Aion::Env::Etc module is copyright © 2026 Yaroslav O. Kosmina. Rusland. All rights reserved.
