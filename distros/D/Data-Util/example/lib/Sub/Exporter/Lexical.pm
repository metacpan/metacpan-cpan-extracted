package # this is an example for install_subroutine()/uninstall_subroutine().
	Sub::Exporter::Lexical;
use 5.008_001;
use strict;
use warnings;

use Data::Util;
use Carp ();

sub import :method{
	my $class    = shift;
	my $exportee = caller;

	$class->setup_installer($exportee, @_);
}

sub setup_installer :method{
	my($exporter, $exportee, %args) = @_;

	my $exportable_ref = Data::Util::mkopt_hash $args{exports}, 'setup', 'CODE';

	while(my($name, $entity) = each %{$exportable_ref}){
		unless($entity){
			$exportable_ref->{$name} = Data::Util::get_code_ref($exportee, $name, -create);
		}
	}

	Data::Util::install_subroutine($exportee, import => sub :method{
		my $class = shift;

		my $export_ref;
		if(@_){
			$export_ref = {};
			for my $name(@_){
				$export_ref->{$name} = $exportable_ref->{$name}
					or Carp::croak "$name is not exportable in $exportee";
			}

		}
		else{
			$export_ref = $exportable_ref;
		}

		my $into = caller;
		Data::Util::install_subroutine($into, %{$export_ref});

		$^H |= 0x020000; # HINT_LOCALIZE_HH
		my $cleaner = $^H{$exporter .'/'. $into} ||= bless [$into], $exporter;

		push @{$cleaner}, %{$export_ref};

		return;
	});
}

sub DESTROY :method{
	my($self) = @_;

	Data::Util::uninstall_subroutine(@{$self});
}
1;

__END__

=head1 NAME

Sub::Exporter::Lexical - Exports subrtouines lexically

=head1 SYNOPSIS

	package Foo;
	use Sub::Exporter::Lexical
		exports => [
			qw(foo bar),
			baz => \&bar, # i.e. the synonym of bar
		],
	;

	# ...

	{
		use Foo;
		foo(...); # Foo::foo(...)
		bar(...); # Foo::bar(...)
		baz(...); # Foo::bar(...), too

	} # foo, bar and baz are uninstalled

	foo(); # fatal!
	bar(); # fatal!
	baz(); # fatal!

=head1 SEE ALSO

L<Data::Util>.

=cut
