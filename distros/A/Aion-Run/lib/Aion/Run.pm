package Aion::Run;
use common::sense;

our $VERSION = "0.0.1-prealpha";

use Aion -role;

# Позволяет проставлять однобуквенные ключи (-x) в соответствие фичам
aspect arg => sub {
	my ($arg, $feature) = @_;
	die "has $feature->{name} => (arg => '$arg'), where only `-A` parameters are allowed!" unless $arg =~ /^(?:-\w|\d+)\z/a;
	$feature->{arg} = $arg;
};

# Создаёт объект с параметрами запроса
sub new_from_args {
	my ($pkg, $args) = @_;

	my $get_key = sub { my ($feature) = @_; $feature->{opt}{init_arg} // $feature->{name} };
	my $FEATURE = $Aion::META{$pkg}{feature};
	my $ARG = {};
	my $ARGUMENT = {};
	exists $_->{arg} and do { $ARG->{$_->{arg}} = $_; $ARGUMENT->{$get_key->($_)} = $_ } for values %$FEATURE;

	my %param;

	my $set_feature = sub {
		my ($key, $val) = @_;
		my $feature = $ARGUMENT->{$key} // die "Unknown option --$key";
		if($feature->{isa}{name} eq "ArrayRef") {
			push @{$param{$key}}, $val;
		} else {
			die "--$key / $feature->{arg} repeats" if exists $param{$key};
			$param{$key} = $val;
		}
	};

	my @args;

	for(my $i=0; $i < @$args; $i++) {
		local $_ = $args->[$i];
		if(/^--([\w-]+)(?:=(.*))?\z/a) {
			$set_feature->($1, $2);
		}
		elsif(/^-(\w+)\z/ai) {
			for(split //, $1) {
				my $feature = $ARG->{"-$_"} or die "Unknown option -$_";
				my $key = $get_key->($feature);
				if($feature->{isa}{name} eq "Bool") {
					$set_feature->($key, !$feature->{default});
				} else {
					$set_feature->($key, $args->[++$i]);
				}
			}
		}
		else {
			push @args, $_;
			my $feature;
			$set_feature->($get_key->($feature), $_) if $feature = $ARG->{@args};
		}
	}
	
	if(exists $ARG->{0}) {
		my $key = $ARG->{0}{opt}{init_arg} // $ARG->{0}{name};
		$param{$key} = \@args;
	}

	$pkg->new(%param)
}

1;

__END__

=encoding utf-8

=head1 NAME

Aion::Run - role for console commands

=head1 VERSION

0.0.1-prealpha

=head1 SYNOPSIS

File lib/Scripts/MyScript.pm:

	package Scripts::MyScript;
	
	use common::sense;
	
	use List::Util qw/reduce/;
	use Aion::Format qw/trappout/;
	
	use Aion;
	
	with qw/Aion::Run/;
	
	# Operands for calculations
	has operands => (is => "ro+", isa => ArrayRef[Int], arg => "-a", init_arg => "operand");
	
	# Operator for calculations
	has operator => (is => "ro+", isa => Enum[qw!+ - * /!], arg => 1);
	
	#@run math/calc „Calculate”
	sub calculate_sum {
	    my ($self) = @_;
	    printf "Result: %g\n", reduce {
	        given($self->operator) {
	            $a+$b when /\+/;
	            $a-$b when /\-/;
	            $a*$b when /\*/;
	            $a/$b when /\//;
	        }
	    } @{$self->operands};
	}
	
	1;



	use Aion::Format qw/trappout/;
	
	use lib "lib";
	use Scripts::MyScript;
	
	trappout { Scripts::MyScript->new_from_args([qw/-a 1 -a 2 -a 3 +/])->calculate_sum } # => Result: 6\n
	trappout { Scripts::MyScript->new_from_args([qw/--operand=4 * --operand=2/])->calculate_sum } # => Result: 8\n

=head1 DESCRIPTION

The C<Aion::Run> role implements the C<arg> aspect for installing features from command line parameters.

=over

=item * C<< arg =E<gt> "-X" >> is a named parameter. You can use either the shortcut B<-X> or the feature name with B<-->.

=item * C<< arg =E<gt> natural >> is an ordinal parameter. C<1+>.

=item * C<< arg =E<gt> 0 >> - all unnamed parameters. Used with C<< isa =E<gt> ArrayRef >>.

=back

=head1 METHODS

=head2 new_from_args ($pkg, $args)

Constructor. It creates a script object with command line options.

	package ArgExample {
		use Aion;
		
		with qw/Aion::Run/;
		
		has args => (is => "ro+", isa => ArrayRef[Str], arg => 0);
		has arg => (is => "ro+", isa => ArrayRef[Str], arg => '-a');
		has arg1 => (is => "ro+", isa => Str, arg => 1);
		has arg2 => (is => "ro+", isa => Str, init_arg => '_arg2', arg => 2);
		has arg_1 => (is => "ro+", isa => Str, init_arg => '_arg_1', arg => -1);
		has arg_2 => (is => "ro+", isa => Str, arg => -2);
	}
	
	my $ex = ArgExample->new_from_args([qw/1  -a 5  2  --arg=6 -2 5 --_arg_1=4/]);
	
	$ex->arg1 # => 1
	$ex->arg2 # => 2
	$ex->arg_1 # => 4
	$ex->arg_2 # => 5
	$ex->args # --> [1, 2]
	$ex->arg # --> [5, 6]

=head1 SEE ALSO

=over

=item * L<Aion>

=back

=head1 AUTHOR

Yaroslav O. Kosmina L<mailto:dart@cpan.org>

=head1 LICENSE

⚖ B<GPLv3>

=head1 COPYRIGHT

The Aion::Run module is copyright (c) 2023 Yaroslav O. Kosmina. Rusland. All rights reserved.
