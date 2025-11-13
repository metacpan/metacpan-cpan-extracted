use common::sense; use open qw/:std :utf8/;  use Carp qw//; use File::Basename qw//; use File::Find qw//; use File::Slurper qw//; use File::Spec qw//; use File::Path qw//; use Scalar::Util qw//;  use Test::More 0.98;  BEGIN {     $SIG{__DIE__} = sub {         my ($s) = @_;         if(ref $s) {             $s->{STACKTRACE} = Carp::longmess "?" if "HASH" eq Scalar::Util::reftype $s;             die $s;         } else {             die Carp::longmess defined($s)? $s: "undef"         }     };      my $t = File::Slurper::read_text(__FILE__);     my $s = '/tmp/.liveman/perl-aion/aion!meta!requires-feature.pm';      File::Find::find(sub { chmod 0700, $_ if !/^\.{1,2}\z/ }, $s), File::Path::rmtree($s) if -e $s;  	File::Path::mkpath($s);  	chdir $s or die "chdir $s: $!";  	push @INC, '/ext/__/@lib/perl-aion/lib', 'lib'; 	 	$ENV{PROJECT_DIR} = '/ext/__/@lib/perl-aion'; 	$ENV{TEST_DIR} = $s;      while($t =~ /^#\@> (.*)\n((#>> .*\n)*)#\@< EOF\n/gm) {         my ($file, $code) = ($1, $2);         $code =~ s/^#>> //mg;         File::Path::mkpath(File::Basename::dirname($file));         File::Slurper::write_text($file, $code);     } } # package Aion::Meta::RequiresFeature;
# 
# use common::sense;
# 
# use Aion::Meta::Util qw//;
# use List::Util qw/pairmap/;
# use Scalar::Util qw/looks_like_number reftype blessed refaddr/;
# 
# Aion::Meta::Util::create_getters(qw/pkg name opt has/);
# 
# #  Конструктор
# sub new {
# 	my ($cls, $pkg, $name, @has) = @_;
# 	bless {pkg => $pkg, name => $name, opt => {@has}, has => \@has}, ref $cls || $cls;
# }
# 
# # Строковое представление фичи
# sub stringify {
# 	my ($self) = @_;
# 	my $has = join ', ', pairmap { "$a => ${\
# 		Aion::Meta::Util::val_to_str($b)
# 	}" } @{$self->{has}};
# 	return "req $self->{name} => ($has) of $self->{pkg}";
# }
# 
# # Сравнивает с фичей, но только значения которые есть в этой
# sub compare {
# 	my ($self, $feature) = @_;
# 
# 	die "Requires $self" unless UNIVERSAL::isa($feature, 'Aion::Meta::Feature');
# 
# 	my $fail = 0;
# 	for my $key (keys %{$self->{opt}}) {
# 		$fail = 1, last unless exists $feature->{opt}{$key};
# 
# 		my $value = $self->{opt}{$key};
# 		my $other_value = $feature->{opt}{$key};
# 		$fail = 1, last unless _deep_equal($value, $other_value);
# 	}
# 
# 	die "Feature mismatch with ${\$self->stringify}" if $fail;
# }
# 
# # Сравнивает два значения
# sub _deep_equal {
# 	my ($value, $other_value) = @_;
# 
# 	if (blessed $value) {
# 		return "" unless blessed $other_value;
# 
# 		if (overload::Method($value, '==')) {
# 			return "" unless $value == $other_value;
# 		}
# 		elsif (overload::Method($value, 'eq')) {
# 			return "" unless $value eq $other_value;
# 		}
# 		else {
# 			return "" if refaddr $value != refaddr $other_value;
# 		}
# 	}
# 	elsif (looks_like_number($value)) {
# 		return "" unless looks_like_number($other_value) && $value == $other_value;
# 	}
# 	elsif (reftype $value eq 'ARRAY') {
# 		for(my $i = 0; $i <= $#$value; $i++) {
# 			return "" unless _deep_equal($value->[$i], $other_value->[$i]);
# 		}
# 	}
# 	elsif (reftype $value eq 'HASH') {
# 		for my $k (keys %$value) {
# 			return "" unless exists $other_value->{$k} && _deep_equal($value->{$k}, $other_value->{$k});
# 		}
# 	}
# 	elsif (reftype $value eq 'SCALAR') {
# 		return "" unless reftype $other_value eq 'SCALAR' && _deep_equal($$value, $$other_value);
# 	}
# 	elsif (reftype $value eq 'CODE') {
# 		return "" unless reftype $other_value eq 'CODE' && refaddr $value == refaddr $other_value;
# 	}
# 	else {
# 		return "" if $value ne $other_value;
# 	}
# 
# 	return 1;
# }
# 
# 1;
# 
# __END__
# 
# =encoding utf-8
# 
# =head1 NAME
# 
# Aion::Meta::RequiresFeature - требование фичи для интерфейсов
# 
# =head1 SYNOPSIS
# 
# 	use Aion::Types qw(Str);
# 	use Aion::Meta::RequiresFeature;
# 	use Aion::Meta::Feature;
# 	
# 	my $req = Aion::Meta::RequiresFeature->new(
# 		'My::Package', 'name', is => 'rw', isa => Str);
# 	
# 	my $feature = Aion::Meta::Feature->new(
# 		'Other::Package',
# 		'name', is => 'rw', isa => Str,
# 		default => 'default_value');
# 	
# 	$req->compare($feature);
# 	
# 	$req->stringify  # => req name => (is => 'rw', isa => Str) of My::Package
# 
# =head1 DESCRIPTION
# 
# С помощью C<req> создаёт требование к фиче которая будет описана в модуле к которому будет подключена роль или который унаследует абстрактный класс.
# 
# Проверяться будут только указанные аспекты в фиче.
# 
# =head1 SUBROUTINES
# 
# =head2 new ($cls, $pkg, $name, @has)
# 
# Конструктор.
# 
# =head2 pkg ()
# 
# Возвращает имя пакета в котором описано требование к фиче.
# 
# =head2 name ()
# 
# Возвращает имя фичи.
# 
# =head2 has ()
# 
# Возвращает массив с аспектами фичи.
# 
# =head2 opt ()
# 
# Возвращает хеш аспектов фичи.
# 
# =head2 stringify ()
# 
# Строковое представление фичи.
# 
# =head2 compare ($feature)
# 
# Сравнивает с фичей, но только указанные аспекты.
# 
# =head1 AUTHOR
# 
# Yaroslav O. Kosmina L<mailto:dart@cpan.org>
# 
# =head1 LICENSE
# 
# ⚖ B<GPLv3>
# 
# =head1 COPYRIGHT
# 
# The Aion::Meta::RequiresFeature module is copyright © 2025 Yaroslav O. Kosmina. Rusland. All rights reserved.

::done_testing;
