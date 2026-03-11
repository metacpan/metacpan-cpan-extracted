package TAP::Parser::Metrics;
use parent qw/TAP::Parser/;

use strict;
use warnings;

our $VERSION='0.0.1';

my $METRICS='__METRICS__'.int(1e6+rand(9e6));

sub configure {
	my ($self,%opt)=@_;
	if($opt{callback}) { $$self{callback}=$opt{callback} }
	return $self;
}

sub new {
	my ($ref,$argref)=@_;
	my $class=ref($ref)||$ref;
	my $self=$class->SUPER::new($argref);
	$$self{$METRICS}={path=>[],log=>[],source=>$$argref{source}};
	return $self;
}

sub next {
	my ($self,@args)=@_;
	my $next=$self->SUPER::next(@args);
	if(!$next) {
		if($$self{callback}) { &{$$self{callback}}(@{$$self{$METRICS}{log}}) }
		return $next;
	}
	my $metrics=$$self{$METRICS};
	if(my $raw=$next->raw()) {
		if($raw=~/^(?<indent>\s*)# Subtest:\s+(?<name>.*)$/) {
			my $indent=length($+{indent})/4;
			if($#{$$metrics{path}}>$indent) { splice(@{$$metrics{path}},$indent) }
			push @{$$metrics{path}},$+{name};
		}
		elsif($raw=~/^(?<indent>\s*)(?<not>not )?ok\s+\d+\s+-\s*(?<label>.*)$/) {
			my $indent=length($+{indent})/4;
			if($#{$$metrics{path}}>=$indent) { splice(@{$$metrics{path}},$indent) }
			push @{$$metrics{log}},{
				file=>$$metrics{source},
				pass=>($+{not}?0:1),
				path=>[@{$$metrics{path}//[]}],
				label=>$+{label},
			};
		}
	}
	return $next;
}

1;

__END__
