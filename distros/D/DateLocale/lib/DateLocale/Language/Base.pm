package DateLocale::Language::Base;

use Mouse;
use utf8;

has language => (is => 'ro', isa => 'Str', default => sub {$_[0]->redef_child_class('language')});
has locale   => (is => 'ro', isa => 'Str', default => sub {$_[0]->redef_child_class('locale')});


sub redef_child_class {
	my ($self, $param) = @_;
	die "Language class ".ref($self)." is bad. Attribute $param must be redefined";
}

sub _fmt_redef {
	my ($self,$fmt) = @_;
	my $fn;
	$fmt =~ s/%(O?[%a-zA-Z])/($_[0]->can("format_$1") || sub { $1 })->($_[0]);/sgeox;
	$fmt;
}

1;

