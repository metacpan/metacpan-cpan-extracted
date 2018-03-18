package Dwarf::DSL;
use Dwarf::Pragma;
use Dwarf::Module::DSL;

sub import {
	my $self = shift;
	my $caller = caller;

	no strict 'refs';

	# コンパイラをだますために use したクラスに DSL 用の空の関数をエクスポートする
	for my $f (@Dwarf::Module::DSL::FUNC) {
		my $existing = *{"${caller}::${f}"}{CODE};
		next if defined $existing;
		*{"${caller}::${f}"} = sub {};
	}
}

1;
